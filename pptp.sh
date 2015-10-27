#!/bin/bash
ESC_SEQ="\x1b["
RST=$ESC_SEQ"39;49;00m"
GRN=$ESC_SEQ"32;01m"
BLU=$ESC_SEQ"34;01m"
INT=$(route |grep default |awk '{print $8}')
IP=$(ifconfig $INT |grep "inet addr:"|cut -d":" -f2|cut -d" " -f1)

echo -ne "$BLU Installing pptpd (This might take a while!) $RST"
  apt-get -y install pptpd >/dev/null
echo -e "$GRN[ Done ]$RST"

echo -ne "$BLU Setting pptpd localip to 192.168.100.1 $RST"
  if grep -q "^localip" /etc/pptpd.conf; then
    sed -i 's/^localip.*/localip 192.168.100.1/g' /etc/pptpd.conf
  else
    echo "localip 192.168.100.1" >> /etc/pptpd.conf
  fi
echo -e "$GRN[ Done ]$RST"

echo -ne "$BLU Set pptpd remoteip to 192.168.100.200-210 $RST"
  if grep -q "^remoteip" /etc/pptpd.conf; then
    sed -i 's/^remoteip.*/remoteip 192.168.100.200-210/g' /etc/pptpd.conf
  else
    echo "remoteip 192.168.100.200-210" >> /etc/pptpd.conf
  fi
echo -e "$GRN[ Done ]$RST"

echo -ne "$BLU Setting pptpd ms-dns to 114.114.114.114 (114dns) $RST"
  if grep -q "^ms-dns" /etc/ppp/options; then
    sed -i 's/^ms-dns.*/ms-dns 114.114.114.114/g' /etc/ppp/options
  else
    echo "ms-dns 114.114.114.114" >> /etc/ppp/options
  fi
echo -e "$GRN[ Done ]$RST"

echo -ne "$BLU Enter the username for this VPN connection: $RST"
  read -r user
echo -e "$BLU Enter the password for this VPN connection: $RST"
  read -rs pass
echo -ne "$BLU Applying the supplied credentials $RST"
  echo -e "$user\t*\t$pass\t*" >> /etc/ppp/chap-secrets
echo -e "$GRN[ Done ]$RST"

echo -ne "$BLU Enabling Port Forwarding and IP Masquerading$RST"
  if grep -q "^net.ipv4.ip_forward" /etc/sysctl.conf; then
    sed -i 's/^net\.ipv4.ip_forward.*/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
  else
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  fi
  sysctl -p >/dev/null
  iptables -t nat -I POSTROUTING -o "$INT" -j MASQUERADE
  iptables-save >/dev/null
echo -e "$GRN[ Done ]$RST"

echo -ne "$BLU Restarting pptpd $RST"
  service pptpd restart >/dev/null
echo -e "$GRN[ Done ]\n$RST"

echo -e "$BLU PPTPD is now running! $RST"
echo -e "$BLU Please configure your client to connect to $IP:1723\n$RST"

echo -e "$BLU Additionally, to tunnel all traffic destined for TCP ports 80 and 443 to Fiddler,\n\
 apply the following iptables rules: $RST"
echo -e "$GRN iptables -t nat -A PREROUTING -i ppp0 -p tcp --dport 80 -j REDIRECT --to-ports 8888 $RST"
echo -e "$GRN iptables -t nat -A PREROUTING -i ppp0 -p tcp --dport 443 -j REDIRECT --to-ports 8888 $RST"

echo -e "$GRN iptables -t nat -A PREROUTING -i ppp0 -p tcp --dport 80 -j DNAT --to 127.0.0.1:8888 $RST"
echo -e "$GRN iptables -t nat -A PREROUTING -i ppp0 -p tcp --dport 443 -j DNAT --to 127.0.0.1:8888 $RST"
