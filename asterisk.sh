#!/bin/sh
asterisk=0
sed -i 's/no/yes/g' /etc/sysconfig/network-scripts/ifcfg-eth0
echo "4. Asterisk 1.8.X version"

ast_file="asterisk-1.8.20.1.tar.gz"
ast_sound_file="asterisk-sounds-1.2.1.tar.gz"
dahdi_file="dahdi-linux-complete-current.tar.gz"
libpri_file="libpri-1.4-current.tar.gz"

yum -y install nano gcc gcc-c++ kernel-devel mlocate make openssl openssl-devel perl-Net-SSLeay perl-Crypt-SSLeay libtermcap-devel ncurses-devel doxygen curl-devel newt-devel mod_ssl crontabs vixie-cron speex speex-devel unixODBC unixODBC-devel libtool-ltdl libtool-ltdl-devel flex screen mod_ssl build-essential libxml2 libxml2-devel wget vim-enhanced

mkdir -p /usr/src/asterisk
ntpdate pool.ntp.org

asterisk_url="http://downloads.asterisk.org/pub/telephony/asterisk/old-releases/"
dahdi_url="http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/"
libpri_url="http://downloads.digium.com/pub/libpri/"

cd /usr/src/asterisk 

wget http://sourceforge.net/projects/lame/files/lame/3.98.4/lame-3.98.4.tar.gz
tar zxvf lame-3.98.4.tar.gz
cd lame-3.98.4
./configure
make
make install
cd ..

yum -y install libogg libogg-devel
wget http://downloads.xiph.org/releases/speex/speex-1.2rc1.tar.gz
tar -xvf speex-1.2rc1.tar.gz
cd speex-1.2rc1
./configure
make
make install
echo "/usr/local/lib">/etc/ld.so.conf.d/speex.conf
ldconfig

server=`uname -m`
echo "Server details $server"
if [ "$server" == "x86_64" ]; then
        echo "64 bit server"
        wget http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.1-1.el5.rf.x86_64.rpm
        rpm -ivh rpmforge-release-0.5.1-1.el5.rf.x86_64.rpm
fi

if [ "$server" == "i686" ]; then
        echo "32 bit server"
        wget http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.1-1.el5.rf.i386.rpm
        rpm -ivh rpmforge-release-0.5.1-1.el5.rf.i386.rpm
fi

if [ "$server" == "i386" ]; then
        echo "32 bit server"
        wget http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.1-1.el5.rf.i386.rpm
        rpm -ivh rpmforge-release-0.5.1-1.el5.rf.i386.rpm
fi

echo "Downloading all the files"
echo $asterisk_url$ast_file
wget $asterisk_url$ast_file
echo $asterisk_url$ast_addon_file
wget $asterisk_url$ast_addon_file
echo $asterisk_url$ast_sound_file
wget $asterisk_url$ast_sound_file
echo $dahdi_url$dahdi_file
wget $dahdi_url$dahdi_file
echo $libpri_url$libpri_file
wget $libpri_url$libpri_file

echo "Extracting all the downloads"
tar -zxf $ast_file
tar -zxf $ast_addon_file
tar -zxf $ast_sound_file
tar -zxf $dahdi_file
tar -xzf $libpri_file

echo "Cleaning up all the downloads"
rm -f *.tar.gz

libpri=`ls -l | grep libpri | awk '{print $9}'`
cd $libpri
make clean
make
make install

cd ..
dahdi=`ls -l | grep dahdi-linux | awk '{print $9}'`
cd $dahdi
make all 
make install 
make config
service dahdi start

cd ..
asterisk=`ls -l | grep asterisk-1 | awk '{print $9}'`
cd $asterisk
make clean
./configure
make 
make install
make samples 
make config 

cd ..
asterisk_addons=`ls -l | grep asterisk-addons | awk '{print $9}'`
cd $asterisk_addons
make clean 
./configure 
make 
make install
make samples

cd ..
asterisk_sound=`ls -l | grep asterisk-sounds | awk '{print $9}'`
cd $asterisk_sound
make install

cd ..
cd ..

echo "=======================================Securing asterisk==============================="
groupadd -g 5060 asterisk
adduser -c "$1" -d /var/lib/asterisk -g asterisk -u 5060 asterisk

