#!/usr/bin/env bash
# Provisions the Redis + RedisInsight stack via Terraform, seeds sample data,
# and starts the pub/sub publisher background loop.
# Pass --no-pubsub to skip starting the publisher (e.g. CI runs that don't need it).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform"

cd "$TF_DIR"
terraform init -input=false
terraform apply -auto-approve

cd "$SCRIPT_DIR/.."
./scripts/seed.sh

if [[ "${1:-}" != "--no-pubsub" ]]; then
  ./scripts/pubsub.sh start
fi

echo "Bootstrap complete."
