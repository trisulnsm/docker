# Ubuntu 16.04
FROM ubuntu:16.04

# Meta
LABEL 	org.trisul.project="trisul-probe" \
        maintainer="github.com/trisulnsm" \
		project="Trisul Network Analytics Probe Node" \
		description="Trisul Probe Node single container" \
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
		vim \
		libleveldb1v5 \
		bsdmainutils \
		suricata  

# Packages
COPY *.deb /root/
RUN dpkg -i /root/trisul-probe_6.5.*-xenial_amd64.deb    /root/trisul-badfellas_6.5.*-xenial_amd64.deb  /root/trisul-geo_6.5.*-xenial_amd64.deb	   /root/trisul-urlfilter_6.5.*-xenial_amd64.deb  

# This layer overlays SURICATA config items 
COPY oink.cron \
     oinkmaster.conf \
	 suricata-debian.yaml \
	 emerging.rules.tar.gz \
	 luaplugs.tar.gz \
	 /root/ 

# Layer moves initial var and etc out of the way 
RUN mv /usr/local/var /usr/local/var_init ; \
    mv /usr/local/etc /usr/local/etc_init; \
	mv /etc/suricata /etc/suricata_init; \
	mv /usr/local/share/trisul-probe/plugins /usr/local/share/trisul-probe/shareplugins_init; \
	mv /etc/oinkmaster.conf /etc/oinkmaster.conf_init ; \
	rm  /etc/localtime 

RUN echo 'PS1="DOCKER:\h:\u \W$ "' > /root/.bashrc 

# Entry point script 
COPY entrypoint.sh /root 
ENTRYPOINT   ["/root/entrypoint.sh"]
CMD [""] 


VOLUME /trisulroot

