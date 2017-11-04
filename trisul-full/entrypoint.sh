#!/bin/bash
# (c) Trisul Network Analytics 
# Docker entry point for Trisul-Full



# Command line options
START_INTERFACE=
WEBSERVER_PORT=
WEBSOCKETS_PORT=
CAPTURE_FILE=
while true; do
  case "$1" in
	-i | --interface )  START_INTERFACE="$2"; shift 2 ;;
	-f | --pcap )       CAPTURE_FILE="$2"; shift 2 ;;
    --webserver-port )  WEBSERVER_PORT="$2"; shift 2 ;;
    --websockets-port ) WEBSOCKETS_PORT="$2"; shift 2 ;;
    -- ) shift; break ;;
	* ) if [ ! -z "$1" ]; then 
			echo "Unknown option [$1]"; 
		fi
		break ;;
  esac
done

if [ ! -z "$START_INTERFACE" ]; then
echo  INTF Start interface set $START_INTERFACE
echo  INTF Using ETHTOOL to disable gso gro tso on $START_INTERFACE
ethtool -K $START_INTERFACE  tso off gso off gro off
fi

if [ ! -z "$CAPTURE_FILE" ]; then
echo "PCAP Capture file set to  $CAPTURE_FILE"
fi


# Fix the webserver port 
if [ ! -z "$WEBSERVER_PORT" ]; then
echo NGINX Web server port changed to : $WEBSERVER_PORT
sed -i -E "s/listen.*;/listen $WEBSERVER_PORT/" /usr/local/share/webtrisul/build/nginx.conf
fi

if [ ! -z "$WEBSOCKETS_PORT" ]; then
echo THIN Web sockets changed to $WEBSOCKETS_PORT
sed -i -E "s/3003/$WEBSOCKETS_PORT/" /usr/local/share/webtrisul/build/thin-nginxd
sed -i -E "s/3003/$WEBSOCKETS_PORT/" /usr/local/share/webtrisul/build/thin-nginxssld
fi

echo Stopping Webtrisul
/usr/local/share/webtrisul/build/webtrisuld stop

echo Stopping Hub domain
/usr/local/bin/trisulctl_hub stop context all   
/usr/local/bin/trisulctl_hub stop domain

echo Stopping Probe domain
/usr/local/bin/trisulctl_probe stop  domain

echo Clean up old pid files - within Docker PIDs repeat 
rm -f /usr/local/var/lib/trisul-probe/domain0/probe0/run/trisul_cp_probe.pid
rm -f /usr/local/var/lib/trisul-probe/domain0/probe0/context0/run/trisul-probe.pid
rm -f /usr/local/var/lib/trisul-hub/domain0/hub0/context0/run/flushd.pid
rm -f /usr/local/var/lib/trisul-hub/domain0/hub0/context0/run/trp.pid
rm -f /usr/local/var/lib/trisul-hub/domain0/hub0/run/trisul_cp_hub.pid
rm -f /usr/local/var/lib/trisul-hub/domain0/run/trisul_cp_config.pid
rm -f /usr/local/var/lib/trisul-hub/domain0/run/trisul_cp_router.pid

echo Mapping persistent directories DATA 
if test -e /trisulroot/var; then 
mv /usr/local/var /usr/local/var_docker
ln -sf /trisulroot/var /usr/local/var
else
cp -r /usr/local/var /trisulroot/var
mv /usr/local/var /usr/local/var_docker
ln -sf /trisulroot/var /usr/local/var
fi  


echo Mapping persistent directories DATA CONFIG 
if test -e /trisulroot/etc; then 
mv /usr/local/etc /usr/local/etc_docker
ln -sf /trisulroot/etc /usr/local/etc
else
cp -r /usr/local/etc /trisulroot/etc
mv /usr/local/etc /usr/local/etc_docker
ln -sf /trisulroot/etc /usr/local/etc
fi  

chown trisul.trisul /trisulroot/var/lib/trisul* -R 
chown trisul.trisul /trisulroot/etc/trisul* -R 
chown trisul.trisul /trisulroot/var/log/trisul* -R 
chown trisul.trisul /trisulroot/var/run/trisul -R 

echo Starting Hub domain
/usr/local/bin/trisulctl_hub start domain
/usr/local/bin/trisulctl_hub start context default  

echo start Probe domain
/usr/local/bin/trisulctl_probe start  domain

echo Starting Webtrisul
/usr/local/share/webtrisul/build/webtrisuld start 

# if interface supplied use it and start 
if [ ! -z "$START_INTERFACE" ]; then
	echo "Automatically starting default context "
	/usr/local/bin/trisulctl_probe stop context default@probe0

	echo "Automatically setting interface to supplied command line $START_INTERFACE" 
	/usr/local/bin/trisulctl_probe set config default interface=$START_INTERFACE 

	echo "Automatically starting default context "
	/usr/local/bin/trisulctl_probe start context default 
fi

echo Sleeping
sleep infinity 
