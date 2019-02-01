#!/bin/bash
# (c) Trisul Network Analytics 
# Docker entry point for Trisul-Full



# Command line options
START_INTERFACE=
WEBSERVER_PORT=
WEBSOCKETS_PORT=
CAPTURE_FILE=
NO_SURICATA=
ENABLE_FILE_EXTRACTION=
FINE_RESOLUTION="coarse"
USECONTEXTNAME="assign"
NETFLOW_MODE=
while true; do
  case "$1" in
	-i | --interface )  		START_INTERFACE="$2"; shift 2 ;;
	-f | --pcap )       		CAPTURE_FILE="/trisulroot/$2"; shift 2 ;;
    --webserver-port )  		WEBSERVER_PORT="$2"; shift 2 ;;
    --websockets-port ) 		WEBSOCKETS_PORT="$2"; shift 2 ;;
    --timezone) 				TIMEZONE="$2"; shift 2 ;;
	--no-ids )          		NO_SURICATA="1"; shift 1;; 
	--fine-resolution)  		FINE_RESOLUTION="fine"; shift 1;; 
	--context-name)             USECONTEXTNAME="$2"; shift 2;;  
	--enable-file-extraction)   ENABLE_FILE_EXTRACTION="1"; shift 1;; 
	--netflow-mode)   			NETFLOW_MODE="1"; shift 1;; 
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
		echo "Cannot find PCAP file $CAPTURE_FILE. "
		echo "You need to place the pcap file inside the shared docker volume as specified in -v "
	fi 
fi


if [ ! -z "$NO_SURICATA" ]; then
	echo "NOIDS --no-ids : We wont be running IDS over this PCAP file $CAPTURE_FILE"
fi

# Timezone will be UTC unless explicitly overridden 
if [ ! -z "$TIMEZONE" ]; then
	echo "TIMEZONE -- setting timezone to $TIMEZONE"
	if [ ! -e  /usr/share/zoneinfo/$TIMEZONE ]; then 
		echo "Invalid timezone specified $TIMEZONE,  defaulting to UTC" 
		echo "TIMEZONE -- defaulting  to Etc/UTC" 
		ln -sf /usr/share/zoneinfo/Etc/UTC   /etc/localtime 
	else
		ln -sf /usr/share/zoneinfo/$TIMEZONE  /etc/localtime 
	fi 
else
	echo "TIMEZONE -- setting to Etc/UTC" 
	ln -sf /usr/share/zoneinfo/Etc/UTC   /etc/localtime 
fi

# Fix the webserver port 
if [ ! -z "$WEBSERVER_PORT" ]; then
	echo NGINX Web server port changed to : $WEBSERVER_PORT
	sed -i -E "s/listen.*;/listen $WEBSERVER_PORT;/" /usr/local/share/webtrisul/build/nginx.conf
	/usr/local/bin/shell  /usr/local/var_init/lib/trisul-config/domain0/webtrisul/WEBTRISULDB.SQDB "update webtrisul_options set value='$WEBSERVER_PORT' where name = 'webtrisul_port';"
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


echo Mapping persistent directories DATA 
if test -e /trisulroot/var; then 
	echo == Found Existing Data and Config at /trisulroot/var == Linking to /usr/local/var 
	ln -sf /trisulroot/var /usr/local/var
else
	echo ++ Not Found /trisulroot/var XX Initial run copy and link 
	echo ++ Copying /usr/local/var_init  to /trisulroot/var 
	cp -r /usr/local/var_init  /trisulroot/var
	echo ++ Linking trisulroot/var 
	ln -sf /trisulroot/var /usr/local/var
fi  

echo Mapping webtrisul Plugins  
if test -e /trisulroot/webtrisul_public_plugins_init; then 
	echo == Found Existing Data and Config. Linking webtrisul public plugins 
	ln -sf /trisulroot/webtrisul_public_plugins_init  /usr/local/share/webtrisul/public/plugins
else
	echo ++ Initialize /trisulroot/var ++ Initial run copy and link 
	echo ++ Copying /usr/local/share/webtrisul/public/plugins_init to /trisulroot/var/webtrisul_public_plugins
	cp -r /usr/local/share/webtrisul/public/plugins_init  /trisulroot/webtrisul_public_plugins_init
	chown -R trisul.trisul /trisulroot/webtrisul_public_plugins_init  
	echo ++ Linking webtrisul_public_plugins
	ln -sf /trisulroot/webtrisul_public_plugins_init  /usr/local/share/webtrisul/public/plugins
	echo ++ Installing default Trisul APP dashboards 
	tar xf /root/dash.tar.gz -C  /usr/local/share/webtrisul/public/plugins 
	echo ++ Changing perms of public plugins 
	chown trisul.trisul /trisulroot/webtrisul_public_plugins_init -R
	echo ++ Installing default Trisul LUA analytics  
	tar xf /root/luaplugs.tar.gz -C  /usr/local/var/lib/trisul-config/domain0/context0/profile0/lua
	echo ++ Installing default WEBTRISULDB

	cp -f  /root/WEBTRISUL_DEFAULT.SQDB  /usr/local/var/lib/trisul-config/domain0/webtrisul/WEBTRISULDB.SQDB  
fi  


echo Mapping persistent directories DATA CONFIG  for TrisulNSM 
if test -e /trisulroot/etc; then 
	echo ++ Linking persistent Etc to image 
	ln -sf /trisulroot/etc /usr/local/etc
else
	echo ZZ Creating and linking persistent ETC for trisul components 
	cp -r /usr/local/etc_init  /trisulroot/etc
	ln -sf /trisulroot/etc /usr/local/etc
fi  

