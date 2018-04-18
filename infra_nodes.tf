module "infra" {
  source                      = "odzhu/asg/aws"
  version                     = "1.0.4"
  subnet_ids                  = "${var.private_subnet_ids}"
  environment                 = "${var.environment}"
  name                        = "${var.infra_name}"
  vpc_id                      = "${var.vpc_id}"
  instance_type               = "${var.infra_instance_type}"
  instance_profile            = "${aws_iam_instance_profile.infra.name}"
  ami                         = "${var.infra_ami}"
  admin_ssh_key               = "${aws_key_pair.admin_key.key_name}"
  user_data                   = "${data.template_file.infra.rendered}"
  load_balancers              = ["${aws_elb.infra.name}"]
  management_net              = "${var.management_net}"
  associate_public_ip_address = "false"
  min_size                    = "${var.infra_node_count}"
  max_size                    = "${var.infra_node_count + 2}"
  spot_price                  = "${var.infra_spot_price}"
}

data "template_file" "infra" {
  template = "${file("${path.module}/${var.infra_user_data}")}"

  vars {
    environment = "${var.environment}"
    region      = "${data.aws_region.current.name}"
  }
}
