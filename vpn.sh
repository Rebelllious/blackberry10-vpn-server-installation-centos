#!/bin/bash
############################################
noip() {
#add IP address check and writing it to VPN server configuration on boot
echo "var=\$(curl -s http://checkip.dyndns.org/ | grep -i address | grep -o \"[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\")" >> /etc/rc.d/rc.local
echo "sed -i '17 c\\
   leftid='\$var'' /etc/ipsec.conf" >> /etc/rc.d/rc.local
   
#download the source file of the NoIP client
wget https://www.noip.com/client/linux/noip-duc-linux.tar.gz

#create directory specially for further unpacking of source file
#(the version of NoIP client can be upgraded with time, and this folder will remain the same always)
mkdir /etc/noip

#unpack the tarball
tar -xzvf noip-duc-linux.tar.gz -C /etc/noip

#go to the directory (independent of further upgrades of the NoIP client
noipfolder=$(find /etc/noip/ -name "noip-*" -type d)
cd $noipfolder

#compile and install
make
make install

#add NoIP client to autoloading on boot
echo "/usr/local/bin/noip2" >> /etc/rc.local

#run the NoIP client
/usr/local/bin/noip2
#after installation the configuration script of NoIP will start automatically
}
#############################################
strongswan() {
#starting the Strongswan part of party
echo "Now the Strongswan VPN server installation starts"

#ask for server address
echo "Type the public IP address of your server, followed by [ENTER]:"
read IP

#ask for gateway preshared key
echo "Type the gateway preshared key to be used, followed by [ENTER]:"
read gatewaykey

#ask for user name
echo "Type the test user to be used, followed by [ENTER]:"
read username

#ask for user password
echo "Type the test user password to be used, followed by [ENTER]:"
read userpass

#updating the system
yum -y update;

#installing necessary software prerequisites
yum -y install gmp-devel openldap-devel libcurl-devel openssl-devel

#downloading Strongswan source
wget http://download.strongswan.org/strongswan-5.1.1.tar.bz2

#create directory for Strongswan unpacking
mkdir /etc/strongswan

#unpack the Strongswan tarball
tar xjvf strongswan-5.1.1.tar.bz2 -C /etc/strongswan

#go to correct folder 
strongswanfolder=$(find /etc/strongswan/ -name "strongswan-*" -type d)
cd $strongswanfolder

#configuring Strongswan build
./configure --prefix=/usr --sysconfdir=/etc --enable-curl --enable-ldap --enable-pkcs11 --enable-md4 --enable-openssl --enable-ccm --enable-gcm --enable-farp --enable-eap-identity --enable-eap-aka --enable-eap-aka-3gpp2 --enable-eap-md5 --enable-eap-gtc --enable-eap-mschapv2 --enable-eap-dynamic --enable-eap-radius --enable-eap-tls --enable-eap-ttls --enable-eap-peap --enable-eap-tnc --enable-xauth-eap --enable-dhcp --enable-charon

#compile the source
make

#install Strongswan
make install

#edit iptables rules (UDP ports 500, 4500 and 1701 shall be opened)
iptables -I POSTROUTING -t nat -o eth0 -j MASQUERADE
iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
iptables -I INPUT -p udp --dport 500 -j ACCEPT
iptables -I INPUT -p udp --dport 4500 -j ACCEPT
iptables -I INPUT -p udp --dport 1701 -j ACCEPT

#save iptables rules
service iptables save

#edit iptables in order to get rid of any REJECT rules, as Strongswan will not allow traffic to pass through it in case there are some REJECTs
sed -i '/REJECT/d' /etc/sysconfig/iptables

#restart iptables to bring changes into effect
service iptables restart

#change core parameters for Strongswan to work properly
sed -i -e 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sed -i '/net.ipv4.ip_forward = 1/a net.net.ipv4.conf.default.proxy_arp = 1' /etc/sysctl.conf
sed -i '/net.net.ipv4.conf.default.proxy_arp = 1/a net.ipv4.conf.default.arp_accept = 1' /etc/sysctl.conf
sed -i '/net.ipv4.conf.default.arp_accept = 1/a net.ipv4.conf.default.proxy_arp_pvlan = 1' /etc/sysctl.conf

sed -i -e 's/net.bridge.bridge-nf-call-ip6tables = 0/#net.bridge.bridge-nf-call-ip6tables = 0/g' /etc/sysctl.conf
sed -i -e 's/net.bridge.bridge-nf-call-iptables = 0/#net.bridge.bridge-nf-call-iptables = 0/g' /etc/sysctl.conf
sed -i -e 's/net.bridge.bridge-nf-call-arptables = 0/#net.bridge.bridge-nf-call-arptables = 0/g' /etc/sysctl.conf

#load new core parameters
sysctl -p

#edit configuration file with gateway preshared key, user names and passwords
echo ": PSK \"$gatewaykey\"
$username : EAP \"$userpass\"" > /etc/ipsec.secrets

#edit VPN server configuration file 
echo "config setup
    strictcrlpolicy=no

conn %default
   ikelifetime=24h
   keylife=24h
   keyexchange=ikev2
   dpdaction=clear
   dpdtimeout=3600s
   dpddelay=3600s
   compress=yes

conn rem
   rekey=no
   leftsubnet=0.0.0.0/0
   leftauth=psk
   leftid=$IP
   right=%any
   rightsourceip=192.168.2.100/29
   rightauth=eap-mschapv2
   rightsendcert=never
   eap_identity=%any
   auto=add" > /etc/ipsec.conf

#edit Strongswan configuration file
echo "charon {
   threads = 16
   dns1 = 8.8.4.4
   dns2 = 8.8.8.8
}

pluto {
}

libstrongswan {
}" > /etc/strongswan.conf

#configure ipsec (VPN) service to start at server boot time
echo "ipsec start" >> /etc/rc.d/rc.local

#start VPN server service
ipsec start
}
#############################################
#install wget to be able to download files from the Internet, will be needed anyway
yum install wget vim make gcc glibc glibc-headers unzip -y

#ask if dynamic DNS configuration will be used
echo "Will you use dynamic DNS configuration for this installation? [yes/no]"
read dynamic
if [ "$dynamic" == "no" ]
then
	#only Strongswan stuff is installed
	strongswan
elif [ "$dynamic" == "yes" ]
then
	#NoIP and Strongswan are installed
	noip
	strongswan
else
	echo "First make your decision concerning dynamic DNS use, then try again. Exiting installation process..."
	exit
fi
