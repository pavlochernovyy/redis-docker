---
description: Tear down the redis-docker stack (stop pub/sub, terraform destroy, remove images)
---

Run:

```bash
./scripts/teardown.sh
```

Pass `--volumes` (i.e. `./scripts/teardown.sh --volumes`) if the user wants to also wipe the persisted data volumes (`redis-local-data`, `redisinsight-local-data`).

This already stops the pub/sub publisher, destroys the terraform-managed resources, and removes the redis/redisinsight docker images — no extra steps needed.
