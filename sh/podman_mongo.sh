sudo podman run --replace -d \
    --name mongodb \
    --network host \
    -v /nas/mongo/data:/data/db:Z \
    mongo