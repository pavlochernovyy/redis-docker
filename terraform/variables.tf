variable "redis_image" {
  description = "Redis Docker image"
  type        = string
  default     = "redis:7-alpine"
}

variable "redisinsight_image" {
  description = "RedisInsight Docker image"
  type        = string
  default     = "redis/redisinsight:latest"
}

variable "redis_port" {
  description = "Host port mapped to Redis' 6379"
  type        = number
  default     = 6379
}

variable "redisinsight_port" {
  description = "Host port mapped to RedisInsight's 5540"
  type        = number
  default     = 5540
}

variable "network_name" {
  description = "Name of the docker network shared by both containers"
  type        = string
  default     = "redis-local-net"
}

variable "redis_container_name" {
  type    = string
  default = "redis-local"
}

variable "redisinsight_container_name" {
  type    = string
  default = "redisinsight-local"
}
