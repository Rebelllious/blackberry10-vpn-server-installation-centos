blackberry10-vpn-server-installation-centos
===========================================

The script for installing the Strongswan IPsec VPN server (with optional dynamic DNS updates using Noip Dynamic DNS Client for Linux
Here are the steps on how to use it:
1. Get a working instance of CentOS with working Internet connection.
2. In your Terminal window, type or copy-paste the following command:
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/Rebelllious/blackberry10-vpn-server-installation-centos/master/vpn.sh)
To execute this command, you will need wget installed on your system. You might already have it in case you have used this machine for some other tasks. In case you don't have it, please execute:
yum install wget -y
3. Type or copy-paste the following command:
bash <(wget -qO- --no-check-certificate https://github.com/Rebelllious/blackberry10-vpn-server-installation-centos/blob/master/vpn.sh)
This will start the installation script.
4. If you want to just install Strongswan, please answer "no" to the question concerning dynamic DNS configuration and switch now to step 5.
Yet, in case your IP is dynamic, you will have to say "yes" to this question and undergo some additional steps.
So, before installing the Linux Dynamic Update Client as part of your installation you have to visit http://noip.com and register for a free account. When registering, choose the domain name you like to be able to access your server using it afterwards.
After this you can say "yes" to the script question about dynamic IP and continue. The script will ask you for login and password to your NoIP account. When prompted, set the update interval according to your preferences. Using default suggested 30 minutes interval should be good in most cases.
5. Enter the information the script ask you: IP address of the server, gateway pre-shared key, user name and user password.
Please notice the script will only create configuration for one user (for test purposes, so to say). To add more users, use your favorite editor (like vi/vim) and edit /etc/ipsec.secrets to introduce or change user credentials.

Congratulations, your VPN server is now ready to use.
===========================================
Setting up a VPN profile on your BlackBerry 10 device

Create a new VPN profile using the following connection details:
Profile Name: the_name_you_wish_to_call_it
Server Address: VPN_server's_public_Internet_address (or your dynamic NoIP domain name if you used it)
Gateway Type: Generic IKEv2 VPN Server
Authentication Type: EAP-MSCHAPv2
Authentication ID Type: IPv4
MSCHAPv2 EAP Identity: your_user_name
MSCHAPv2 Username: your_user_name (username specified in /etc/ipsec.secrets)
MSCHAPv2 Password: your_password (user password specified in /etc/ipsec.secrets)
Gateway Auth Type: PSK
Gateway Auth ID Type: IPv4
Gateway Preshared Key: your_gateway_pre-shared_key (the PSK password specified in /etc/ipsec.secrets) 
Perfect Forward Secrecy: not checked
There is no need to change any "Advanced" configurations.

ENJOY IT!