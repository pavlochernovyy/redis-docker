resource "docker_network" "redis_net" {
  name = var.network_name
}

resource "docker_volume" "redis_data" {
  name = "redis-local-data"
}

resource "docker_volume" "redisinsight_data" {
  name = "redisinsight-local-data"
}

resource "docker_image" "redis" {
  name = var.redis_image
}

resource "docker_image" "redisinsight" {
  name = var.redisinsight_image
}

resource "docker_container" "redis" {
  name  = var.redis_container_name
  image = docker_image.redis.image_id

  networks_advanced {
    name    = docker_network.redis_net.name
    aliases = ["redis"]
  }

  ports {
    internal = 6379
    external = var.redis_port
  }

  volumes {
    volume_name    = docker_volume.redis_data.name
    container_path = "/data"
  }

  # Persist to disk so seeded data survives container restarts.
  command = ["redis-server", "--save", "60", "1", "--appendonly", "yes"]

  restart = "unless-stopped"
}

resource "docker_container" "redisinsight" {
  name  = var.redisinsight_container_name
  image = docker_image.redisinsight.image_id

  networks_advanced {
    name = docker_network.redis_net.name
  }

  ports {
    internal = 5540
    external = var.redisinsight_port
  }

  volumes {
    volume_name    = docker_volume.redisinsight_data.name
    container_path = "/data"
  }

  # Preconfigure the redis-local connection so it shows up automatically in the UI.
  env = [
    "RI_REDIS_HOST=host.docker.internal",
    "RI_REDIS_PORT=${var.redis_port}",
    "RI_REDIS_ALIAS=redis-local",
  ]

  restart = "unless-stopped"

  depends_on = [docker_container.redis]
}
