### backend for "Try Online" at http://spacemacs.org/

#### usage:
```
docker network create -d overlay --attachable --internal maxnet

docker service create \
    --replicas 1 \
    --name traefik \
    --constraint=node.role==manager \
    --publish 10000:80 --publish 8081:8081 \
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    --network=maxnet \
    traefik \
        -c /dev/null \
        --web \
        --web.address=:8081 \
        --web.ReadOnly=true \
        --docker \
        --docker.domain=<YOUR_BACKEND_DOMAIN_NAME> \
        --docker.endpoint=unix:///var/run/docker.sock \
        --docker.watch=true \
        --docker.swarmmode=true \
        --docker.exposedbydefault=true

docker service create \
    --replicas 16 \
    --name browsermax \
    -e APPROXIMATE_MAX_CONNECTION_LENGTH_S=3600 \
    --limit-memory 300M \
    --limit-cpu 0.5 \
    --read-only \
    --mount type=tmpfs,destination="/home/emacs/.emacs.d/.cache",tmpfs-mode="777",tmpfs-size="20M" \
    --label traefik.backend=browsermax \
    --label traefik.port=10000 \
    --label traefik.network=maxnet \
    --label traefik.frontend.rule=Host:<YOUR_BACKEND_DOMAIN_NAME> \
    --label traefik.frontend.entryPoints=http \
    --label traefik.protocol=ws \
    --network=maxnet \
    jare/browsermax:latest
```
