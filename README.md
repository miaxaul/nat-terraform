# NAT Instance  + Private Web Server + Load Balancer with Terraform

> Infrastructure as Code (IaC) deployment using **Terraform** on AWS  
> **Written by:** [Brielliana](https://github.com/miaxaul)

---

## Project Overview

This Terraform project creates:
- 1 **NAT Instance** inside a public subnet
- 2 **EC2 Instances (Private Subnet)** running basic HTML web servers
- 1 **Application Load Balancer (ALB)** to serve private instances via DNS
- Variables : save region, ami id, key pair
- Outputs: NAT Instance **public IP** and ALB **DNS name**

---

## AWS Resources Used

- `VPC`, `Subnets` (public & private), `Route Tables`
- `Security Groups`
- `EC2 Instances` (Amazon Linux)
- `Elastic IP`
- `Application Load Balancer (ALB)`
- `Launch Template`
- `User Data` to deploy HTML
- `NAT Instance`

---

## How to Use

```terraform init  # Download providers & initialize the working directory```
```terraform plan  # Preview the changes Terraform will make```
```terraform apply # Apply and provision the infrastructure```



