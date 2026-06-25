#!/usr/bin/env bash
#
# Cake Agents installer entrypoint.
#
# This is a STUB that wires up the real install flow: it runs Terraform against
# the cake-oss/terraform-cake-agents module (the examples/basic configuration)
# to provision a VPC, EKS cluster, and the cake-agents Helm release. Terraform
# state is stored in S3.
#
# Inputs are passed as environment variables:
#
#   CAKE_STATE_BUCKET   (required) S3 bucket for Terraform remote state.
#   CAKE_STATE_PREFIX   (optional) Key prefix in the bucket. Default: cake-agents
#   CAKE_STATE_REGION   (optional) Region of the state bucket.
#                                  Defaults to AWS_REGION, then TF_VAR_region.
#   CAKE_ACTION         (optional) plan | apply | destroy. Default: apply
#   CAKE_AGENTS_REF     (optional) git ref of terraform-cake-agents. Default: main
#
# Terraform module inputs are passed via TF_VAR_* variables, e.g.:
#
#   TF_VAR_name                       (required) Cluster name, e.g. "prod"
#   TF_VAR_region                     (required) AWS region to deploy into
#   TF_VAR_install_key                (required) Install key for Cake-hosted DNS automation
#   TF_VAR_cake_agents_chart_version  (optional) cake-agents Helm chart version. Default: 0.11.2
#   TF_VAR_vpc_cidr                   (optional) Default: 10.0.0.0/16
#
set -euo pipefail

log() { printf '%s [cake-agents-install] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

# --- Resolve configuration ---------------------------------------------------
CAKE_STATE_PREFIX="${CAKE_STATE_PREFIX:-cake-agents}"
CAKE_ACTION="${CAKE_ACTION:-apply}"
CAKE_AGENTS_REF="${CAKE_AGENTS_REF:-main}"

[ -n "${CAKE_STATE_BUCKET:-}" ]  || die "CAKE_STATE_BUCKET is required (S3 bucket for Terraform state)."
[ -n "${TF_VAR_name:-}" ]        || die "TF_VAR_name is required (cluster name)."
[ -n "${TF_VAR_region:-}" ]      || die "TF_VAR_region is required (AWS region)."
[ -n "${TF_VAR_install_key:-}" ] || die "TF_VAR_install_key is required (Cake install key)."

CAKE_STATE_REGION="${CAKE_STATE_REGION:-${AWS_REGION:-${TF_VAR_region}}}"
STATE_KEY="${CAKE_STATE_PREFIX%/}/${TF_VAR_name}/terraform.tfstate"

case "${CAKE_ACTION}" in
  plan|apply|destroy) ;;
  *) die "CAKE_ACTION must be one of: plan, apply, destroy (got '${CAKE_ACTION}')." ;;
esac

WORKDIR="${CAKE_TERRAFORM_DIR:-/opt/cake-agents/terraform}"
cd "${WORKDIR}"

# Pin the terraform-cake-agents module to the requested ref. Terraform does not
# allow variable interpolation in a module source, so we rewrite it in place.
if [ "${CAKE_AGENTS_REF}" != "main" ]; then
  log "Pinning terraform-cake-agents module to ref '${CAKE_AGENTS_REF}'."
  sed -i "s|terraform-cake-agents.git?ref=main|terraform-cake-agents.git?ref=${CAKE_AGENTS_REF}|g" main.tf
fi

# --- Run Terraform -----------------------------------------------------------
log "State backend: s3://${CAKE_STATE_BUCKET}/${STATE_KEY} (region ${CAKE_STATE_REGION})"
log "Action: ${CAKE_ACTION}"

terraform init -input=false \
  -backend-config="bucket=${CAKE_STATE_BUCKET}" \
  -backend-config="key=${STATE_KEY}" \
  -backend-config="region=${CAKE_STATE_REGION}"

case "${CAKE_ACTION}" in
  plan)
    terraform plan -input=false
    ;;
  apply)
    terraform apply -input=false -auto-approve
    log "Install complete."
    terraform output
    ;;
  destroy)
    terraform destroy -input=false -auto-approve
    log "Destroy complete."
    ;;
esac