chown --recursive  asterisk:asterisk /var/lib/asterisk
chown --recursive  asterisk:asterisk /var/log/asterisk
chown --recursive  asterisk:asterisk /var/run/asterisk
chown --recursive  asterisk:asterisk /var/spool/asterisk
chown --recursive  asterisk:asterisk /usr/lib/asterisk
chmod --recursive  u=rwX,g=rX,o= /var/lib/asterisk
chmod --recursive  u=rwX,g=rX,o= /var/log/asterisk
chmod --recursive  u=rwX,g=rX,o= /var/run/asterisk
chmod --recursive  u=rwX,g=rX,o= /var/spool/asterisk
chmod --recursive  u=rwX,g=rX,o= /usr/lib/asterisk

sed -i 's/;runuser/runuser/g' /etc/asterisk/asterisk.conf
sed -i 's/;rungroup/rungroup/g' /etc/asterisk/asterisk.conf
sed -i 's/#AST_USER/AST_USER/g' /etc/sysconfig/asterisk
sed -i 's/#AST_GROUP/AST_GROUP/g' /etc/sysconfig/asterisk
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

cd /usr/lib/asterisk/modules/
scp -P 10022 ramesh@voscdr2.gventure.net:/home/ramesh/*.so .

service iptables stop 
chkconfig iptables off
echo "=======================================Securing asterisk==============================="

service mysqld start
chkconfig --add mysqld
chkconfig --add httpd
chkconfig --add asterisk
chkconfig asterisk on
chkconfig mysqld on
chkconfig httpd on
service asterisk start
service mysqld start
service httpd start

echo "Installing openvpn================================================="
cd /usr/src/
yum -y install openvpn
chkconfig --add openvpn
chkconfig openvpn on
#mkdir -p /etc/openvpn
#cp /usr/share/doc/openvpn-*/sample-config-files/server.conf /etc/openvpn

service openvpn restart
sleep 10
#cd /etc/openvpn
#scp ramesh@voscdr2.gventure.net:/home/ramesh/client1.tgz .
#tar -xzf client1.tgz
#mv tmp/* .
iax="/etc/asterisk/iax.conf"
sip="/etc/asterisk/sip.conf"
ext="/etc/asterisk/extensions.conf"

echo "[general]">$iax
echo "bindport=4569">>$iax
echo "bandwidth=low">>$iax
echo "disallow=lpc10">>$iax
echo "jitterbuffer=no">>$iax
echo "forcejitterbuffer=no">>$iax
echo "">>$iax
echo "register => client1:asterisk@172.17.0.1">>$iax
echo "autokill=yes">>$iax
echo "">>$iax
echo "[V_client1]">>$iax
echo "type=friend">>$iax
echo "host=dynamic">>$iax
echo "trunk=yes">>$iax
echo "secret=asterisk">>$iax
echo "context=calling">>$iax
echo "disallow=all">>$iax
echo "allow=all">>$iax
echo "permit=172.17.0.1/255.255.255.255">>$iax

echo "[calling]">>$ext
echo "exten => _1X., 1, Dial(SIP/dev1/\${EXTEN:1})">>$ext
echo "exten => _2X., 1, Dial(SIP/dev2/\${EXTEN:1})">>$ext
echo "exten => _3X., 1, Dial(SIP/dev3/\${EXTEN:1})">>$ext
echo "exten => _4X., 1, Dial(SIP/dev4/\${EXTEN:1})">>$ext

echo "[route](!)">>$sip
echo "type=friend">>$sip
echo "context=calling">>$sip
echo "disallow=all">>$sip
echo "allow=ulaw">>$sip
echo "allow=alaw">>$sip
echo "dtmfmode=rfc2833">>$sip
echo "nat=yes">>$sip
echo "insecure=port,invite">>$sip
echo "directmedia=yes">>$sip
echo "qualify=10000">>$sip

echo "">>$sip
echo "[dev1](route)">>$sip
echo "host=dynamic">>$sip
echo "defaultuser=dev1">>$sip
echo "secret=gvsol786">>$sip
echo "">>$sip
echo "[dev2](route)">>$sip
echo "host=dynamic">>$sip
echo "defaultuser=dev2">>$sip
echo "secret=gvsol786">>$sip
echo "">>$sip
echo "[dev3](route)">>$sip
echo "host=dynamic">>$sip
echo "defaultuser=dev3">>$sip
echo "secret=gvsol786">>$sip
echo "">>$sip
echo "[dev4](route)">>$sip
echo "host=dynamic">>$sip
echo "defaultuser=dev4">>$sip
echo "secret=gvsol786">>$sip

service asterisk restart
ifconfig
asterisk -rvvvvvvvvvvvvvvvvvvv
