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

echo
echo "Seeded data:"
docker exec "$CONTAINER_NAME" redis-cli KEYS '*' | sort | while read -r key; do
  [[ -z "$key" ]] && continue
  type="$(docker exec "$CONTAINER_NAME" redis-cli TYPE "$key")"
  case "$type" in
    string) value="$(docker exec "$CONTAINER_NAME" redis-cli GET "$key")" ;;
    list)   value="$(docker exec "$CONTAINER_NAME" redis-cli LRANGE "$key" 0 -1)" ;;
    set)    value="$(docker exec "$CONTAINER_NAME" redis-cli SMEMBERS "$key")" ;;
    hash)   value="$(docker exec "$CONTAINER_NAME" redis-cli HGETALL "$key")" ;;
    zset)   value="$(docker exec "$CONTAINER_NAME" redis-cli ZRANGE "$key" 0 -1 WITHSCORES)" ;;
    *)      value="<$type>" ;;
  esac
  echo "  $key ($type): $(echo "$value" | tr '\n' ' ')"
done

echo
echo "Done. Verify with: docker exec -it ${CONTAINER_NAME} redis-cli KEYS '*'"
