#!/bin/bash
# trisul_suricata.sh $PCAPFILE  $USE_IDS 
#

# create new context
# Prepare context name

pcount=0
TOTAL_STEPS=11
show_progress_text(){
  pcount=$((pcount+1))
  echo -e "\e[32m"
  echo -e "  $pcount/$TOTAL_STEPS $1"
  echo -e "\e[0m"
}
get_xml_tag_value(){
  xml_file=$1
  tag=$2
  value=$(sed -e "/<$tag>/,/<\/$tag/!d" $config_file)
  value=$(echo $value | grep -o -P "(?<=<$tag>).*(?=</$tag)")
  value=${value#" "}
  echo $value
}

PCAP_FILE=$1
USE_IDS=$2 
FINE_RESOLUTION=$3 
if ! test -e $PCAP_FILE; then
  echo "PCAP file does not exist : $PCAP_FILE"
  exit
fi
suricata_conf_file="/etc/suricata/suricata-debian.yaml"
if ! test -e $suricata_conf_file; then
  echo "Suricata config  file does not exist : $suricata_conf_file"
  exit
fi

file_name=$(basename $PCAP_FILE)
#remove the extension from the file name
file_name="${file_name%.*}"

#remove the special characters from file name
file_name=$(echo $file_name | tr -dc '[:alnum:]\n\r'| tr '[:upper:]' '[:lower:]')

wc_count=$(find /usr/local/etc/trisul-hub/domain0/hub0/context_*  -type d  | wc -l)
wc_count=$((wc_count+1)) 
if (( ${#file_name} > 10 )) ; then 
	echo "XXX Warning : Pcapfilename top big for context, truncating"
	file_name_short=${file_name: 0:5}_${file_name: -8}
	echo "Truncated to $file_name_short"
else
	file_name_short=$file_name
fi 
context_name=$file_name_short$wc_count

config_file="/usr/local/etc/trisul-probe/domain0/probe0/context_$context_name/trisulProbeConfig.xml"

show_progress_text "Stopping webtrisul to conserve memory" 
/usr/local/share/webtrisul/build/webtrisuld stop

show_progress_text "Creating new context $context_name"

/usr/local/bin/trisulctl_hub create context $context_name

pid_file=$(get_xml_tag_value $config_file "PidFile")
pid=$(cat $pid_file)

show_progress_text "Waiting to finish context initialization pid $pid"
while test -d /proc/$pid; do
 sleep 2
done

show_progress_text "Preparing Context, copying LUA Apps"
cp -r /usr/local/var/lib/trisul-config/domain0/context0/profile0/lua/* /usr/local/var/lib/trisul-config/domain0/context_$context_name/profile0/lua/ 
chown trisul.trisul -R /usr/local/var/lib/trisul-config/domain0/context_$context_name/profile0/lua/ 

show_progress_text "Adjusting resolution"
if [ ${FINE_RESOLUTION} == "fine" ]; then 
	echo "FINE Resolution requested, adjusting bucket size to 1s and topper size = 60s"
	/usr/local/bin/shell /usr/local/var/lib/trisul-config/domain0/context_$context_name/profile0/TRISULCONFIG.SQDB 'update trisul_counter_groups set BucketSizeMS=1000, TopNCommitIntervalSecs=60;' 

fi 


show_progress_text "Creating RAMFS for file extraction "
/usr/local/bin/trisulctl_probe "set config $context_name@probe0  Reassembly>FileExtraction>Enabled=true"
RAMFSDIR=/usr/local/var/lib/trisul-probe/domain0/probe0/context_$context_name/run/ramfs
mkdir $RAMFSDIR
mount -t tmpfs -o size=20m  tmpfs $RAMFSDIR



show_progress_text "Disabling active Name resolution for PCAP imports "
/usr/local/bin/trisulctl_hub "set config $context_name@probe0  DBTasks>ResolveIP>Enable=false"

show_progress_text "Running trisul in offline mode"

/usr/local/bin/trisul -nodemon /usr/local/etc/trisul-probe/domain0/probe0/context_$context_name/trisulProbeConfig.xml -mode offline -in $PCAP_FILE

echo "Unmounting RAMFS "
umount $RAMFSDIR


if  [ "$USE_IDS" == "suricata" ]; then 

	logdir=$(get_xml_tag_value $config_file "UnixSocket")
	logdir=$(dirname $logdir)

	echo Logdir for IDS overlay set to $logdir 

	show_progress_text  "Starting trisul in ids alert mode(demon)"
	/usr/local/bin/trisul -demon /usr/local/etc/trisul-probe/domain0/probe0/context_$context_name/trisulProbeConfig.xml -mode idsalertoverlay

	# wait for unix socket to open before running suricata 
	while ! test -e $logdir/suricata_eve.socket; do  
		sleep 1 
		echo "still waiting for  $logdir/suricata_eve.socket " 
	done 


	show_progress_text "Running suricata "
	user=$(get_xml_tag_value $config_file "User")
	IFS='.'; user=($user); unset IFS;
	user="${user[0]}" 

	/usr/bin/suricata -c $suricata_conf_file --user $user -l $logdir -r $PCAP_FILE

	# sending stop cmd
	/usr/local/bin/trisulctl_probe start context $context_name@probe0  tool=pipeeof 

fi 

show_progress_text "Restarting Webtrisul " 
/usr/local/share/webtrisul/build/webtrisuld start 

echo " Done"

echo 
echo ==== SUCCESSFULLY IMPORTED FROM PCAP FILE $PCAP_FILE           =====
echo ==== LOGIN to the Web Trisul interface http://ip-address:3000  =====
echo ==== Then select $context_name on the Login Screen             =====
echo 