echo Mapping share/plugins with Badfellas INTEL for TrisulNSM
if test -e /trisulroot/shareplugins_init; then 
	echo ^^ Linking persistent SharePlugins 
	ln -sf /trisulroot/shareplugins_init /usr/local/share/trisul-probe/plugins
else
	echo vv Creating and linking persistent Share plugins 
	cp -r /usr/local/share/trisul-probe/shareplugins_init  /trisulroot/shareplugins_init
	ln -sf /trisulroot/shareplugins_init /usr/local/share/trisul-probe/plugins
fi  


echo Clean up old pid files - within Docker PIDs repeat  easily 
rm -f /usr/local/var/lib/trisul-probe/domain0/probe0/run/trisul_cp_probe.pid
rm -f /usr/local/var/lib/trisul-probe/domain0/probe0/context0/run/trisul-probe.pid
rm -f /usr/local/var/lib/trisul-hub/domain0/hub0/context0/run/flushd.pid
rm -f /usr/local/var/lib/trisul-hub/domain0/hub0/context0/run/trp.pid
rm -f /usr/local/var/lib/trisul-hub/domain0/hub0/run/trisul_cp_hub.pid
rm -f /usr/local/var/lib/trisul-hub/domain0/run/trisul_cp_config.pid
rm -f /usr/local/var/lib/trisul-hub/domain0/run/trisul_cp_router.pid

echo Stopping Hub domain
/usr/local/bin/trisulctl_hub stop context all   
/usr/local/bin/trisulctl_hub stop domain

echo Stopping Probe domain
/usr/local/bin/trisulctl_probe stop  domain

currowner=$(stat -c '%U' /trisulroot/var/lib/trisul-probe/domain0/probe0/context0)
if [ $currowner != 'trisul' ]; then 
	echo "Changing  ownership of databases , current owner: $currowner"
	chown trisul.trisul /trisulroot/var/lib/trisul* -R 
fi 
chown trisul.trisul /trisulroot/etc/trisul* -R 
chown trisul.trisul /trisulroot/var/log/trisul* -R 
chown trisul.trisul /trisulroot/var/run/trisul -R 


echo Mapping persistent directories for Suricata and Oinkmaster 
if test -e /trisulroot/suricata; then 
	echo ++ Reusing : linking persistent suricata and oinkmaster into image 
	ln -sf /trisulroot/suricata/etc /etc/suricata

	ln -sf /trisulroot/oinkmaster.conf /etc/oinkmaster.conf 
else
	echo EE First time run  Initializing Suricata config 
    mkdir -p /trisulroot/suricata/etc 

	echo ET Rules packaged ,, oink will update
	tar xf /root/emerging.rules.tar.gz -C /etc/suricata_init

	echo Replaing OINKMASTER with custom ET Updates 
	cp /root/oinkmaster.conf  /etc/oinkmaster.conf 

	echo Replacing custom YAML - we disable Suricata internal events 
	cp -f /root/suricata-debian.yaml /etc/suricata_init/suricata-debian.yaml

	echo Copy  over initial suricata config to persistent area
	cp -r /etc/suricata_init/*  /trisulroot/suricata/etc
	ln -sf /trisulroot/suricata/etc /etc/suricata


	echo Copy  over initial oinkmaster to persistent area 
	cp -r /etc/oinkmaster.conf_init  /trisulroot/suricata/oinkmaster.conf 
	ln -sf /trisulroot/oinkmaster.conf /etc/oinkmaster.conf 
fi  

echo Adding OINK to CRONTAB
crontab /root/oink.cron 

currowner=$(stat -c '%U' /trisulroot/var/lib/trisul-probe/domain0/probe0/context0)
if [ $currowner != 'trisul' ]; then 
	echo "Changing  ownership of databases , current owner: $currowner"
	chown trisul.trisul /trisulroot/var/lib/trisul* -R 
fi

chown trisul.trisul /trisulroot/etc/trisul* -R 
chown trisul.trisul /trisulroot/var/log/trisul* -R 
chown trisul.trisul /trisulroot/var/run/trisul -R 



echo Starting Hub domain
/usr/local/bin/trisulctl_hub start domain

echo start Probe domain
/usr/local/bin/trisulctl_probe start  domain


echo capture context 
/usr/local/bin/trisulctl_hub start context default@hub0  

# if user wants ramfs (for file extraction) 
if [ ! -z "$ENABLE_FILE_EXTRACTION" ]; then
echo "Creating TMPFS partition with size 20MB" 
/usr/local/bin/trisulctl_hub "set config default@probe0  Reassembly>FileExtraction>Enabled=true"
RAMFSDIR=/usr/local/var/lib/trisul-probe/domain0/probe0/context0/run/ramfs
mkdir -p $RAMFSDIR
mount -t tmpfs -o size=20m  tmpfs $RAMFSDIR
fi 

# if running in NETFLOW mode  option --netflow-mode
if [ ! -z "$NETFLOW_MODE" ]; then
echo "Switching to Netflow mode NETFLOW_TAP" 
/usr/local/bin/trisulctl_hub "set config default@probe0  App>TrisulMode=NETFLOW_TAP"
fi 

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
		/root/trisul_suricata.sh  $CAPTURE_FILE no_ids  $FINE_RESOLUTION $USECONTEXTNAME
	else
		echo "Importing from capture file $CAPTURE_FILE into new context. Will also index with Suricata "
		/root/trisul_suricata.sh  $CAPTURE_FILE suricata  $FINE_RESOLUTION $USECONTEXTNAME
	fi
fi 

# system services 
/usr/sbin/cron -n 


echo Started TrisulNSM docker image. Sleeping. 
sleep infinity 
