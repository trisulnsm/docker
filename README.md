Trisul Network Analytics : Network Security Monitoring in a Docker 
===========

A full blown Network Security and Traffic Monitoring (NSM) solution you can deploy in 1 minute.



- Full traffic monitoring - 100s of metrics from every angle
- Alert on traffic, flows, malware activity
- Complete flow monitoring, we capture and record every single flow with blazing fast retrieval
- Extract URLs, Certs, Files, .. with API to script your own
- Sophisticated PCAP storage with best retrieval times
- Also includes Suricata + ET community rules with auto refresh 
- **BEST of all**  - all parts are included and optimized. No messing around with Splunk or ELK or SIEMS. 
- Completely FREE to run to monitor a rolling window of the most recent 3 days.


Cast
---

1. [Trisul Network Analytics](https://trisul.org) for traffic analytics, flows, packet storage, resource, scripting, web interface.
2. Trisul Plugins : Geo , Badfellas (malware intel),  Urlfilter (web category) 
3. [Suricata IDS](https://suricata-ids.org/)  for IDS alerts : The output of Suricata is piped to Trisul using EVE JSON.
4. [Emerging Threats Open Rules](https://www.proofpoint.com/us)  for ruleset :  if you have an ET-PRO subscription, it is easy to plug that in.


![Trisul Screenshot](screenshot.png) 


Running.
---------

### 1. Install the free Docker if you already havent done so

Please see instructions for installing [Docker CE on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04) You can find official instructions for installing Docker on a number of platforms on the official (Install Docker site](https://docs.docker.com/engine/installation/)


### 2. Create data directory on host 

Create a directory on the host system where the data and config will be stored. This is a one time job.

````
sudo mkdir /opt/trisul6_root
````

### 3. Run TrisulNSM  on a capture interface 

Now you are ready to run TrisulNSM.  Say you want to capture traffic from the port `enp5s0`, just type 

````
sudo docker run  --net=host -v /opt/trisul6_root:/trisulroot -d trisulnsm/trisul6 --interface enp5s0 
````

Thats ! Logon on `https://localhost:3000` and you can dive right in..


---------------------

Additional tasks
================

Here are some tips for common use cases 


### Start TrisulNSM  docker without capturing

You can run the TrisulNSM docker , then log on the web interface setup the capture adapters, Netflow mode, or other options manually. To do that just skip the `--interface ` option

````
sudo docker run --net=host -v /opt/trisul6_root:/trisulroot -d trisulnsm/trisul6 
````


### Use different webserver ports 

By default TrisulNSM uses the `net:host` docker network and needs ports 3000 (for web access) and 3003 (for websockets) open. If you wish to change these ports use the `--webserver-port`  and `--websockets-port` options 

````
sudo docker run --net=host -v /opt/trisul6_root:/trisulroot -d trisulnsm/trisul6 \
  --interface enp5s0 --webserver-port 4000 --websockets-port 4003 
````


## Recommendation : assign a label to the docker instance


We recommend that you assign a name using `--name` to the running docker instance , so you can log in to it easily. To assign `trisul1a` to a new instance 

````
sudo docker run --name  trisul1a --net=host -v /opt/trisul6_root:/trisulroot -d trisulnsm/trisul6 \
  --interface enp5s0 --webserver-port 4000 --websockets-port 4003 
````

You can login to the docker using the usual -it switch 


````
sudo docker exec -it <tag> /bin/bash
````



Developers
==========

## Building your own docker images from packages

1. Go to [Trisul.org Downloads](https://trisul.org/download)  and put the latest Xenial DEBs into the same directory as this repo
2. Run

````docker
sudo docker build -t trisul-full .
````


