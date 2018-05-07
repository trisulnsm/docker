# Ubuntu 16.04
FROM ubuntu:16.04

# Meta
LABEL 	org.trisul.project="trisul" \
        maintainer="github.com/trisulnsm" \
		project="Trisul Network Analytics Full" \
		description="Trisul Probe, Hub, and Web in a single container" \
		version="6.5" 


# Usual update
RUN apt-get update  &&  apt-get install -y  \
		apt-utils \
		iputils-ping \
		net-tools \
		libssl1.0.0 \
		lsb-release \
		anacron \
		tzdata \
		ethtool \
		libpcap0.8 \
		binutils  \
		nano  \
		librsvg2-bin \
		libleveldb1v5 \
		snmp \
		bsdmainutils \
		suricata  

# Tshark alone in non-interactive
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tshark \
	&& rm -rf /var/lib/apt/lists/*
    

# Packages
COPY *.deb /root/
RUN dpkg -i /root/trisul-probe_6.5.*-xenial_amd64.deb /root/trisul-hub_6.5.*-xenial_amd64.deb       /root/trisul-badfellas_6.5.*-xenial_amd64.deb  /root/trisul-geo_6.5.*-xenial_amd64.deb	   /root/trisul-urlfilter_6.5.*-xenial_amd64.deb /root/webtrisul_6.5.*-xenial_amd64.deb 

# This layer overlays SURICATA config items 
COPY oink.cron \
     oinkmaster.conf \
	 suricata-debian.yaml \
	 suricata_eve_unixsocket.lua \
	 emerging.rules.tar.gz \
	 trisul_suricata.sh \
	 /root/ 

# Layer moves initial var and etc out of the way 
RUN mv /usr/local/var /usr/local/var_init ; \
    mv /usr/local/etc /usr/local/etc_init; \
	mv /etc/suricata /etc/suricata_init; \
	mv /usr/local/share/trisul-probe/plugins /usr/local/share/trisul-probe/shareplugins_init; \
	mv /etc/oinkmaster.conf /etc/oinkmaster.conf_init ; \
	mv /usr/local/share/webtrisul/public/plugins  /usr/local/share/webtrisul/public/plugins_init; \
	rm  /etc/localtime 

RUN echo 'PS1="DOCKER:\h:\u \W$ "' > /root/.bashrc 

# Entry point script 
COPY entrypoint.sh /root 
ENTRYPOINT   ["/root/entrypoint.sh"]
CMD [""] 


VOLUME /trisulroot
EXPOSE 3000  3003

