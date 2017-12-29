#!/bin/bash
# (c) Trisul Network Analytics 
# Docker entry point for Trisul-Full



# Command line options
START_INTERFACE=
WEBSERVER_PORT=
WEBSOCKETS_PORT=
CAPTURE_FILE=
NO_SURICATA=
while true; do
  case "$1" in
	-i | --interface )  START_INTERFACE="$2"; shift 2 ;;
	-f | --pcap )       CAPTURE_FILE="/trisulroot/$2"; shift 2 ;;
    --webserver-port )  WEBSERVER_PORT="$2"; shift 2 ;;
    --websockets-port ) WEBSOCKETS_PORT="$2"; shift 2 ;;
	--no-ids )          NO_SURICATA="1"; shift 1;; 
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

	if [ ! -e  $CAPTURE_FILE ]; then 
		echo "Cannot find PCAP file $CAPTURE_FILE. You need to put in on the root directory"
	fi 
fi

if [ ! -z "$NO_SURICATA" ]; then
	echo "NOIDS --no-ids : We wont be running IDS over this PCAP file $CAPTURE_FILE"
fi


# Fix the webserver port 
if [ ! -z "$WEBSERVER_PORT" ]; then
	echo NGINX Web server port changed to : $WEBSERVER_PORT
	sed -i -E "s/listen.*;/listen $WEBSERVER_PORT;/" /usr/local/share/webtrisul/build/nginx.conf
	/usr/local/bin/shell  /usr/local/var/lib/trisul-config/domain0/webtrisul/WEBTRISULDB.SQDB 'update webtrisul_options set value="4000" where name = "webtrisul_port";'
fi

if [ ! -z "$WEBSOCKETS_PORT" ]; then
	echo THIN Web sockets changed to $WEBSOCKETS_PORT
	sed -i -E "s/3003/$WEBSOCKETS_PORT/" /usr/local/share/webtrisul/build/thin-nginxd
	sed -i -E "s/3003/$WEBSOCKETS_PORT/" /usr/local/share/webtrisul/build/thin-nginxssld
	sed -i -E "s/3003/$WEBSOCKETS_PORT/" /usr/local/share/webtrisul/config/initializers/oem_settings.rb 
fi

echo Stopping Webtrisul
/usr/local/share/webtrisul/build/webtrisuld stop

echo Removing the linkdev.db so incoming Image can  do migration of old DB on startup
rm -f /usr/local/share/webtrisul/db/linkdev.db 

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


echo Mapping persistent directories DATA CONFIG  for TrisulNSM 
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


echo Mapping persistent directories for Suricata and Oinkmaster 
if test -e /trisulroot/suricata; then 
	mv /etc/suricata/ /etc/suricata_docker
	ln -sf /trisulroot/suricata/etc /etc/suricata

	mv /etc/oinkmaster.conf /etc/oinkmaster.conf_docker
	ln -sf /trisulroot/oinkmaster.conf /etc/oinkmaster.conf 
else
    mkdir -p /trisulroot/suricata/etc 

	echo ET Rules packaged ,, oink will update
	tar xf /root/emerging.rules.tar.gz -C /etc/suricata 

	echo Replaing OINKMASTER with custom ET Updates 
	cp /root/oinkmaster.conf  /etc/oinkmaster.conf 

	echo Replaing custom YAML - we disable Suricata internal events 
	cp -f /root/suricata-debian.yaml /etc/suricata/suricata-debian.yaml

	echo Copy  over initial config to persistent area
	cp -r /etc/suricata/*  /trisulroot/suricata/etc
	mv /etc/suricata /etc/suricata_docker 
	ln -sf /trisulroot/suricata/etc /etc/suricata



	cp -r /etc/oinkmaster.conf /trisulroot/suricata/oinkmaster.conf 
	mv /etc/oinkmaster.conf /etc/oinkmaster.conf_docker
	ln -sf /trisulroot/oinkmaster.conf /etc/oinkmaster.conf 
fi  

echo Adding suricata_eve_unixsocket.lua APP to probe 
cp /root/suricata_eve_unixsocket.lua /usr/local/lib/trisul-probe/plugins/lua/ 

echo Adding OINK to CRONTAB
crontab /root/oink.cron 

chown trisul.trisul /trisulroot/var/lib/trisul* -R 
chown trisul.trisul /trisulroot/etc/trisul* -R 
chown trisul.trisul /trisulroot/var/log/trisul* -R 
chown trisul.trisul /trisulroot/var/run/trisul -R 



echo Starting Hub domain
/usr/local/bin/trisulctl_hub start domain

echo start Probe domain
/usr/local/bin/trisulctl_probe start  domain


echo capture context 
/usr/local/bin/trisulctl_hub start context default@hub0  


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

if [ ! -z "$START_INTERFACE" ]; then
	if [ ! -z "$NO_SURICATA" ]; then
		echo We wont be running suricata on the interface $NO_SURICATA : user specified --no-ids option 
	else 
		echo Starting Suricata  on line  $START_INTERFACE
		/usr/bin/suricata --user trisul -l /usr/local/var/lib/trisul-probe/domain0/probe0/context0/run -c /etc/suricata/suricata-debian.yaml -i $START_INTERFACE  -D
	fi
fi 



if [ ! -z "$CAPTURE_FILE" ]; then
	if [ ! -z "$NO_SURICATA" ]; then
		echo "Importing from capture file $CAPTURE_FILE into new context. No IDS  "
		/root/trisul_suricata.sh  $CAPTURE_FILE no_ids 
	else
		echo "Importing from capture file $CAPTURE_FILE into new context. Will also index with Suricata "
		/root/trisul_suricata.sh  $CAPTURE_FILE suricata 
	fi
fi 


echo Sleeping
sleep infinity 
