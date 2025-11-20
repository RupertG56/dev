# Run container using host network
sudo podman run --replace -d \
    --name "mariadb" \
    --network host \
    -v "/nas/mariadb/data:/var/lib/mysql:Z" \
    -e MYSQL_ROOT_PASSWORD="7dVdjKmkFv7r9D" \
    -e MARIADB_USER="ryan" \
    -e MARIADB_PASSWORD="q27g5IrAbljHW3" \
    -e MARIADB_DATABASE="ryan_db"
    --restart=always \
    "docker.io/library/mariadb:latest"

echo "MariaDB container 'mariadb' started using host network. Data stored in volume '/nas/mariadb/data'."