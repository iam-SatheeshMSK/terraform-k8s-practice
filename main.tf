module "vpc" {
  source     = "./modules/vpc"
  vpc_name   = "satheesh-vpc"
  cidr_block = "10.0.0.0/16"
}

module "ec2" {
  source        = "./modules/ec2"
  instance_count         = var.instance_count
  instance_name = "satheesh-k8s-server"
  subnet_id     = module.vpc.public_subnet_id
  key_name      = var.key_pair_name
  instance_type = "t2.medium"
  volume_size   = 30
  vpc_id        = module.vpc.vpc_id
  public_key_path = "C:/Users/sathe/Downloads/satheesh.pub"
  user_data = file("${path.module}/script/k8s-setup-final.sh")
}


