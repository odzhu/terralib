module "provisioner" {
  source           = "odzhu/asg/aws"
  version          = "1.0.4"
  subnet_ids       = "${var.public_subnet_ids}"
  environment      = "${var.environment}"
  name             = "${var.provisioner_name}"
  vpc_id           = "${var.vpc_id}"
  instance_type    = "${var.provisioner_instance_type}"
  instance_profile = "${aws_iam_instance_profile.provisioner.name}"
  ami              = "${var.provisioner_ami}"
  admin_ssh_key    = "${aws_key_pair.admin_key.key_name}"
  load_balancers   = ["${aws_elb.master.name}"]
  user_data        = "${data.template_file.provisioner.rendered}"
  management_net   = "${var.management_net}"
  spot_price       = "${var.provisioner_spot_price}"
}

data "template_file" "provisioner" {
  template = "${file("${path.module}/${var.provisioner_user_data}")}"

  vars {
    master_asg_name     = "${replace("${module.master.name}", "-", "_")}"
    infra_asg_name      = "${replace("${module.infra.name}", "-", "_")}"
    app_asg_name        = "${replace("${module.app.name}", "-", "_")}"
    environment         = "${var.environment}"
    public_domain       = "${var.public_domain}"
    master_public_fqdn  = "${aws_route53_record.master.fqdn}"
    master_private_fqdn = "${aws_route53_record.internal_master.fqdn}"
    region              = "${data.aws_region.current.name}"
    log_group           = "${var.environment}"
    sqs                 = "${aws_sqs_queue.scaling.id}"
    ssm                 = "${aws_ssm_document.openshift.name}"
  }
}

data "aws_region" "current" {
  current = true
}

resource "aws_ssm_document" "openshift" {
  name          = "${var.environment}_openshift"
  document_type = "Command"

  content = <<DOC
  {
              "schemaVersion":"2.2",
              "description":"cross-platform sample",
              "mainSteps":[
                  {
                    "action":"aws:runShellScript",
                    "name":"Ansible",
                    "inputs":{
                        "runCommand":[
                          "provisioner.sh"
                        ]
                    }
                  }
              ]
}
DOC
}
