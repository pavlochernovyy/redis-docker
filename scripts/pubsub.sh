#!/usr/bin/env bash
# Controls the pub/sub publisher tool against the local Redis container.
#
# Usage:
#   pubsub.sh publish [count]        one-off publish of `count` random messages (default 2) to distinct channels
#   pubsub.sh start [interval_sec]   start a background loop publishing 1 random message every interval (default 5s)
#   pubsub.sh stop                   stop the background loop
#   pubsub.sh status                 show whether the loop is running
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="${REDIS_CONTAINER_NAME:-redis-local}"
PID_FILE="$SCRIPT_DIR/../.pubsub.pid"
LOG_FILE="$SCRIPT_DIR/../.pubsub.log"

require_container() {
  if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '${CONTAINER_NAME}' is not running. Run 'terraform apply' first." >&2
    exit 1
  fi
}

cmd_publish() {
  local count="${1:-2}"
  require_container
  echo "Publishing ${count} random message(s) to ${CONTAINER_NAME}..."
  python3 "$SCRIPT_DIR/pubsub_publish.py" "$CONTAINER_NAME" "$count"
}

cmd_start() {
  local interval="${1:-5}"
  require_container

  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "Publisher already running (PID $(cat "$PID_FILE"))."
    exit 0
  fi

  echo "Starting background publisher (every ${interval}s)... logs: $LOG_FILE"
  nohup bash -c "
    while true; do
      python3 '$SCRIPT_DIR/pubsub_publish.py' '$CONTAINER_NAME' 1
      sleep '$interval'
    done
  " >"$LOG_FILE" 2>&1 &

  echo $! > "$PID_FILE"
  echo "Started (PID $(cat "$PID_FILE"))."
}

cmd_stop() {
  if [[ ! -f "$PID_FILE" ]] || ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "Publisher is not running."
    rm -f "$PID_FILE"
    exit 0
  fi

  local pid
  pid="$(cat "$PID_FILE")"
  pkill -P "$pid" 2>/dev/null || true
  kill "$pid" 2>/dev/null || true
  rm -f "$PID_FILE"
  echo "Stopped (PID $pid)."
}

cmd_status() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "Publisher running (PID $(cat "$PID_FILE"))."
  else
    echo "Publisher not running."
  fi
}

case "${1:-}" in
  publish) cmd_publish "${2:-2}" ;;
  start)   cmd_start "${2:-5}" ;;
  stop)    cmd_stop ;;
  status)  cmd_status ;;
  *)
    echo "Usage: $0 {publish [count]|start [interval_sec]|stop|status}" >&2
    exit 1
    ;;
esac
