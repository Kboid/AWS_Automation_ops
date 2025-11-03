import docker

client = docker.from_env()
client.containers.run("nginx", detach=True, ports={"80/tcp": 80})
print("Nginx container started")
