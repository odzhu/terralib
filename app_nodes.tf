module "app" {
  source                      = "odzhu/asg/aws"
  version                     = "1.0.4"
  subnet_ids                  = "${var.private_subnet_ids}"
  environment                 = "${var.environment}"
  name                        = "${var.app_name}"
  vpc_id                      = "${var.vpc_id}"
  instance_type               = "${var.app_instance_type}"
  instance_profile            = "${aws_iam_instance_profile.app.name}"
  ami                         = "${var.app_ami}"
  admin_ssh_key               = "${aws_key_pair.admin_key.key_name}"
  user_data                   = "${data.template_file.app.rendered}"
  load_balancers              = ["${aws_elb.infra.name}"]
  management_net              = "${var.management_net}"
  associate_public_ip_address = "false"
  min_size                    = "${var.app_node_count}"
  max_size                    = "${var.app_node_count + 2}"
  spot_price                  = "${var.app_spot_price}"
}

data "template_file" "app" {
  template = "${file("${path.module}/${var.app_user_data}")}"

  vars {
    environment = "${var.environment}"
    region      = "${data.aws_region.current.name}"
  }
}
