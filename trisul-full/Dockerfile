# Ubuntu 18.04
FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

# Meta
LABEL 	org.trisul.project="trisul" \
        maintainer="github.com/trisulnsm" \
		project="Trisul Network Analytics Full" \
		description="Trisul Probe, Hub, and Web in a single container" \
		version="6.5" 


# Usual update
RUN apt-get update  &&  apt-get install -y  \
		software-properties-common \
		apt-utils \
		iputils-ping \
		net-tools \
		libssl1.0.0 \
		lsb-release \
		systemd \
		anacron \
		tzdata \
		ethtool \
		libpcap0.8 \
		binutils  \
		nano  \
		vim \
		librsvg2-bin \
		libleveldb1v5 \
		snmp \
		bsdmainutils \
		sudo 


RUN add-apt-repository ppa:oisf/suricata-stable  && apt update && apt install -y suricata

# Tshark alone in non-interactive
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tshark \
	&& rm -rf /var/lib/apt/lists/*
    

# Packages
COPY *.deb /root/
RUN dpkg -i /root/trisul-probe_6.5.*-bionic_amd64.deb /root/trisul-hub_6.5.*-bionic_amd64.deb       /root/trisul-badfellas_6.5.*-bionic_amd64.deb  /root/trisul-geo_6.5.*-bionic_amd64.deb	   /root/trisul-urlfilter_6.5.*-bionic_amd64.deb /root/webtrisul_6.5.*-bionic_amd64.deb 

# This layer overlays SURICATA config items 
COPY oink.cron \
     oinkmaster.conf \
	 suricata-debian.yaml \
	 emerging.rules.tar.gz \
	 luaplugs.tar.gz \
	 dash.tar.gz \
	 WEBTRISUL_DEFAULT.SQDB \
	 trisul_suricata.sh \
	 isfilereadable.sh \
	 /root/ 

# Layer moves initial var and etc out of the way 
RUN mv /usr/local/var /usr/local/var_init ; \
    mv /usr/local/etc /usr/local/etc_init; \
	mv /etc/suricata /etc/suricata_init; \
	mv /usr/local/share/trisul-probe/plugins /usr/local/share/trisul-probe/shareplugins_init; \
	mv /usr/local/share/webtrisul/public/plugins  /usr/local/share/webtrisul/public/plugins_init; \
	rm  /etc/localtime 

RUN echo 'PS1="DOCKER:\h:\u \W$ "' > /root/.bashrc 

# Entry point script 
COPY entrypoint.sh /root 
ENTRYPOINT   ["/root/entrypoint.sh"]
CMD [""] 


VOLUME /trisulroot
EXPOSE 3000  3003

