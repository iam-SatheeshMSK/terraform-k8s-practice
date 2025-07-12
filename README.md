# Terraform K8s Practice

This repository contains a Terraform configuration that:

- Builds a VPC with a public subnet
- Spins up N identical EC2 instances (control-plane or “all-in-one” K8s nodes)  
- Installs Docker & Kubernetes (kubeadm, kubelet, kubectl) via a user-data script  
- Opens all of the necessary ports for a single-node Kubernetes cluster

> **Module structure**  
> - `modules/vpc`  
>   - Creates a VPC, Internet Gateway, public subnet, route table  
> - `modules/ec2`  
>   - Imports an SSH keypair  
>   - Creates a security group (SSH, API server, NodePort, etc.)  
>   - Launches N EC2 instances with a user-data script  

---

## 🚀 Prerequisites

1. **Terraform v1.4+**  
2. **AWS CLI** (configured with credentials & default region)  
3. **Your SSH public key** (to import into AWS as a Key Pair)  
4. **IAM permission** to create EC2, VPC, IAM resources  

---

## 📁 Repo Layout

```text
.
├── modules
│   ├── vpc
│   │   ├── main.tf        ← VPC, subnet, IGW, route table
│   │   └── variables.tf
│   └── ec2
│       ├── main.tf        ← Keypair, SG, EC2 with count
│       ├── variables.tf
│       └── outputs.tf     ← Exposes instance IDs & public IPs
├── script
│   └── k8s-setup-final.sh ← User-data: disables swap, installs containerd + kube*
├── main.tf                ← Root module, calls `vpc` + `ec2` modules
├── variables.tf           ← Global variables: region, key_pair_name, instance_count
├── terraform.tfvars       ← Your overrides (region, key, count…)
└── versions.tf            ← Specifies provider versions
⚙️ Configuration
Edit terraform.tfvars (create it if missing) with your values:

hcl
Copy
Edit
aws_region     = "us-east-1"           # e.g. us-east-1
key_pair_name  = "your-existing-key"   # must already exist in AWS
instance_count = 2                     # number of EC2 nodes
(Optional) Change the EC2 instance type, volume size, etc. in the modules/ec2/variables.tf.

🛠 Commands
Run these from the repo root:

bash
Copy
Edit
# 1. Initialize Terraform (downloads providers, sets up backend):
terraform init

# 2. See what will be created:
terraform plan -out=tfplan

# 3. Create everything:
terraform apply tfplan

# …wait for “Apply complete”…
You should now see:

A new VPC, subnet, IGW

A security group opening TCP/22, 6443, NodePort range, etc.

N EC2 instances running your user-data script

🔍 Verifying
SSH into one of the instances:

bash
Copy
Edit
ssh -i ~/.ssh/your-key.pem ubuntu@$(terraform output -raw ec2_public_ips | cut -d',' -f1)
Check Docker & kubelet are installed:

bash
Copy
Edit
docker --version
kubelet --version
Initialize your single-node cluster on one instance (as root):

bash
Copy
Edit
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
Install a CNI plugin (Flannel):

bash
Copy
Edit
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
Verify pods in kube-system become Running:

bash
Copy
Edit
kubectl get pods -n kube-system
🧹 Tear Down
When you’re done:

bash
Copy
Edit
terraform destroy
📖 Further Reading
Terraform Modules

kubeadm docs

Flannel CNI
