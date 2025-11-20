#creates container
#podman run --name samba -itd --network=host -e "NAME=media" -e "USER=samba" -e "PASS=password123" -v "/home/ryan/Downloads:/storage" dockurr/samba

sudo podman run --replace  --name samba -itd --network=host -e "PUID=1000" -e "PGID=1000" -e "NAME=nas" -e "USER=samba" -e "PASS=WfPo4*5b" -v "/nas:/storage:Z" docker.io/dockurr/samba

#start container
#podman start samba

#sudo firewall-cmd --permanent --zone=home --add-port=139/tcp
#sudo firewall-cmd --permanent --zone=home --add-port=445/tcp
