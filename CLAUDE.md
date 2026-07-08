# redis-docker

Local Redis + RedisInsight stack, provisioned with Terraform (`kreuzwerker/docker` provider) and seeded with sample data.

## Layout

- `terraform/` — Terraform config that creates a docker network, two volumes, and the `redis-local` + `redisinsight-local` containers.
- `seed/seed-data.redis` — sample data (users, sessions, a queue, a set, a sorted-set leaderboard, config keys) in plain Redis command format.
- `seed/pubsub-messages.json` — message pool for the pub/sub publisher tool: each entry is a `{channel, payload}` template (see file for the full schema and `{{random_id}}`/`{{timestamp}}` placeholders).
- `scripts/seed.sh` — pipes `seed-data.redis` into the running Redis container and prints every key/value it seeded (also what makes the seeded data visible in CI logs).
- `scripts/pubsub.sh` — controls the pub/sub publisher tool (start/stop/status/one-off publish).
- `scripts/pubsub_publish.py` — helper invoked by `pubsub.sh`; picks random messages from `seed/pubsub-messages.json` and publishes them via `redis-cli PUBLISH`.
- `scripts/bootstrap.sh` — runs `terraform init`/`apply`, seeds data, and starts the pub/sub publisher (see Bootstrap below).
- `scripts/teardown.sh` — stops the pub/sub publisher, runs `terraform destroy`, and removes redis/redisinsight images; pass `--volumes` to also wipe persisted data.
- `.github/workflows/test-project.yml` — manually triggered (`workflow_dispatch`, "Run workflow" button in the Actions tab, available once merged to `master`) end-to-end smoke test: bootstrap (with pub/sub), verify Redis/publisher, then teardown, all in one job. GitHub-hosted runners are ephemeral, so nothing persists after the job — this doesn't stand up a reachable environment, it just verifies the scripts work end to end.

## Prerequisites

- Docker Desktop (or another local Docker daemon) running.
- Terraform >= 1.5.

## Bootstrap (first run)

Run `/bootstrap` or `./scripts/bootstrap.sh` directly (non-interactive, so it also works in CI — pass `--no-pubsub` to skip starting the publisher). This starts:
- Redis on `localhost:6379` (AOF persistence enabled, data in the `redis-local-data` volume), seeded with sample data.
- RedisInsight on `http://localhost:5540` (state in the `redisinsight-local-data` volume), with a `redis-local` connection (`host.docker.internal:6379`) preconfigured via `RI_REDIS_HOST`/`RI_REDIS_PORT`/`RI_REDIS_ALIAS` env vars on the container (see `terraform/main.tf`) — no manual setup needed. Note: these connections are wiped on restart if the env vars are removed.
- The pub/sub publisher background loop (see below), publishing a random message every 5s.

## Interacting

- **CLI**: `docker exec -it redis-local redis-cli`
- **Browse keys**: `docker exec -it redis-local redis-cli KEYS '*'`
- **Re-seed** any time (idempotent, just overwrites keys): `./scripts/seed.sh`

## Pub/sub publisher tool

A controllable tool that publishes messages (from `seed/pubsub-messages.json`) to Redis pub/sub channels. Requires `python3` (no extra deps) and the Redis container running.

```bash
./scripts/pubsub.sh publish [count]        # one-off: publish `count` random messages (default 2) to distinct channels
./scripts/pubsub.sh start [interval_sec]   # turn ON: background loop, 1 random message every interval (default 5s)
./scripts/pubsub.sh status                 # check whether it's running
./scripts/pubsub.sh stop                   # turn OFF
./scripts/pubsub.sh logs                   # print every message published so far by the background loop
```

The background loop's PID is tracked in `.pubsub.pid` and its output (every published message, printed by `pubsub_publish.py`) in `.pubsub.log` (both git-ignorable, project-local) — `./scripts/pubsub.sh logs` surfaces this, which is how published messages show up in CI logs too. To watch messages arrive live, subscribe in another terminal, e.g. `docker exec -it redis-local redis-cli PSUBSCRIBE '*'`.

To add/change messages or channels, edit `seed/pubsub-messages.json` — no script changes needed.

## Teardown

Run `/teardown` (see `.claude/commands/teardown.md`). It stops the pub/sub publisher, deletes `.pubsub.log`, destroys the terraform-managed resources, and removes the redis/redisinsight images. Add `--volumes` to also delete `redis-local-data` and `redisinsight-local-data`.

## Notes for future changes

- Ports, image tags, and container/network names are all Terraform variables (`terraform/variables.tf`) — override via `-var` or a `.tfvars` file rather than editing `main.tf`.
- Seed data lives in plain `.redis` command format (not RDB/JSON) so it's human-editable and diffable; add new keys there rather than scripting `SET` calls elsewhere.
