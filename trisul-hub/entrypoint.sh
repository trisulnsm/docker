#!/bin/bash
# (c) Trisul Network Analytics 
# Docker entry point for Trisul-Hub 


# Command line options
INSTALL_HUB=
DOMAIN_ID=
HUB_ID="$HUB_ID"
USECONTEXTNAME="default"
USECONTEXTDIR="context0"
while true; do
  case "$1" in
    --timezone) 		    	TIMEZONE="$2"; shift 2 ;;
	--hub-id )                  HUB_ID="$2";shift 2;; 
	--install-hub )             INSTALL_HUB="1"; DOMAIN_ID="$2";HUB_ID="$3";shift 3;; 
	--context-name)             USECONTEXTNAME="$2"; USECONTEXTDIR="context_$USECONTEXTNAME";shift 2;;  
        -- ) shift; break ;;
        * ) if [ ! -z "$1" ]; then 
		echo "Unknown option [$1]"; 
	    fi
	    break ;;
  esac
done

if [ -z "$HUB_ID" ]; then
	echo ERROR - missing parameter --hub-id 
	exit 1
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

if [ ! -z "$INSTALL_HUB" ]; then
	echo  Installing hub domain=$DOMAIN_ID,  hub=$HUB_ID 
	/usr/local/bin/trisulctl_hub stop domain 
	/usr/local/bin/trisulctl_hub "set state ask_confirm=false;install remote-domain /trisulroot/$DOMAIN_ID.cert "
	/usr/local/bin/trisulctl_hub "set state ask_confirm=false;install hub /trisulroot/$HUB_ID.cert "
	/usr/local/bin/trisulctl_hub "set state ask_confirm=false;install context  $HUB_ID  $USECONTEXTNAME " 
	/usr/local/bin/trisulctl_hub "set state ask_confirm=false;uninstall hub domain0 hub0  "
	/usr/local/bin/trisulctl_hub restart domain 

	echo  Successfully installed a new hub Certificate 
	echo  Showing hub connection 

	/usr/local/bin/trisulctl_hub list hubs 

	echo  Successfully installed a new hub $HUB_ID 
	echo  You can now stop this docker image and start using it as a Trisul-Hub 
	echo  Exiting docker, you can now start the hub . 
	sleep infinity 

	exit 1
fi

echo Clean up old pid files - within Docker PIDs repeat  easily 
rm -f /usr/local/var/lib/trisul-hub/domain0/$HUB_ID/run/trisul_cp_hub.pid
rm -f /usr/local/var/lib/trisul-hub/domain0/$HUB_ID/$USECONTEXTDIR/run/trisul-hub.pid

echo Stopping Hub  domain
/usr/local/bin/trisulctl_hub stop  domain

currowner=$(stat -c '%U' /trisulroot/var/lib/trisul-hub/domain0/$HUB_ID/$USECONTEXTDIR)
if [ $currowner != 'trisul' ]; then 
	echo "Changing  ownership of databases , current owner: $currowner"
	chown trisul.trisul /trisulroot/var/lib/trisul* -R 
fi 
chown trisul.trisul /trisulroot/etc/trisul* -R 
chown trisul.trisul /trisulroot/var/log/trisul* -R 
chown trisul.trisul /trisulroot/var/run/trisul -R 


currowner=$(stat -c '%U' /trisulroot/var/lib/trisul-hub/domain0/$HUB_ID/$USECONTEXTDIR)
if [ $currowner != 'trisul' ]; then 
	echo "Changing  ownership of databases , current owner: $currowner"
	chown trisul.trisul /trisulroot/var/lib/trisul* -R 
fi

chown trisul.trisul /trisulroot/etc/trisul* -R 
chown trisul.trisul /trisulroot/var/log/trisul* -R 
chown trisul.trisul /trisulroot/var/run/trisul -R 


echo start Hub  domain
/usr/local/bin/trisulctl_hub start  domain


# system services 
/usr/sbin/cron -n 


echo Started TrisulNSM docker image. Sleeping. 
sleep infinity 
