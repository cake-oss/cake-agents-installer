# Cake Agents installer image.
#
# Runs Terraform against the cake-oss/terraform-cake-agents module to provision
# Cake Agents on AWS. Run it directly:
#
#   docker run --rm \
#     -e CAKE_STATE_BUCKET=my-tf-state-bucket \
#     -e TF_VAR_name=prod \
#     -e TF_VAR_region=us-east-2 \
#     -e TF_VAR_cake_agents_chart_version=0.11.2 \
#     -e TF_VAR_install_key=... \
#     -e TF_VAR_cake_console_url=https://console.cake.ai \
#     -v $HOME/.aws:/root/.aws:ro \
#     ghcr.io/cake-oss/cake-agents-installer:latest
#
FROM debian:bookworm-slim

ARG TERRAFORM_VERSION=1.15.6
# Automatically populated by BuildKit with the target arch (amd64 / arm64).
# Do not give this a default — a default overrides the value BuildKit injects,
# which would fetch the wrong-arch Terraform/AWS CLI binaries.
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl unzip git; \
    rm -rf /var/lib/apt/lists/*; \
    \
    # Terraform \
    curl -fsSL -o /tmp/terraform.zip \
        "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip"; \
    unzip /tmp/terraform.zip -d /usr/local/bin; \
    rm /tmp/terraform.zip; \
    terraform version; \
    \
    # AWS CLI v2 \
    case "${TARGETARCH}" in \
        amd64) awscli_arch=x86_64 ;; \
        arm64) awscli_arch=aarch64 ;; \
        *) echo "unsupported arch: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/awscliv2.zip \
        "https://awscli.amazonaws.com/awscli-exe-linux-${awscli_arch}.zip"; \
    unzip -q /tmp/awscliv2.zip -d /tmp; \
    /tmp/aws/install; \
    rm -rf /tmp/awscliv2.zip /tmp/aws; \
    aws --version

WORKDIR /opt/cake-agents

COPY terraform/ ./terraform/
COPY install.sh /usr/local/bin/cake-agents-install
RUN chmod +x /usr/local/bin/cake-agents-install

ENTRYPOINT ["cake-agents-install"]
