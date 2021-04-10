locals {
  build_stamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

source "amazon-ebs" "ubuntu-20-04" {

  ami_name = "ubuntu-20-04-${local.build_stamp}"

  # Select most recent version of ubuntu-18-04 from canonical
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      root-device-type = "ebs"
      architecture = "x86_64"
      ena-support = true
      name = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
    }
  owners = ["099720109477"]
  most_recent = true
  }
  
  # Define build instance parameters
  vpc_id = "vpc-08fbaa27c3eb37ee9"
  subnet_filter {
    filters = {
      "tag:Name" = "us-west-2*"
    }
    most_free = true
  }
  shutdown_behavior = "terminate"
  ssh_username = "ubuntu"
  ssh_interface = "public_ip"
  associate_public_ip_address = true
  spot_price = "auto"
  spot_instance_types = [
    "t3.small",
    "t3.medium",
    "t3a.small",
    "t3a.medium",
  ]
}

build {
  sources = [
    "source.amazon-ebs.ubuntu-20-04"
  ]
  
  # Install common packages
  provisioner "shell" {
    pause_before = "10s"
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "apt update",
      "apt install -y git tree vim sl nmap make tmux htop curl wget unzip traceroute rsync python3-venv",
    ]
  }

  # Update system packages
  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "apt update -y",
      "apt upgrade -y",
      "apt autoremove -y"
    ]
  }
}
