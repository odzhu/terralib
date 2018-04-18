#cloud-config
mounts:
    - [ /dev/xvdc, /var/lib/docker, auto, "defaults,noexec", "0", "0" ]
package_update: true
package_reboot_if_required: false
packages:
  - wget
  - net-tools 
  - bind-utils 
  - iptables-services 
  - bridge-utils 
  - bash-completion 
  - kexec-tools 
  - sos 
  - psacct 
  - git
  - pyOpenSSL
  - ansible

write_files:
  - path: /var/provisioner/ec2.ini
    content: |
      [ec2]

      regions = all
      regions_exclude = us-gov-west-1, cn-north-1

      destination_variable = private_dns_name
      vpc_destination_variable = private_ip_address
      hostname_variable = private_dns_name

      route53 = False
      all_instances = False
      all_rds_instances = False

      # Include RDS cluster information (Aurora etc.)
      include_rds_clusters = False

      all_elasticache_replication_groups = False
      all_elasticache_clusters = False
      all_elasticache_nodes = False

      cache_path = ~/.ansible/tmp

      cache_max_age = 300

      # Organize groups into a nested/hierarchy instead of a flat namespace.
      nested_groups = False

      # Replace - tags when creating groups to avoid issues with ansible
      replace_dash_in_groups = True

      # If set to true, any tag of the form "a,b,c" is expanded into a list
      # and the results are used to create additional tag_* inventory groups.
      expand_csv_tags = False

      # The EC2 inventory output can become very large. To manage its size,
      # configure which groups should be created.
      group_by_instance_id = True
      group_by_region = True
      group_by_availability_zone = True
      group_by_aws_account = False
      group_by_ami_id = True
      group_by_instance_type = True
      group_by_instance_state = False
      group_by_platform = True
      group_by_key_pair = True
      group_by_vpc_id = True
      group_by_security_group = True
      group_by_tag_keys = True
      group_by_tag_none = True
      group_by_route53_names = True
      group_by_rds_engine = True
      group_by_rds_parameter_group = True
      group_by_elasticache_engine = True
      group_by_elasticache_cluster = True
      group_by_elasticache_parameter_group = True
      group_by_elasticache_replication_group = True

      stack_filters = False
      [credentials]
  - path: /root/.ssh/config
    content: |
      Host *
        user                       centos
        StrictHostKeyChecking      no
        ProxyCommand               none
        CheckHostIP                no
        ForwardAgent               yes
        IdentityFile               /root/.ssh/id_rsa
  - path: /etc/amazon/ssm/seelog.xml
    content: |
      <seelog type="adaptive" mininterval="2000000" maxinterval="100000000" critmsgcount="500" minlevel="info">
          <exceptions>
              <exception filepattern="test*" minlevel="error"/>
          </exceptions>
          <outputs formatid="fmtinfo">
              <console formatid="fmtinfo"/>
              <rollingfile type="size" filename="/var/log/amazon/ssm/amazon-ssm-agent.log" maxsize="30000000" maxrolls="5"/>
              <filter levels="error,critical" formatid="fmterror">
                  <rollingfile type="size" filename="/var/log/amazon/ssm/errors.log" maxsize="10000000" maxrolls="5"/>
              </filter>
              <custom name="cloudwatch_receiver" formatid="fmtdebug" data-log-group="${log_group}"/>
          </outputs>
          <formats>
              <format id="fmterror" format="%Date %Time %LEVEL [%FuncShort @ %File.%Line] %Msg%n"/>
              <format id="fmtdebug" format="%Date %Time %LEVEL [%FuncShort @ %File.%Line] %Msg%n"/>
              <format id="fmtinfo" format="%Date %Time %LEVEL %Msg%n"/>
          </formats>
      </seelog>
  - path: /bin/provisioner.sh
    content: |
      #!/bin/bash

      EC2_INI_PATH=/var/provisioner/ec2.ini

      if aws sqs receive-message --queue-url ${sqs} --visibility-timeout 0 --region ${region} |grep -i body

      then
        echo New provision required
        aws sqs purge-queue --queue-url ${sqs} --region ${region}
        sleep 140
        while pgrep ansible-playbook > /dev/null
        do
              sleep 2
              echo waiting process finish
        done

        while ansible-playbook -i /var/provisioner /openshift-ansible/playbooks/byo/config.yml|tee -a /var/provisioner/provisioner.log|grep -i "Failure summary"
        do
         echo Provison attempt
        done
      fi
  - path: /var/provisioner/ansiblehosts
    content: |
      # Create an OSEv3 group that contains the masters and nodes groups
      [OSEv3:children]
      masters
      nodes
      etcd
      new_nodes

      # Set variables common for all OSEv3 hosts
      [OSEv3:vars]
      openshift_disable_check=memory_availability, disk_availability, docker_storage
      # SSH user, this user should allow ssh based auth without requiring a password
      ansible_user=centos
      openshift_clock_enabled=true
      openshift_docker_insecure_registries=['172.30.0.0/16']
      openshift_master_default_subdomain=public.${master_public_fqdn}
      openshift_public_hostname=${master_public_fqdn}
      openshift_master_cluster_method=native
      openshift_master_cluster_hostname=${master_private_fqdn}
      openshift_master_cluster_public_hostname=${master_public_fqdn}
      
      #Schedule only on nodes with below label
      osm_default_node_selector='app=true'

      # If ansible_ssh_user is not root, ansible_become must be set to true
      ansible_become=true

      openshift_deployment_type=origin

      [tag_aws_autoscaling_groupName_${master_asg_name}]

      [tag_aws_autoscaling_groupName_${infra_asg_name}]

      [tag_aws_autoscaling_groupName_${app_asg_name}]

      # host group for masters
      [masters:children]
      tag_aws_autoscaling_groupName_${master_asg_name}

      [masters:vars]
      #openshift_schedulable=true

      # host group for etcd
      [etcd:children]
      tag_aws_autoscaling_groupName_${master_asg_name}

      # host group for nodes, includes region info
      [nodes:children]
      tag_aws_autoscaling_groupName_${master_asg_name}
      infra
      app

      [infra:children]
      tag_aws_autoscaling_groupName_${infra_asg_name}

      [infra:vars]
      openshift_node_labels="{'region': 'infra'}"

      [app:children]
      tag_aws_autoscaling_groupName_${app_asg_name}

      [app:vars]
      openshift_node_labels="{'app': 'true'}"
bootcmd:
  - mkdir /var/provisioner
runcmd:
  - git clone -b release-3.6 https://github.com/openshift/openshift-ansible
  - wget -O /var/provisioner/ec2.py https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/ec2.py 
  - wget -O /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && chmod +x /bin/jq
  - yum install -y https://s3-${region}.amazonaws.com/amazon-ssm-${region}/latest/linux_amd64/amazon-ssm-agent.rpm && systemctl start amazon-ssm-agent && systemctl enable amazon-ssm-agent
  - chmod +x /var/provisioner/ec2.py /bin/provisioner.sh
  - curl -O https://bootstrap.pypa.io/get-pip.py && python get-pip.py && pip install awscli && pip2 install boto
  - ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa && rm -f /root/.ssh/id_rsa.pub
  - aws ssm get-parameters --names "${environment}.provisioner_id_rsa" --with-decryption --region ${region} --output json|jq -r '.|{Parameters}[][]|.Value'>/root/.ssh/id_rsa
  - aws ssm send-command --document-name ${ssm} --targets Key=tag:Name,Values=provisioner --region ${region}
  - /bin/provisioner.sh
