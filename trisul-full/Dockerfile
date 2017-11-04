# Ubuntu 16.04
FROM ubuntu:16.04

# Meta
LABEL 	org.trisul.project="trisul" \
        maintainer="github.com/trisulnsm" \
		project="Trisul Network Analytics Full" \
		description="Docker image Trisul Probe, Hub, and Web in single container" \
		version="6" 


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
	&& rm -rf /var/lib/apt/lists/*

# Packages
COPY *.deb /root/
RUN dpkg -i /root/trisul-probe_6.0.*-xenial_amd64.deb /root/trisul-hub_6.0.*-xenial_amd64.deb       /root/trisul-badfellas_6.0.*-xenial_amd64.deb  /root/trisul-geo_6.0.*-xenial_amd64.deb	   /root/trisul-urlfilter_6.0.*-xenial_amd64.deb /root/webtrisul_6.0.*-xenial_amd64.deb 

RUN echo 'PS1="DOCKER:\h:\W \u$ "' > /root/.bashrc 

# Entry point script 
COPY entrypoint.sh /root 
ENTRYPOINT   ["/root/entrypoint.sh"]
CMD [""] 


VOLUME /trisulroot
EXPOSE 3000
EXPOSE 3003

