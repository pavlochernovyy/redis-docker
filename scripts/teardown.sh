#!/usr/bin/env bash
# Destroys the Terraform-managed Redis + RedisInsight resources, and their
# docker images (any locally tagged redis / redis/redisinsight image, not
# just the exact tag currently configured in variables.tf).
# Also stops the pub/sub publisher background loop, if running.
# Pass --volumes to also delete the persisted data volumes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform"

echo "Stopping pub/sub publisher (if running)..."
"$SCRIPT_DIR/pubsub.sh" stop

if [[ "${CI:-}" == "true" ]]; then
  echo "Running in CI — keeping .pubsub.log for the workflow to upload as an artifact."
else
  echo "Removing pub/sub logs..."
  rm -f "$SCRIPT_DIR/../.pubsub.log"
fi

cd "$TF_DIR"
terraform destroy -auto-approve

if [[ "${1:-}" == "--volumes" ]]; then
  echo "Removing data volumes..."
  docker volume rm -f redis-local-data redisinsight-local-data 2>/dev/null || true
fi

echo "Removing docker images..."
docker images --filter "reference=redis" --filter "reference=redis/redisinsight" --format "{{.Repository}}:{{.Tag}}" \
  | xargs -r docker rmi -f

echo "Teardown complete."
