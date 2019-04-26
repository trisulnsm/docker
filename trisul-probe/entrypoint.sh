#!/bin/bash
# (c) Trisul Network Analytics 
# Docker entry point for Trisul-Full



# Command line options
START_INTERFACE=
NO_SURICATA=
INSTALL_PROBE=
DOMAIN_ID=
PROBE_ID="$PROBE_ID"
ENABLE_FILE_EXTRACTION=
FINE_RESOLUTION="coarse"
USECONTEXTNAME="default"
USECONTEXTDIR="context0"
while true; do
  case "$1" in
	-i | --interface )  		START_INTERFACE="$2"; shift 2 ;;
    --timezone) 				TIMEZONE="$2"; shift 2 ;;
	--no-ids )          		NO_SURICATA="1"; shift 1;; 
	--probe-id )                PROBE_ID="$2";shift 2;; 
	--install-probe )           INSTALL_PROBE="1"; DOMAIN_ID="$2";PROBE_ID="$3";shift 3;; 
	--fine-resolution)  		FINE_RESOLUTION="fine"; shift 1;; 
	--context-name)             USECONTEXTNAME="$2"; USECONTEXTDIR="context_$USECONTEXTNAME";shift 2;;  
	--enable-file-extraction)   ENABLE_FILE_EXTRACTION="1"; shift 1;; 
    -- ) shift; break ;;
	* ) if [ ! -z "$1" ]; then 
			echo "Unknown option [$1]"; 
		fi
		break ;;
  esac
done

if [ -z "$PROBE_ID" ]; then
	echo ERROR - missing parameter --probe-id 
	exit 1
fi 

if [ ! -z "$START_INTERFACE" ]; then
	echo  INTF Start interface set $START_INTERFACE
	echo  INTF Using ETHTOOL to disable gso gro tso on $START_INTERFACE
	ethtool -K $START_INTERFACE  tso off gso off gro off
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


if [ ! -z "$INSTALL_PROBE" ]; then
	echo  Installing probe domain=$DOMAIN_ID,  probe=$PROBE_ID 
	/usr/local/bin/trisulctl_probe stop domain 
	/usr/local/bin/trisulctl_probe "set state ask_confirm=false;install domain /trisulroot/$DOMAIN_ID.cert "
	/usr/local/bin/trisulctl_probe "set state ask_confirm=false;install probe /trisulroot/$PROBE_ID.cert "
	/usr/local/bin/trisulctl_probe "set state ask_confirm=false;install context  $PROBE_ID  $USECONTEXTNAME " 
	/usr/local/bin/trisulctl_probe "set state ask_confirm=false;uninstall probe domain0 probe0  "
	/usr/local/bin/trisulctl_probe restart domain 

	echo  Successfully installed a new probe Certificate 
	echo  Showing probe connection 

	/usr/local/bin/trisulctl_probe list probes 

	echo  Successfully installed a new probe $PROBE_ID 
	echo  You can now stop this docker image and start using it as a Trisul-Probe 
	echo  Exiting docker, you can now start the probe . 
	sleep infinity 

	exit 1
fi

echo Clean up old pid files - within Docker PIDs repeat  easily 
rm -f /usr/local/var/lib/trisul-probe/domain0/$PROBE_ID/run/trisul_cp_probe.pid
rm -f /usr/local/var/lib/trisul-probe/domain0/$PROBE_ID/$USECONTEXTDIR/run/trisul-probe.pid

echo Stopping Probe domain
/usr/local/bin/trisulctl_probe stop  domain

currowner=$(stat -c '%U' /trisulroot/var/lib/trisul-probe/domain0/$PROBE_ID/$USECONTEXTDIR)
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

currowner=$(stat -c '%U' /trisulroot/var/lib/trisul-probe/domain0/$PROBE_ID/$USECONTEXTDIR)
if [ $currowner != 'trisul' ]; then 
	echo "Changing  ownership of databases , current owner: $currowner"
	chown trisul.trisul /trisulroot/var/lib/trisul* -R 
fi

chown trisul.trisul /trisulroot/etc/trisul* -R 
chown trisul.trisul /trisulroot/var/log/trisul* -R 
chown trisul.trisul /trisulroot/var/run/trisul -R 



echo start Probe domain
/usr/local/bin/trisulctl_probe start  domain

# if user wants ramfs (for file extraction) 
if [ ! -z "$ENABLE_FILE_EXTRACTION" ]; then
echo "Creating TMPFS partition with size 20MB" 
/usr/local/bin/trisulctl_probe "set config $USECONTEXTNAME@$PROBE_ID  Reassembly>FileExtraction>Enabled=true"
RAMFSDIR=/usr/local/var/lib/trisul-probe/domain0/$PROBE_ID/$USECONTEXTDIR/run/ramfs
mkdir -p $RAMFSDIR
mount -t tmpfs -o size=20m  tmpfs $RAMFSDIR
fi 


# if interface supplied use it and start 
if [ ! -z "$START_INTERFACE" ]; then
	echo "Automatically starting context "
	/usr/local/bin/trisulctl_probe stop context $USECONTEXTNAME@$PROBE_ID

	echo "Automatically setting interface to supplied command line $START_INTERFACE" 
	/usr/local/bin/trisulctl_probe set config $USECONTEXTNAME@$PROBE_ID  interface=$START_INTERFACE 

	echo "Automatically starting context "
	/usr/local/bin/trisulctl_probe start context $USECONTEXTNAME@$PROBE_ID 
fi

if [ ! -z "$START_INTERFACE" ]; then
	if [ ! -z "$NO_SURICATA" ]; then
		echo We wont be running suricata on the interface $NO_SURICATA : user specified --no-ids option 
	else 
		echo Starting Suricata  on line  $START_INTERFACE
		/usr/bin/suricata --user trisul -l /usr/local/var/lib/trisul-probe/domain0/$PROBE_ID/$USECONTEXTDIR/run -c /etc/suricata/suricata-debian.yaml -i $START_INTERFACE  -D
	fi
fi 



# system services 
/usr/sbin/cron -n 


echo Started TrisulNSM docker image. Sleeping. 
sleep infinity 
