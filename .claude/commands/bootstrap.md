---
description: Bootstrap the redis-docker stack (terraform apply, seed data, start pub/sub)
---

Run the project bootstrap:

```bash
./scripts/bootstrap.sh
```

After it completes:
- Remind the user that RedisInsight (http://localhost:5540) already has the `redis-local` connection preconfigured (`host.docker.internal:6379`) — no manual setup needed.
- Confirm the pub/sub publisher is running (`./scripts/pubsub.sh status`).
