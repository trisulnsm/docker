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

Note :  If you are developing on same machine you can use `trisul-full` instead of the dockerhub `trisulnsm/trisul6` 

#### 2.1 start trisul and capture from enp5s0 

````
sudo docker run --name=trisul1a --net=host -v /opt/trisul6_root:/trisulroot -d trisulnsm/trisul6 --interface enp5s0 
````


#### 2.2 start instace of trisul, you need to login and configure 

````
sudo docker run --name=trisul1a --net=host -v /opt/trisul6_root:/trisulroot -d trisulnsm/trisul6 
````

#### 2.3 start instance of trisul capture from enp5s0 change webserver ports 

````
sudo docker run --name=trisul1a --net=host -v /opt/trisul6_root:/trisulroot -d trisulnsm/trisul6 \
  --interface enp5s0 --webserver-port 4000 --websockets-port 4003 
````

You can login to the docker using the usual -it switch 


````
sudo docker exec -it trisul1a /bin/bash
````

### 3. Login

Go to localhost:4000

Done! 
