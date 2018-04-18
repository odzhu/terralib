variable "environment" {
  description = "Environment tag, e.g prod"
  default     = "default"
}

variable "vpc_id" {
  description = "VPC id which will host openshift"
}

variable "public_subnet_ids" {
  description = "List of Subnets"
  type        = "list"
}

variable "private_subnet_ids" {
  description = "List of Subnets"
  type        = "list"
}

variable "admin_ssh_key" {
  description = "Instance key name"
  default     = ""
}

variable "management_net" {}

variable "public_domain" {
  description = "Public domain name used as parent for all environments"
}

variable "provisioner_ami" {
  default = "ami-0d063c6b"
}

variable "provisioner_instance_type" {
  default = "m3.large"
}

variable "provisioner_user_data" {
  default = "provisioner_user_data.tpl"
}

variable "provisioner_name" {
  default = "provisioner"
}

variable "provisioner_spot_price" {
  default = "0.10"
}

//<Master nodes variables
variable "master_node_count" {
  default = "1"
}

variable "master_ami" {
  default = "ami-0d063c6b"
}

variable "master_instance_type" {
  default = "m3.large"
}

variable "master_user_data" {
  default = "node_user_data.tpl"
}

variable "master_name" {
  default = "master"
}

variable "master_spot_price" {
  default = "0.10"
}

//>Master nodes variables

//<Infra nodes variables

variable "infra_node_count" {
  default = "1"
}

variable "infra_ami" {
  default = "ami-0d063c6b"
}

variable "infra_instance_type" {
  default = "m3.large"
}

variable "infra_user_data" {
  default = "node_user_data.tpl"
}

variable "infra_name" {
  default = "infra"
}

variable "infra_spot_price" {
  default = "0.10"
}

//>Infra nodes variables

//<app nodes variables

variable "app_node_count" {
  default = "1"
}

variable "app_ami" {
  default = "ami-0d063c6b"
}

variable "app_instance_type" {
  default = "m3.large"
}

variable "app_user_data" {
  default = "node_user_data.tpl"
}

variable "app_name" {
  default = "app"
}

variable "app_spot_price" {
  default = "0.10"
}

//>app nodes variables

//<Ports definitions for masters

variable "allowed_ports_tcp_from_master_to_master" {
  default = ["53", "8053", "2049", "2379", "2380", "4001", "8443"]
}

variable "allowed_ports_udp_from_master_to_master" {
  default = ["53", "8053", "2049"]
}

variable "allowed_ports_tcp_from_node_to_master" {
  default = ["53", "8053", "443", "8443"]
}

variable "allowed_ports_udp_from_node_to_master" {
  default = ["53", "8053"]
}

//>

variable "allowed_ovs_port_inside_cluster" {
  default = "4789"
}

//<Ports definitions for app nodes

variable "allowed_ports_tcp_from_master_inside_cluster" {
  default = ["10250"]
}

//>

//<Ports definitions for infra nodes

variable "allowed_ports_tcp_from_public_to_infra" {
  default = ["80", "443"]

  //default = []
}

//>

