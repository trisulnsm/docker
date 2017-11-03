#!/bin/bash
# (c) Trisul Network Analytics 
# Docker entry point for Trisul-Full

echo Stopping Webtrisul
/usr/local/share/webtrisul/build/webtrisuld stop

echo Stopping Hub domain
/usr/local/bin/trisulctl_hub stop context default  
/usr/local/bin/trisulctl_hub stop domain

echo Stopping Probe domain
/usr/local/bin/trisulctl_probe stop  domain

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

echo Sleeping
sleep infinity 
