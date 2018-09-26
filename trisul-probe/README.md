Docker : trisul-probe
===========

trisul-probe builds the Docker image for a Trisul Probe node 


## Using this Trisul-Probe image to join a distributed domain

### 1. Obtain from the Trisul-Domain administrator the following three files

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


## For Hub Administrators

When you get a request for a new probe, you need to provide the following three credentials.

1. domain certificate 
2. probe certificate containing the new ProbeName  
3. probe private key 

### Hub admin : Do the following steps

Assign a unique name to the new probe in the context. Say `probeEAST11`.To select a unique probe name, use `trisulctl_hub info context default` to see all existing probes

#### Create a probe cert + key

You can create this on any probe node.  You just need the `trisulctl_probe` CLI tool 

````
trisulctl_probe create probe
  enter name
  enter description

````

Send the following to the probe requestor

1. The new probe cert+key will be found in `/usr/local/share/trisul-probe/probeXX.cert`  and `cert_secret`. 
2. The domain cert can be found in `/usr/local/etc/trisul-hub/domain0/domain0.cert`

#### Authorize this on the hub 

Only when you perform this step can the new probe connect to your domain.

````
trisulctl_hub install probe probeXYZ.cert 
trisulctl_hub set config default@hub0 addlayer=probeXYZ 
````

For more details see Trisul Documentation , [Step 5 and Step 6 in Deploy a new probe](https://www.trisul.org/docs/ug/domain/deploy_probe.html) 


