Docker : trisul-probe
===========

trisul-probe builds the Docker image for a Trisul Probe node 

```
docker pull trisulnsm/trisul-probe 
```

## Bringing a new Trisul-Probe online 

The following steps connect the new probe to a Trisul distributed monitoring domain. 

### 1. Obtain certificates from the Trisul-Domain administrator 

The domain admin will assign a name to the new probe like `probeEAST1`. This is  shown as `..XYZ` in the listings below 

The following certificates and keys will be given to you by the admin. See [For Hub Administrators](#for-hub-administrators) 

  1. `domain0.cert`  - the domain certificate (public key) file 
  2. `probeXYZ.cert` - the probe certificate (public key) file
  3. `probeXYZ.cert_secret` - the probe private key file 


### 2. Create a docker volume on your local storage 

Put above three files given to you by the Hub administrator in that volume.


_Substitute the actual probe name instead of probeEAST11_ 

````
sudo mkdir /home/unpl/probeEAST11data
sudo cp domain0.cert /home/unpl/probeEAST11data
sudo cp probeEAST11.cert /home/unpl/probeEAST11data
sudo cp probeEAST11.cert_secret /home/unpl/probeEAST11data
````

### 3. Initialize a probe with the certificate 

This step installs the certificate-key pair on the probe 

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


### More steps

Your new probe should now be online and connected to the distributed domain.
Use the following commands inside the docker container to confirm 


````

# login to the container
docker exec -it /bin/bash probe1a

# check status from the CLI 
trisulctl_probe 
   list probes
   info context

````


## For Hub Administrators

When you get a request for a new probe, you need to provide the following three credentials.

1. domain certificate 
2. probe certificate containing the new ProbeName  
3. probe private key 

### 1. Select a unique name for the new probe 

Assign a unique and meaningful name to the new probe. 

To select a unique probe name, use `trisulctl_hub info context default` to see all existing probes

### 2. Create a probe cert + key

You can create this on any probe node.  You just need the `trisulctl_probe` CLI tool 

````
trisulctl_probe create probe
  enter name
  enter description

````

### 3. Send the credentials to the probe 

Send the following to the probe requestor

1. The new probe cert+key will be found in `/usr/local/share/trisul-probe/probeXX.cert`  and `cert_secret`. 
2. The domain cert can be found in `/usr/local/etc/trisul-hub/domain0/domain0.cert`

### 4. Authorize this on the hub 

Only when you perform this step can the new probe connect to your domain.

````
trisulctl_hub install probe probeXYZ.cert 
trisulctl_hub set config default@hub0 addlayer=probeXYZ 
````

For more details see Trisul Documentation , [Step 5 and Step 6 in Deploy a new probe](https://www.trisul.org/docs/ug/domain/deploy_probe.html) 


