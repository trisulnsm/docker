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
NO_PCAP_STORE=
INIT_DATABASE=
while true; do
  case "$1" in
    -i | --interface )          START_INTERFACE="$2"; shift 2 ;;
    -f | --pcap )               CAPTURE_FILE="/trisulroot/$2"; shift 2 ;;
    --webserver-port )          WEBSERVER_PORT="$2"; shift 2 ;;
    --websockets-port )         WEBSOCKETS_PORT="$2"; shift 2 ;;
    --timezone)                 TIMEZONE="$2"; shift 2 ;;
    --no-ids )                  NO_SURICATA="1"; shift 1;; 
    --fine-resolution)          FINE_RESOLUTION="fine"; shift 1;; 
    --context-name)             USECONTEXTNAME="$2"; shift 2;;  
    --enable-file-extraction)   ENABLE_FILE_EXTRACTION="1"; shift 1;; 
    --netflow-mode)             NETFLOW_MODE="1"; shift 1;; 
    --no-pcap-store)            NO_PCAP_STORE="1"; shift 1;; 
    --init-db)                  INIT_DATABASE="1"; shift 1;; 
    -- ) shift; break ;;
    * ) if [ ! -z "$1" ]; then 
            echo "Unknown option [$1]"; 
        fi
        break ;;
  esac
done

if [ ! -z "$USECONTEXTNAME" ]; then
    echo -en "\e[32m"
    echo  Option [--context-name]      Context name set to $USECONTEXTNAME
    echo -en "\e[0m"
fi

if [ ! -z "$FINE_RESOLUTION" ]; then
    echo -en "\e[32m"
    echo  Option [--fine-resolution]   Fine metrics resolution  $FINE_RESOLUTION
    echo -en "\e[0m"
fi

if [ ! -z "$ENABLE_FILE_EXTRACTION" ]; then
    echo -en "\e[32m"
    echo  Option [--enable-file-extraction] Enable file extraction , create ramfs $ENABLE_FILE_EXTRACTION
    echo -en "\e[0m"
fi

if [ ! -z "$NETFLOW_MODE" ]; then
    echo -en "\e[32m"
    echo  Option [--netflow-mode]      Netflow mode $NETFLOW_MODE
    echo -en "\e[0m"
fi

if [ ! -z "$START_INTERFACE" ]; then
    echo -en "\e[32m"
    echo  Option [--interface]         Start interface set $START_INTERFACE
    echo -en "\e[0m"

    echo  "Using ETHTOOL disabling gso gro tso on $START_INTERFACE"
    ethtool -K $START_INTERFACE  tso off gso off gro off
fi


# check capture file 
if [ ! -z "$CAPTURE_FILE" ]; then
    echo -en "\e[32m"
    echo  Option [--pcap]              PCAP Capture file set to  $CAPTURE_FILE
    echo -en "\e[0m"

    #  check if pcap input file exists 
    if [ ! -e  $CAPTURE_FILE ]; then 
	echo -en "\e[31m"
        echo "Cannot find PCAP file $CAPTURE_FILE. "
        echo "You need to place the pcap file inside the shared docker volume as specified in -v "
        echo -en "\e[0m"
	exit 1
    fi 
fi

# check capture file readability 
if [ ! -z "$CAPTURE_FILE" ]; then

    #  check if pcap input file is readable by trisul user 
    cp /root/isfilereadable.sh /tmp
    if ! sudo -u trisul /tmp/isfilereadable.sh $CAPTURE_FILE ; then 
	echo -en "\e[31m"
        echo "Cannot READ the pcap file/directory  $CAPTURE_FILE. user=trisul"
        echo "Ensure the pcap file/directory is readable by user trisul, use chmod +rR $CAPTURE_FILE" 
        echo -en "\e[0m"
	exit 2
    fi 
fi


if [ ! -z "$NO_SURICATA" ]; then
    echo -en "\e[32m"
    echo  Option [--no-ids]            We wont be running IDS over this PCAP file $CAPTURE_FILE
    echo -en "\e[0m"
fi

if [ ! -z "$NO_PCAP_STORE" ]; then
    echo -en "\e[32m"
    echo  Option [--no-pcap-store]     Disabling packet storage in ring 
    echo -en "\e[0m"
fi

# Timezone will be UTC unless explicitly overridden 
if [ ! -z "$TIMEZONE" ]; then
    echo -en "\e[32m"
    echo  Option [--timezone]          Setting timezone to $TIMEZONE
    echo -en "\e[0m"

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
    echo -en "\e[32m"
    echo  Option [--webserver-port]    Web server port changed to : $WEBSERVER_PORT
    echo -en "\e[0m"
    sed -i -E "s/listen.*;/listen $WEBSERVER_PORT;/" /usr/local/share/webtrisul/build/nginx.conf
    /usr/local/bin/shell  /usr/local/var_init/lib/trisul-config/domain0/webtrisul/WEBTRISULDB.SQDB "update webtrisul_options set value='$WEBSERVER_PORT' where name = 'webtrisul_port';"
fi

if [ ! -z "$WEBSOCKETS_PORT" ]; then
    echo -en "\e[32m"
    echo  Option [--websockets-port]   Web sockets changed to $WEBSOCKETS_PORT
    echo -en "\e[0m"

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

# if user does not want to store packets 
if [ ! -z "$NO_PCAP_STORE" ]; then
echo "Disabling Ring"
/usr/local/bin/trisulctl_hub "set config default@probe0  Ring>Enabled=FALSE"
fi 


# check for init-db if : /usr/local/var/lib/trisul-hub/domain0/hub0/context0/meters
# only if empty database 
if [ ! -z "$INIT_DATABASE" ]; then

	if [ -d "/usr/local/var/lib/trisul-hub/domain0/hub0/context0/meters/oper/0" ]; then 
		echo -en "\e[31m"
		echo "-----------------------------------------------------------------"
		echo "ERROR:  --init-db  can only be done on a first run"
		echo "ERROR:  There seems to be already some data in the volume"
		echo "ERROR:  If you want to clean up existing data "
		echo "ERROR:  Run without --init-db m then login to the instance and do "
		echo "ERROR:  trisulctl_hub reset context default"
		echo "-----------------------------------------------------------------"
		echo -en "\e[0m"
		exit 
	else
		/usr/local/bin/trisulctl_hub "start context default mode=initdb"
	fi
fi


# all set to start UI 
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
        /root/trisul_suricata.sh  $CAPTURE_FILE no_ids  $FINE_RESOLUTION $USECONTEXTNAME $ENABLE_FILE_EXTRACTION
    else
        echo "Importing from capture file $CAPTURE_FILE into new context. Will also index with Suricata "
        /root/trisul_suricata.sh  $CAPTURE_FILE suricata  $FINE_RESOLUTION $USECONTEXTNAME $ENABLE_FILE_EXTRACTION
    fi
fi 

# system services 
/usr/sbin/cron -n 


echo Started TrisulNSM docker image. Sleeping. 
sleep infinity 
