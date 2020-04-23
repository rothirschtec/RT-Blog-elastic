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
echo "Copy modules config files"
if [ -f ${hd}my-filebeat.yml ]; then
    rsync -a ${hd}my-filebeat.yml /etc/filebeat/filebeat.yml
fi
for config in ${hd}my-*.yml
do
	if [[ ! $config =~ "my-filebeat.yml" ]]; then
    		rsync -a ${config} /etc/filebeat/modules.d/${config##*/my-}
	fi
done

# # #
echo "Install executable"
mkdir -p /usr/share/filebeat/bin
read -p "arm (A) arm64 (64): " arch
if [[ $arch == "64" ]]; then
    rsync -a ${hd}filebeat-arm64 /usr/share/filebeat/bin/filebeat
else
    rsync -a ${hd}filebeat-arm /usr/share/filebeat/bin/filebeat
fi


# # # 
echo -e "\nEnable filebeat"
systemctl enable filebeat.service

# # #
echo -e "\nChoose the modules you want to use."

for module in "iptables" "system" "apache"
do
	read -p "$module (yN): " service
	if [[ $service == [yY] ]]; then
	    echo "Configure iptables"
	    filebeat modules enable $module
	fi
done

# # # 
echo -e "\nRestart filebeat"
chown -R root: /etc/filebeat/
chown -R root: /usr/share/filebeat/
service filebeat restart


# # #
echo -e "\nAdd logs prefix to you iptables rules"
echo '$IPT -A INPUT -m state --state NEW -j LOG --log-prefix="[netfilter] "
$IPT -A OUTPUT -m state --state NEW -j LOG --log-prefix="[netfilter] "
$IPT -A FORWARD -m state --state NEW -j LOG --log-prefix="[netfilter] "'
