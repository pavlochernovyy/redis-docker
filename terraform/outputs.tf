output "redis_connection" {
  value = "redis://localhost:${var.redis_port}"
}

output "redisinsight_url" {
  value = "http://localhost:${var.redisinsight_port}"
}
