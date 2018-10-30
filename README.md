# Sensu HA Workshop

## Requirements

* [Terraform] with configured AWS provider
    * See [installation instructions here][tf-install].
* AWS Account
    * To configure the Terraform AWS provider with your credentials, see
      [instructions here][aws-creds].
* Acccess to CentOS 7 AMI
    * Subscribe to this AMI [via the AWS Marketplace][centos-ami].
* SSH key provisioned in AWS Account
    * See [AWS documentation on EC2 Key Pairs][ec2-keys] for more information.
    * Name of your SSH key should be provided as value of Terraform `key_name` variable.
    * Private key should be stored at a known path on your system. Path should be provided as value of Terraform `key_path` variable.

## Usage

_NOTE:_ Using the code in this project to provision resources will incur charges against the configured
AWS account. In using this project you accept responsibility for any costs incurred.

First, set environment variables as expected by AWS provider:

```
$ export AWS_ACCESS_KEY_ID="anaccesskey"
$ export AWS_SECRET_ACCESS_KEY="asecretkey"
```

_NOTE:_ The terraform plan uses us-west-2 region by default. If you wish to use
a different region you will need to specify it as an argument to terraform
apply, e.g.: `terraform apply -var region=us-west-1`

Now you're ready to provision infrastructure:

* `terraform init` - installs required Terraform modules
* `terraform apply` - provisions AWS resources described in plan.tf

You may also provide values for variables via command-line flags:

```
$ terraform apply -var key_name=my_user -var key_path=~/.ssh/my_user-us-west-2.pem
```

After a successful `terraform apply` you should see output providing IP
addresses for your EC2 instances:

```
Outputs:

rabbitmq_ips = [
    35.166.147.53,
    34.211.69.229,
    54.214.141.139
]
redis_ips = [
    54.201.125.218,
    54.245.153.124
]
```

You can print these again as needed by running `terraform output`.

Accessing each of these systems is accomplished using ssh with the private key file and the username `centos`:

```
ssh -i ~/.ssh/my_user-us-west-2.pem centos@35.166.147.53
```

Finally, when you're done with the workshop run `terraform destroy` to tear down the infrastructure
you've built to avoid any excess spending.

[terraform]: https://www.terraform.io
[tf-install]: https://www.terraform.io/intro/getting-started/install.html
[aws-creds]: https://www.terraform.io/docs/providers/aws/
[ec2-keys]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html
[centos-ami]: https://aws.amazon.com/marketplace/pp/B00O7WM7QW