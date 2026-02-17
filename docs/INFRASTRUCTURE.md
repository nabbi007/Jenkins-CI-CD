# Infrastructure Documentation

## AWS Infrastructure Overview

**Region:** eu-west-1 (Ireland)  
**Account ID:** 049618907165  

### Services Used

1. **EC2**
   - Instance Type: t3.micro
   - AMI: Amazon Linux 2
   - Public IP: 54.74.21.91
   - DNS: ec2-54-74-21-91.eu-west-1.compute.amazonaws.com
   - Port: 80 (host) → 3000 (container)

2. **ECR (Elastic Container Registry)**
   - Repository: jenkins-ci-cd-demo
   - URI: 049618907165.dkr.ecr.eu-west-1.amazonaws.com/jenkins-ci-cd-demo
   - Image Storage for pipeline

3. **IAM**
   - Role: jenkins-cicd-t3micro-ecr-role
   - Policy: AmazonEC2ContainerRegistryReadOnly
   - Instance Profile: jenkins-cicd-t3micro-instance-profile

### Network Configuration

- **VPC:** Default VPC (vpc-09e5505c13f07c56d)
- **Subnet:** Default subnet
- **Security Group:** Allows port 80 (HTTP)
- **Internet Gateway:** Enabled for public access

---

## Terraform Infrastructure Code

**Location:** `infra/terraform/`

### Files

| File | Purpose |
|------|---------|
| `main.tf` | EC2, ECR, IAM resources |
| `variables.tf` | Input parameters |
| `outputs.tf` | Output values |
| `versions.tf` | Provider versions |

### Resources Created

✅ EC2 instance (t3.micro)  
✅ ECR repository  
✅ Security group  
✅ IAM role and policy  
✅ Instance profile  

### Deployment

```bash
cd infra/terraform
terraform init
terraform plan
terraform apply -auto-approve
```

---

## Container Architecture

```
[Jenkins Build]
        ↓
[Docker Build] → node:18-alpine
        ↓
[Docker Image]  
    - npm dependencies
    - app.js
    - public/ assets
    - Port 3000
        ↓
[ECR Registry] → 049618907165.dkr.ecr.eu-west-1.amazonaws.com
        ↓
[Docker Run] on EC2
    - Port 80:3000
    - Restart: unless-stopped
    - Health Check: /health
```

---

## Deployment Flow

```
Git Push
   ↓
Jenkins Webhook
   ↓
Pipeline Start
   ├─ Checkout
   ├─ Test
   ├─ Docker Build
   ├─ ECR Push
   └─ EC2 Deploy
```

