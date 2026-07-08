---
description: Bootstrap the redis-docker stack (terraform apply, seed data, start pub/sub)
---

Run the project bootstrap:

```bash
cd terraform
terraform init
terraform apply -auto-approve
cd ..
./scripts/seed.sh
./scripts/pubsub.sh start
```

After it completes:
- Remind the user how to connect to Redis from the RedisInsight UI (http://localhost:5540): add a database with host `redis` (shared `redis-local-net` docker network) port `6379`, or `host.docker.internal`/`localhost` port `6379` from outside Docker.
- Confirm the pub/sub publisher is running (`./scripts/pubsub.sh status`).
