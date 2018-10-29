# Sensu HA Workshop

## Requirements

* [Terraform] with configured AWS provider
    * See [installation instructions here][tf-install].
* AWS Account
    * To configure the Terraform AWS provider with your credentials, see [instructions here][aws-creds].
* SSH key provisioned in AWS Account
    * See [AWS documentation on EC2 Key Pairs][ec2-keys] for more information.
    * Name of your SSH key should be provided as value of Terraform `key_name` variable.
    * Private key should be stored at a known path on your system. Path should be provided as value of Terraform `key_path` variable.

## Usage

_NOTE:_ Using the code in this project to provision resources will incur charges against the configured
AWS account. In using this project you accept responsibility for any costs incurred.

* `terraform init` - installs required Terraform modules
* `terraform apply` - provisions AWS resources described in plan.tf
* `terraform output` - prints IP addresses of provisioned AWS EC2 instances
* `terraform destroy` - destroys the provisioned AWS resources

[terraform]: https://www.terraform.io
[tf-install]: https://www.terraform.io/intro/getting-started/install.html
[aws-creds]: https://www.terraform.io/docs/providers/aws/
[ec2-keys]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html