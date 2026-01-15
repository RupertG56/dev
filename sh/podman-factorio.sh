sudo podman run -d \
  -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v /nas/factorio:/factorio:Z \
  --name factorio \
  --restart=unless-stopped \
  factoriotools/factorio