#!/bin/bash
echo "Init VPN DDoS Attack Alerts"
echo  # Space

# Variables
interface="<interface>"
dumpdir=/root/dumps

ports=("80" "443" "22")
url='https://discord.com/api/webhooks/1245871944138756147/jSO-Y3zJRWXq6kY45Jo7OPlj_h9yA1vcBANbB3AZWbOsngFQgJIkc3hkT_FXtIaqahCw'


check_ddos_attack_on_port() {
    local port=$1
    echo "Checking for DDoS attack on port $port..."

    local connection_count=$(netstat -an | grep ":$port" | wc -l)
    echo "$connection_count"
}


while true; do
    old_b=$(grep "$interface:" /proc/net/dev | awk '{print $2}')
    old_ps=$(grep "$interface:" /proc/net/dev | awk '{print $3}')

    sleep 1

    new_b=$(grep "$interface:" /proc/net/dev | awk '{print $2}')
    new_ps=$(grep "$interface:" /proc/net/dev | awk '{print $3}')

    # Calculating Packets/s
    pps=$((new_ps - old_ps))

    # Calculating Bytes/s
    byte=$((new_b - old_b))

    gigs=$((byte / 1024 ** 3))
    mbps=$((byte / 1024 ** 2))
    kbps=$((byte / 1024))

    echo -e "\033[97mPackets/s \033[36m$pps\n\033[97mBytes/s \033[36m$byte\n\033[97mKbp/s \033[36m$kbps\n\033[97mGbp/s \033[36m$gigs\n\033[97mMbp/s \033[36m$mbps"
    echo

    tcpdump -i "$interface" -n -s0 -c 519 -w "$dumpdir/capture.$(date +"%Y%m%d").pcap"

    echo "$(date) Detecting Attack Packets."
    echo

    sleep 1

    # Value PPS 263507 for attack
    if [ $pps -gt 263507 ]; then ## Always true
        echo "Attack Detected. Monitoring Incoming Traffic..."

        max_connections=0 dport=0

        for port in "${ports[@]}"; do
            connection_count=$(check_ddos_attack_on_port $port)

            connections="$(echo $connection_count | grep -oP '(?<=\.\.\.).*')"
            connections=${connections/ /}

            echo "Port $port has $connection_count connections."

            if [[ $connections > $max_connections ]]; then
                max_connections=$connections
                dport=$port
            fi
        done

        # Simple treatment
        old_ps=$((old_ps / 1000))
        old_b=$((old_b / 1000000))

        # Run the python script
        destIp=$(python detected_isp.py)

        # Separate using cut
        location=$(echo "$destIp" | awk -F ':' '{print $2}')
        destIp=$(echo "$destIp" | cut -d '|' -f 2)

        # Replaces spaces with -, for some reason the discord embed has a bug when there are spaces in the variable
        location=$(echo "$location" | xargs)
        location=$(echo "$location" | tr ' ' '-')

        destIp=$(echo "$destIp" | xargs)

        echo  # Space
        echo $location
        echo $destIp

        if [ "$destIp" == "No source IP found" ]; then
            destIp='Proxied!'
	    else
            echo "Potential DDoS IPs and their locations:"
        fi

    curl -H "Content-Type: application/json" -X POST -d '{
      "embeds": [{
        "title": "🚨 Attack Detected On",
        "username": "DDoS Attack Alert!",
        "color": 15158332,
        "thumbnail": {
          "url": "https://i.imgur.com/59ubUbx.jpeg"
        },
        "footer": {
          "text": "Our Tempest A.I. system has mitigated the attack.",
          "icon_url": "https://cdn.countryflags.com/thumbs/united-states-of-america/flag-800.png"
        },
        "description": "🔍Detection of an attack: '$(date +"%H:%M")'",
        "fields": [
          {"name": "**🌐 Server Provider**", "value": "Tempest Hosting LLC", "inline": false},
          {"name": "**🎯 Source**", "value": "'$destIp' | '$location'", "inline": false},
          {"name": "**🎯 Destination**", "value": "IP Address: 45.88.228.55", "inline": false},
          {"name": "**⬅ Incoming Port:**", "value": "'$dport'", "inline": false},
          {"name": "**⬅ Incoming Bandwith: **", "value": "'$old_ps' PPS", "inline": false},
          {"name": "**💾 Total MB:**", "value": "'$old_b' MB", "inline": false}
        ]
      }]
    }' "$url"

        echo "Paused for."
        sleep 120 && pkill -HUP -f /usr/sbin/tcpdump

        echo -e "\033[97mPackets/s \033[36m$pps\n\033[97mBytes/s \033[36m$byte\n\033[97mKbp/s \033[36m$kbps\n\033[97mGbp/s \033[36m$gigs\n\033[97mMbp/s \033[36m$mbps"

        # Simple treatment
        new_ps=$((new_ps / 1000))
        new_b=$((new_b / 1000000))

        if [ $new_b > 1023 ]; then
            new_b="$(echo "scale=2; $new_b / 1024" | bc)"
            TGBPS="GB"
        else
            TGBPS="MB"
        fi

    curl -H "Content-Type: application/json" -X POST -d '{
      "embeds": [{
        "title": "🚨 Attack Stopped",
        "username": "DDoS Stop Alert!",
        "color": 65280,
        "thumbnail": {
          "url": "https://i.imgur.com/J4jt60N.png"
        },
        "footer": {
          "text": "Our Tempest A.I. system has mitigated the attack.",
          "icon_url": "https://cdn.countryflags.com/thumbs/united-states-of-america/flag-800.png"
        },
        "description": "🔍Source of the attacker",
        "fields": [
          {"name": "**🌐 Server Provider**", "value": "Tempest Hosting LLC", "inline": false},
          {"name": "**🎯 Source**", "value": "IP Address: '$destIp' | '$location'", "inline": false},
          {"name": "**🎯 Destination**", "value": "Our IP: 45.88.228.55", "inline": false},
          {"name": "**⬅ Incoming Port:**", "value": "'$dport'", "inline": false},
          {"name": "**⬅ Incoming Packets: **", "value": "'$new_ps' PPS", "inline": false},
          {"name": "**💾 Total '$TGBPS':**", "value": "'$new_b' Gbps", "inline": false}
        ]
      }]
    }' "$url"
    fi
done
