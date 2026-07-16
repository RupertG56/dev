volume=/nas/factorio/server1
if [[ -n "$2" ]]; then
	volume=$2
fi
name=factorio
if [[ -n "$1" ]]; then
	name=$1
fi
udp_bind=34197
if [[ -n "$3" ]]; then
	udp_bind=$3
fi
tcp_bind=27015
if [[ -n "$4" ]]; then
	tcp_bind=$4
fi

podman run -d \
  --userns=keep-id \
  -p $udp_bind:34197/udp \
  -p $tcp_bind:27015/tcp \
  -v $volume:/factorio:Z \
  --name $name \
  --restart=unless-stopped \
 docker.io/factoriotools/factorio:latest-rootless
