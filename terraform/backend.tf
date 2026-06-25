# Partial S3 backend configuration. The bucket, key, and region are supplied at
# init time by install.sh via -backend-config flags (sourced from the
# CAKE_STATE_* environment variables).
terraform {
  backend "s3" {
    encrypt = true
  }
}
