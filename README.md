# Sensu HA Workshop

## Requirements

* Terraform
* AWS Account
* SSH key provisioned in AWS Account
  * Key name should be provided as value of Terraform `key_name` variable.
  * Private key should be stored at a known path on your system. Path should be provided as value of Terraform `key_path` variable.

## Usage

* `terraform init` - installs required Terraform modules
* `terraform apply` - provisions AWS resources described in plan.tf
* `terraform output` - prints IP addresses of provisioned AWS EC2 instances
