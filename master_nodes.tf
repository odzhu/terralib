module "master" {
  source                      = "odzhu/asg/aws"
  version                     = "1.0.4"
  subnet_ids                  = "${var.private_subnet_ids}"
  environment                 = "${var.environment}"
  name                        = "${var.master_name}"
  vpc_id                      = "${var.vpc_id}"
  instance_type               = "${var.master_instance_type}"
  instance_profile            = "${aws_iam_instance_profile.master.name}"
  ami                         = "${var.master_ami}"
  admin_ssh_key               = "${aws_key_pair.admin_key.key_name}"
  user_data                   = "${data.template_file.master.rendered}"
  load_balancers              = ["${aws_elb.master.name}", "${aws_elb.internal_master.name}"]
  management_net              = "${var.management_net}"
  associate_public_ip_address = "false"
  min_size                    = "${var.master_node_count}"
  max_size                    = "${var.master_node_count + 2}"
  spot_price                  = "${var.master_spot_price}"
}

data "template_file" "master" {
  template = "${file("${path.module}/${var.master_user_data}")}"

  vars {
    environment = "${var.environment}"
    region      = "${data.aws_region.current.name}"
  }
}
