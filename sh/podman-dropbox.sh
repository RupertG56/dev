sudo podman run -itd --name=dropbox --restart=unless-stopped --net="host" -e "TZ=$(readlink /etc/localtime | sed 's#^.*/zoneinfo/##')" -e "DROPBOX_UID=$(id -u)" -e "DROPBOX_GID=$(id -g)" \
    -e "POLLING_INTERVAL=20" -v "/nas/dropbox/config:/opt/dropbox:Z" -v "/nas/dropbox/data:/opt/dropbox/Dropbox:Z" docker.io/otherguy/dropbox:latest
