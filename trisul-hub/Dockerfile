# Ubuntu 18.04 - build on LTS 18 
FROM ubuntu:18.04

# Meta
LABEL 	org.trisul.project="trisul" \
        maintainer="github.com/trisulnsm" \
		project="Trisul Network Analytics Hub" \
		description="Trisul Hub contains the backend database and query components" \
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
		binutils  \
		nano  \
		vim \
        sudo 

# Packages
COPY *.deb /root/
RUN dpkg -i /root/trisul-hub_6.5.*-bionic_amd64.deb  /root/webtrisul_6.5.*-bionic.deb

# Layer moves initial var and etc out of the way 
RUN mv /usr/local/var /usr/local/var_init ; \
    mv /usr/local/etc /usr/local/etc_init; \
    rm /etc/localtime 

RUN echo 'PS1="DOCKER:\h:\u \W$ "' > /root/.bashrc 

# Entry point script 
COPY entrypoint.sh /root 
ENTRYPOINT   ["/root/entrypoint.sh"]
CMD [""] 

VOLUME /trisulroot
EXPOSE 12001  12002

