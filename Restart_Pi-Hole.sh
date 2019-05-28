#!/usr/local/bin/bash
# https://github.com/pi-hole/docker-pi-hole/blob/master/README.md

IP="${IP:-$IP_LOOKUP}"  # use $IP, if set, otherwise IP_LOOKUP
IPv6="${IPv6:-$IPv6_LOOKUP}"  # use $IPv6, if set, otherwise IP_LOOKUP
DOCKER_CONFIGS="$(pwd)"  # Default of directory you run this from, update to where ever.
oDNS1=$(scutil --dns | grep -e 'nameserver\[0\]' | head -1 | cut -d: -f2 | xargs)
oDNS2=$(scutil --dns | grep -e 'nameserver\[1\]' | head -1 | cut -d: -f2 | xargs)
nDNS=127.0.0.1

echo "Using "$oDNS1" and "$oDNS2" for DNS."

echo "Stopping Pi-Hole"
docker stop pihole

echo "Removing Pi-Hole"
docker rm pihole

# Log in to Docker
sh ./d

echo "Pulling Latest Pi-Hole"
docker image pull pihole/pihole

echo "Running Pi-Hole"
docker run -d \
    --name pihole \
    -p 53:53/udp \
    -p 53:53/tcp \
    -p 80:80 \
    -e TZ="UTC" \
    -e WEBPASSWORD="password" \
    -e DNS1=$oDNS1 \
    -e DNS2=$oDNS2 \
    -v "/Users/$USER/pihole/etc-pihole/:/etc/pihole/" \
    -v "/Users/$USER/pihole/etc-dnsmasq.d/:/etc/dnsmasq.d/" \
    --dns=$oDNS1 \
    --dns=$oDNS2 \
    --restart=unless-stopped \
    pihole/pihole:latest

    printf 'Starting up pihole container'
for i in $(seq 1 20); do
    if [ "$(docker inspect -f "{{.State.Health.Status}}" pihole)" == "healthy" ] ; then
    
        printf ' OK'
	
	echo -e "\nUpdating Default Wi-Fi DNS Server to "$nDNS
        sudo networksetup -setdnsservers Wi-Fi $nDNS

        echo -e "\nUpdating Resolv.Conf"
        sudo sed -i -e 's/nameserver\(.*\)/nameserver '$nDNS'/g' /etc/resolv.conf

        exit 0
    else
        sleep 3
        printf '.'
    fi

    if [ $i -eq 20 ] ; then
        echo -e "\nTimed out waiting for Pi-hole start start, consult check your container logs for more info (\`docker logs pihole\`)"
        exit 1
    fi

done;

