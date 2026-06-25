# cake-agents-installer

Installs [Cake Agents](https://github.com/cake-oss/terraform-cake-agents) on AWS.

The installer is a container image that runs Terraform against the
[`terraform-cake-agents`](https://github.com/cake-oss/terraform-cake-agents)
module (the `examples/basic` configuration). It provisions a VPC, an EKS
cluster, and the cake-agents Helm release. DNS is handled by Cake-hosted
automation using your install key. Terraform state is stored in S3.

> **Note:** `install.sh` is currently a stub that wires up the Terraform flow.
> Provisioning logic lives in the upstream `terraform-cake-agents` module.

There are two ways to run it:

1. **Container directly** — bring your own AWS credentials and an S3 bucket.
2. **CloudFormation** — bootstraps the S3 state bucket and a CodeBuild project
   that runs the image for you.

## Prerequisites

- An AWS account and credentials with permission to create a VPC, EKS, ACM,
  IAM, and load balancers.
- An install key from Cake (used for Cake-hosted DNS automation).

## Configuration

Terraform inputs are passed as `TF_VAR_*` environment variables.

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `CAKE_STATE_BUCKET` | yes | — | S3 bucket for Terraform remote state |
| `CAKE_STATE_PREFIX` | no | `cake-agents` | State key prefix within the bucket |
| `CAKE_STATE_REGION` | no | `AWS_REGION`/`TF_VAR_region` | Region of the state bucket |
| `CAKE_ACTION` | no | `apply` | `plan`, `apply`, or `destroy` |
| `CAKE_AGENTS_REF` | no | `main` | git ref of `terraform-cake-agents` |
| `TF_VAR_name` | yes | — | Cluster name (e.g. `prod`) |
| `TF_VAR_region` | yes | — | AWS region to deploy into |
| `TF_VAR_install_key` | yes | — | Install key for Cake-hosted DNS automation |
| `TF_VAR_cake_agents_chart_version` | no | `0.11.2` | cake-agents Helm chart version |
| `TF_VAR_cake_console_url` | no | `https://console.cake.ai` | URL of the Cake console to report to |
| `TF_VAR_vpc_cidr` | no | `10.0.0.0/16` | CIDR for the new VPC |

## Option 1: Run the container directly

```sh
docker run --rm \
  -e CAKE_STATE_BUCKET=my-tf-state-bucket \
  -e TF_VAR_name=prod \
  -e TF_VAR_region=us-east-2 \
  -e TF_VAR_install_key=... \
  -v "$HOME/.aws:/root/.aws:ro" \
  ghcr.io/cake-oss/cake-agents-installer:latest
```

Use `-e CAKE_ACTION=plan` for a dry run, or `destroy` to tear everything down.
The S3 bucket must already exist; create one with versioning enabled, e.g.
`aws s3 mb s3://my-tf-state-bucket`.

### Build it yourself

```sh
docker build -t cake-agents-installer .
```

## Option 2: CloudFormation

This creates the S3 state bucket and a CodeBuild project that runs the image.

```sh
aws cloudformation deploy \
  --template-file cloudformation/cake-agents-installer.yaml \
  --stack-name cake-agents \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    ClusterName=prod \
    Region=us-east-2 \
    InstallKey=...
```

Then start the install (the exact command is in the stack Outputs):

```sh
aws codebuild start-build --project-name cake-agents-cake-agents-install
```

To plan or destroy instead, override `CAKE_ACTION` for a single run:

```sh
aws codebuild start-build --project-name cake-agents-cake-agents-install \
  --environment-variables-override name=CAKE_ACTION,value=destroy
```

> The CodeBuild role is granted `AdministratorAccess` because Terraform
> provisions a wide range of resources. Scope it down for production by editing
> the `CodeBuildRole` policy in the template.

## After installing

Terraform prints a `cluster_name` output for the new EKS cluster. DNS and
certificate validation are handled automatically by Cake using your install
key — no manual nameserver delegation is required.

## License

[Apache License 2.0](LICENSE). Copyright Cake AI Technologies, Inc.
