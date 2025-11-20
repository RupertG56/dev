sudo podman run --replace -d --name=nzb -e PUID=1000 -e PGID=1000 -e TZ=America/Denver --network=host -v /nas/nzb/config:/config:Z -v /nas/nzb/downloads:/downloads:Z --restart unless-stopped lscr.io/linuxserver/nzbget:latest


# Optional
# -e NZBGET_USER=nzbget
# -e NZBGET_PASS=pass
