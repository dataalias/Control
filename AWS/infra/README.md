# Terraform

A cheat sheet for terraform commands.

## Determine Version
`terraform --version`

## Initialize
`terraform init -backend-config='accounts/$MyEnv/backend.conf' -reconfigure -upgrade`

## Plan
`terraform plan -var-file='accounts/$MyEnv/terraform.tfvars'`

## Apply
` terraform apply -var-file='accounts/$MyEnv/terraform.tfvars'`

## Upgrade 
Install a chocolatey nuget. You will need powershell administator privilages.
`choco upgrade terraform`

# AWS CLI
Initiate a command prompt and run the following commands to configure the AWS CLI.
`run cmd`

To swtich envrionments
`aws configure`

enter: Key, secret, us-east-1, JSON

### Change Log:
| User       | Date       | Comment                                                                     |
|------------|------------|-----------------------------------------------------------------------------|
| ffortunato | 09/07/2023 | Initial Iteration. |


[Github-flavored Markdown](https://guides.github.com/features/mastering-markdown/)
