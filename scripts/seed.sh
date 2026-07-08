#!/usr/bin/env bash
# Seeds the local Redis container with data from seed/seed-data.redis
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED_FILE="$SCRIPT_DIR/../seed/seed-data.redis"
CONTAINER_NAME="${REDIS_CONTAINER_NAME:-redis-local}"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Container '${CONTAINER_NAME}' is not running. Run 'terraform apply' first." >&2
  exit 1
fi

echo "Seeding ${CONTAINER_NAME} from $(basename "$SEED_FILE")..."

grep -v '^--' "$SEED_FILE" | grep -v '^\s*$' | docker exec -i "$CONTAINER_NAME" redis-cli --no-raw

echo "Done. Verify with: docker exec -it ${CONTAINER_NAME} redis-cli KEYS '*'"
