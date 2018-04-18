#cloud-config
mounts:
    - [ /dev/xvdc, /var/lib/docker, auto, "defaults,noexec", "0", "0" ]
yum_repos:
    epel:
        baseurl: http://download.fedoraproject.org/pub/epel/testing/7/$basearch
        enabled: false
        gpgcheck: false
        name: Extra Packages for Enterprise Linux 7
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
  - NetworkManager
write_files:
  - path: /tmp/user-data-shell
    content: |
      #!/bin/bash
      yum -y --enablerepo=epel install docker-1.12.6
      sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16"' /etc/sysconfig/docker
      systemctl start docker
      systemctl enable docker
      systemctl start NetworkManager && systemctl enable NetworkManager
runcmd:
  - curl -O https://bootstrap.pypa.io/get-pip.py && python get-pip.py && pip install awscli && pip2 install boto
  - aws ssm get-parameters --names "${environment}.provisioner_id_rsa_pub" --region ${region} --output text|awk '{print $4" "$5" "$6}' >> /home/centos/.ssh/authorized_keys
  - bash -li /tmp/user-data-shell
