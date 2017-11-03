Docker : trisul-full
===========

Building.
---------

1. Download all DEBS into this directory. The DEBs need to be obtained from trisul.org Download page
2. Run

````docker
sudo docker build -t trisul-full .
````


Running.
---------

### 1. Create data directory on host 

1. Create a Directory on the host system where the data and config will be stored. This is a one time job

````
mkdir /opt/trisul6_root
````

### 2. Run 

Give this instance a name trisul1a, 1b etc.. for managing them 

````

# start trisul and capture from enp5s0 
sudo docker run --name=trisul1a --net=host -v /opt/trisul6_root:/trisulroot -d trisul-full enp5s0 

# or if you want to login and configure trisul yourselves
sudo docker run --name=trisul1a --net=host -v /opt/trisul6_root:/trisulroot -d trisul-full


````

Can check using

````
sudo docker exec -it trisul1a /bin/bash
````

### 3. Login

Go to localhost:4000

Done! 
