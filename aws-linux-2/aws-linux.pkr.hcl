locals {
  build_stamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

source "amazon-ebs" "aws-linux-2" {

  ami_name = "aws-linux-2-${local.build_stamp}"

  # Select most recent version of aws-linux-2
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      root-device-type = "ebs"
      architecture = "x86_64"
      ena-support = true
      name = "amzn2-ami-hvm-2.0.*"
    }
  owners = ["amazon"]
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
  ssh_username = "ec2-user"
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
    "source.amazon-ebs.aws-linux-2"
  ]
  
  # Install common packages
  provisioner "shell" {
    pause_before = "5s"
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "yum install -y git tree vim sl nmap tmux htop curl wget unzip traceroute rsync python3-venv",
    ]
  }

  # Copy Gitlab deploy key
  # Will be used to clone ansible repo to auto-apply config
  #provisioner "file" {
  #  source = "secrets/gitlab-deploy"
  #  destination = "/root/.ssh/id_rsa"
  #}
  
  # Install Gitlab deploy key and use it in ssh config
  #provisioner "shell" {
  #  execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
  #  inline = [
  #    "chown root:root /root/.ssh/id_rsa",
  #    "chmod 600 /root/.ssh/id_rsa",
  #    "echo Host git.dorwinia.com >> /root/.ssh/config",
  #    "echo StrictHostKeyChecking no >> /root/.ssh/config"
  #  ]
  #}

  #TODO: open up SECURE access to Gitlab
  # Install AWS credentials needed for ansible runs
  #provisioner "shell" {
  #  inline = [
  #    "mkdir /root/.aws",
  #    "echo '[default]' >> /root/.aws/credentials",
  #    "echo 'aws_access_key_id=replaceme' >> /root/.aws/credentials",
  #    "echo 'aws_secret_access_key=replaceme' >> /root/.aws/credentials",
  #  ]
  #}
  
  # Update system packages
  provisioner "shell" {
    pause_before = "5s"
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "yum update -y"
    ]
  }
}
