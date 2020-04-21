#!/bin/bash


cd $(dirname $0)
cd ../
hd="$PWD/"
id="${hd}filebeat-latest/"

# # # 
echo "Install configuration files"
rsync -a ${id}fields.yml ${id}filebeat.reference.yml ${id}filebeat.yml ${id}modules.d /etc/filebeat/
rsync -a ${id}LICENSE.txt ${id}kibana ${id}module ${id}NOTICE.txt ${id}README.md /usr/share/filebeat/
rsync -a ${hd}RT-Blog-elastic/filebeat.service /lib/systemd/system/
rsync -a ${hd}RT-Blog-elastic/bin-filebeat /usr/bin/filebeat

rsync -a ${hd}RT-Blog-elastic/init.d-filebeat /etc/init.d/filebeat
chmod +x /etc/init.d/filebeat

# # #
if [ -f ${hd}my-filebeat.yml ]; then
    rsync -a ${hd}my-filebeat.yml /etc/filebeat/filebeat.yml
fi
if [ -f ${hd}my-iptables.yml ]; then
    rsync -a ${hd}my-iptables.yml /etc/filebeat/modules.d/iptables.yml
fi
chown -R root: /etc/filebeat/

echo "Install executable"
mkdir -p /usr/share/filebeat/bin
read -p "arm (A) arm64 (64): " arch
if [[ $arch == "64" ]]; then
    rsync -a ${hd}filebeat-arm64 /usr/share/filebeat/bin/filebeat
else
    rsync -a ${hd}filebeat-arm /usr/share/filebeat/bin/filebeat
fi


# # # 
echo "Enable filebeat"
systemctl enable filebeat.service
systemctl restart filebeat.service


# # #
read -p "iptables (yN)" iptables
if [[ $iptables == [yY] ]]; then
    echo "Configure iptables"
    filebeat modules enable iptables
fi

# # #
read -p "system (yN)" system
if [[ $system == [yY] ]]; then
    echo "Configure system"
    filebeat modules enable system
fi

# # #
read -p "apache (yN)" apache
if [[ $apache == [yY] ]]; then
    echo "Configure apache"
    filebeat modules enable apache
fi

# # # 
echo "Restart filebeat"
service filebeat restart

# # #
#echo Configure rsyslog
#echo ':msg,contains, "[netfilter] " /var/log/iptables.log' > /etc/rsyslog.d/iptables.conf
#service rsyslog restart

# # #
echo Add logs prefix to you iptables rules
echo '$IPT -A INPUT -m state --state NEW -j LOG --log-prefix="[netfilter] "\
$IPT -A OUTPUT -m state --state NEW -j LOG --log-prefix="[netfilter] "\
$IPT -A FORWARD -m state --state NEW -j LOG --log-prefix="[netfilter] "'
