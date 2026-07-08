#!/usr/bin/env python3
"""
Publishes messages from seed/pubsub-messages.json to the Redis pub/sub
channels defined there, via `docker exec <container> redis-cli PUBLISH`.

Usage:
  pubsub_publish.py <container_name> <count>

Picks <count> messages at random, preferring distinct channels, fills in
{{random_id}} / {{timestamp}} placeholders, and publishes each one.
"""
import json
import random
import string
import subprocess
import sys
import time
from pathlib import Path

MESSAGES_FILE = Path(__file__).resolve().parent.parent / "seed" / "pubsub-messages.json"


def random_id(n=8):
    return "".join(random.choices(string.ascii_lowercase + string.digits, k=n))


def fill_placeholders(payload):
    filled = {}
    for key, value in payload.items():
        if isinstance(value, str):
            value = value.replace("{{random_id}}", random_id())
            value = value.replace("{{timestamp}}", str(int(time.time())))
        filled[key] = value
    filled.setdefault("id", random_id(12))
    filled.setdefault("timestamp", int(time.time()))
    return filled


def pick_messages(pool, count):
    if count <= len(pool):
        return random.sample(pool, count)
    return [random.choice(pool) for _ in range(count)]


def publish(container, channel, payload):
    message = json.dumps(payload)
    result = subprocess.run(
        ["docker", "exec", "-i", container, "redis-cli", "PUBLISH", channel, message],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"  ! failed to publish to {channel}: {result.stderr.strip()}", file=sys.stderr)
        return
    subscribers = result.stdout.strip()
    print(f"  -> [{channel}] {message}  (subscribers: {subscribers})")


def main():
    if len(sys.argv) < 3:
        print("Usage: pubsub_publish.py <container_name> <count>", file=sys.stderr)
        sys.exit(1)

    container = sys.argv[1]
    count = int(sys.argv[2])

    data = json.loads(MESSAGES_FILE.read_text())
    pool = data["messages"]

    for entry in pick_messages(pool, count):
        publish(container, entry["channel"], fill_placeholders(entry["payload"]))


if __name__ == "__main__":
    main()
