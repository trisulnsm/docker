Docker : trisul-probe
===========

trisul-probe builds the Docker image for a Trisul Probe node 


## Using this Trisul-Probe image to join a distributed domain

### 1. Demand from the Trisul-Domain administrator the following three files
  1. `domain0.cert`  - the domain certificate (public key) file 
  2. `probeXYZ.cert` - the probe certificate (public key) file
  3. `probeXYZ.cert_secret` - the probe private key file 


Create a docker volume on your local storage for the Docker probe to use  and put the above three files in that place 


````
sudo mkdir /home/unpl/probeEAST11data
sudo cp domain0.cert /home/unpl/probeEAST11data
sudo cp probeEAST11.cert /home/unpl/probeEAST11data
sudo cp probeEAST11.cert_secret /home/unpl/probeEAST11data
````

### 3. Initialize a probe with the certificate 

````
docker run --name=probe1a --net=host \
      -v /home/unpl/probeEAST11data:/trisulroot \
	      -d trisulnsm/trisul-probe   \
		      --install-probe domain0  probeEAST11

# to check progress 
docker logs -f probe1a 
````

### 4. Stop the container, now it is initialized and ready to run 

````
docker stop probe1a
docker rm probe1a
````

### 5. Start a probe on interface wlp4s0 


Use the `--probe-id` argument to use the correct probe certificate 

````
docker run --name=probe1a --net=host \
      -v /home/unpl/probeEAST11data:/trisulroot \
	      -d trisulnsm/trisul-probe   \
		      --probe-id probeEAST11 \
				   --interface wlp4s0 
````


## More steps

Your new probe should now be online and connected to the distributed domain.


````

# login to the container
docker exec -it /bin/bash probe1a

# check status
trisulctl_probe 
   list probes
   info context

````



