# My Second Project walkthrough

Hi! Thanks for looking into this project. This is but a mere simple TF based project which intend to do the following:
1. Create new bucket
2. Create index.html in this bucket
3. Create SG
4. Launch new instance with this SG and provide user-data which will install nginx with the index.html from above.

## Terraform installation

* Download the binary from https://www.terraform.io/downloads.html (Optional, place it in your $PATH)
* Download\copy the tf files to your workspace.
* Run `terraform init` to initialize and download all needed providers plugins

## Make it personal!
* Edit `var.tf` with the values that suits your environment
* Validate that everything is configured correctly (I know that I did :smile: ) using `terraform validate`.
* Now, create the actual plan. Since this is a one time project, you can simply use `terraform plan`.
* At last, run it with `terraform apply -auto-approve` (You can also ignore this flag if you wish to approve it yourself)

The public ip is listed in the command output. 

## Good luck!
