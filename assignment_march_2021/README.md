# Project Overview

In order to setup the entire environment with IaaC tools, I've chose to work with Terragrunt: <https://terragrunt.gruntwork.io>
The reason was to have the opportunity of working with a new tool (although it is based on Terraform), so not everything is written and done automatically, yet...

## Terragrunt creation

In order to run the entire IaaC, you need to be in the path of `demo/eu-west-1` and perform the following commands:

```bash
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply -auto-approve
```

## Infrastructure deletion

Run the following in the same path as above:

```bash
terragrunt run-all destroy
```

## Project Layout

You can find here the following directories that I've added to the project:

* _demo_ : The root folder which contains the entire IaaC (Terragrunt)
* _charts_ : The helm chart for the component

## Dockerfiles

In each component directory, you can find the relevant Dockerfile that I've wrote.

## Additional components

The following components were installed:

* _nginx-ingress_
* _Loki-stack_
* _kube-prometheus-stack_
