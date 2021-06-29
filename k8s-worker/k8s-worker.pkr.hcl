locals {
  build_stamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

source "amazon-ebs" "k8s-worker-arm" {
  ami_name = "k8s-worker-arm-${local.build_stamp}"

  # Select most recent version of ubuntu-20-04 from canonical
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      root-device-type = "ebs"
      architecture = "arm64"
      ena-support = true
      name = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-*"
    }
  owners = ["099720109477"]
  most_recent = true
  }
  
  # Define build instance parameters
  region = "us-west-2"
  vpc_id = "vpc-08fbaa27c3eb37ee9"
  subnet_filter {
    filters = {
      "tag:Name" = "us-west-2-dmz"
    }
    most_free = true
  }
  shutdown_behavior = "terminate"
  ssh_username = "ubuntu"
  ssh_interface = "public_ip"
  associate_public_ip_address = true
  spot_price = "auto"
  spot_instance_types = [
    "t4g.small",
    "t4g.medium",
  ]
}

build {
  sources = [
    "source.amazon-ebs.k8s-worker-arm",
  ]
  
  # Install Docker
  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo 'deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu focal stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null]",
      "apt-get update",
      "apt-get install -y docker-ce docker-ce-cli containerd.io"
    ]
  }

  # Install Kubernetes
  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add",
      "apt-add-repository 'deb http://apt.kubernetes.io/ kubernetes-xenial main'",
      "apt-get install -y kubeadm=1.21.2-00 kubelet=1.21.2-00 kubectl=1.21.2-00",
      "apt-mark hold kubeadm kubelet kubectl",
    ]
  }
  

  # Install AWS CLI
  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "apt-get update",
      "apt-get install -y awscli",
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
