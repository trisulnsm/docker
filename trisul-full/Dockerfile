# Ubuntu 16.04
FROM ubuntu:16.04

# Usual update
RUN apt-get update  &&  apt-get install -y  \
		apt-utils \
		iputils-ping \
		net-tools \
		libssl1.0.0 \
		lsb-release \
		anacron \
		tzdata \
		libpcap0.8 \
		binutils  \
	&& rm -rf /var/lib/apt/lists/*

# Packages
COPY *.deb /root/
RUN dpkg -i /root/trisul-probe_6.0.2848-xenial_amd64.deb /root/trisul-hub_6.0.2791-xenial_amd64.deb       /root/trisul-badfellas_6.0.691-xenial_amd64.deb  /root/trisul-geo_6.0.674-xenial_amd64.deb	   /root/trisul-urlfilter_6.0.673-xenial_amd64.deb /root/webtrisul_6.0.2069-xenial_amd64.deb 

# Entry point script 
COPY entrypoint.sh /root 
CMD   ["/root/entrypoint.sh"]


VOLUME /trisulroot
EXPOSE 3000
EXPOSE 3003


