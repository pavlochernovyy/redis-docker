---
description: Tear down the redis-docker stack (stop pub/sub, terraform destroy, remove images)
---

Before running, ask the user whether they also want to wipe the persisted data volumes (`redis-local-data`, `redisinsight-local-data`). Then run:

```bash
./scripts/teardown.sh          # keep data volumes
./scripts/teardown.sh --volumes  # also wipe data volumes
```

This already stops the pub/sub publisher, destroys the terraform-managed resources, and removes the redis/redisinsight docker images — no extra steps needed.
