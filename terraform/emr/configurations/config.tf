terraform {
  backend "s3" {
    bucket = "my-tf-files"
    key    = "tf-state"
    region = "eu-west-1"
  }
}
