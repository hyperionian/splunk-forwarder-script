#!/bin/sh

### Splunk forwarder automated remote installation script  ###############################
################################# Kheli Koh  #############################################
################################# securedhive.com  #######################################
################################# V 0.2  #################################################
################################# @khelikoh  - beehives  #################################
##########The Script must be copied to the machine  performing remote#####################
################# this is typically a deployment server machine###########################
######Installation and the fwd_hosts file must be supplied in the /usr/local/share########
#################with the format of splunk@splunkforwarder target IP######################
##########################################################################################

###Setting Variables #####################################################################
DEST_FWD=/usr/local/share/fwd_hosts

#PACKAGES DOWNLOAD links
FWD_PACKAGE_RPM=splunkforwarder-6.0.1-189883-linux-2.6-x86_64.rpm 'http://www.splunk.com/page/download_track?file=6.0.1/universalforwarder/linux/splunkforwarder-6.0.1-189883-linux-2.6-x86_64.rpm&ac=&wget=true&name=wget&platform=Linux&architecture=x86_64&version=6.0.1&product=splunkd&typed=release&elq=b908044c-cf0b-40b2-82f1-e55004dc5718'
FWD_PACKAGE_TGZ=splunkforwarder-6.0.1-189883-Linux-x86_64.tgz 'http://www.splunk.com/page/download_track?file=6.0.1/universalforwarder/linux/splunkforwarder-6.0.1-189883-Linux-x86_64.tgz&ac=&wget=true&name=wget&platform=Linux&architecture=x86_64&version=6.0.1&product=splunkd&typed=release&elq=b908044c-cf0b-40b2-82f1-e55004dc5718'
FWD_PACKAGE_DEB=splunkforwarder-6.0.1-189883-linux-2.6-amd64.deb 'http://www.splunk.com/page/download_track?file=6.0.1/universalforwarder/linux/splunkforwarder-6.0.1-189883-linux-2.6-amd64.deb&ac=&wget=true&name=wget&platform=Linux&architecture=x86_64&version=6.0.1&product=splunkd&typed=release&elq=b908044c-cf0b-40b2-82f1-e55004dc5718'


### Reading user inputs to populate variables for installation
#Specify the package type
echo "Please enter your forwarder package (RPM/TGZ/DEB)"
read -p "PACKAGE: " PACKAGE

#Specify the package to download
if [ "$PACKAGE" == "RPM" ] ;
 then
FWD_PACKAGE=$FWD_PACKAGE_RPM
DOWNLOAD_CMD=wget -O "$FWD_PACKAGE"

elif [ "$PACKAGE" == "TGZ" ] ;
 then
FWD_PACKAGE=$FWD_PACKAGE_TGZ
DOWNLOAD_CMD=wget -O "$FWD_PACKAGE"

elif [ "$PACKAGE" == "DEB"];
 then
FWD_PACKAGE=$FWD_PACKAGE_DEB
DOWNLOAD_CMD=wget -O "$FWD_PACKAGE"
else
  echo "No forwarder package specified either RPM or TGZ or DEB... aborting..."
  exit 1
fi

#New splunkd password
echo "Please enter your new splunkd password"
read -s -p "New Password: " password

# Deployment server
echo "Please enter your deployment server IP"
read -p "Deployment Server: " IP


### Installation script ##################################################################
INSTALL_SCRIPT="

cd /opt
$DOWNLOAD_CMD

if [ "$PACKAGE" == "TGZ" ];
  then
  tar -xzf splunkforwarder-6.0.1-189883-Linux-x86_64.tgz
elif [ "$PACKAGE" == "RPM" ];
then
  rpm -i splunkforwarder-6.0.1-189883-linux-2.6-x86_64.rpm
else
   dpkg -i splunkforwarder-6.0.1-189883-linux-2.6-amd64.deb
fi

/opt/splunkforwarder/bin/splunk enable boot-start -user splunk
/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --auto-ports --no-prompt
/opt/splunkforwarder/bin/splunk edit user admin -password "$password" -auth admin:changme

#Deploying deployment client app

if [[ ! -e /opt/splunkfowarder/bin/splunk ];
   then
  echo " Splunk forwarder failed to install in specified location. Aborting..."
  exit 1
fi

#Create the deployment client app file
mkdir -p /opt/splunkforwarder/etc/apps/deploy_client/default/
cat > deploymentclient.conf << EOF
[[target-broker:deploymentServer]
targetUri = "$IP":8089
EOF

echo "Starting Splunkd..."
/opt/splunkforwarder/bin/splunk restart
"
### end of remote installation script#####################################################

echo "Remote installation script will run in a moment"
sleep 3
echo " Starting... "

for $TARGET in `cat "$DEST_FWD"`; do
	if [ -z $TARGET]; then
	   echo " Please specify targets in the /home/splunk/fwd_hosts file"
	   exit1
	fi
   echo "*************************************************************"
   echo "Installing splunk forwarder to $TARGET"
 
   ssh "$TARGET" "$INSTALL_SCRIPT"
done 
echo " Remote installation of Splunk forwarder is completed"
