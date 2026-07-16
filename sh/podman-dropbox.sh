sudo podman run \
  --replace -itd --name=dropbox \
  --restart=unless-stopped \
  --net="host" \
  -e "DROPBOX_UID=$(id -u)" \
  -e "DROPBOX_GID=$(id -g)" \
  -e "POLLING_INTERVAL=20" \
  -v "/etc/localtime:/etc/localtime" \
  -v "/nas/dbx/.dropbox:/opt/dropbox/.dropbox:Z" \
  -v "/nas/dbx/Dropbox:/opt/dropbox/Dropbox:Z" \
  docker.io/otherguy/dropbox:latest
