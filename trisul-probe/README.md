Docker : trisul-probe
===========

trisul-probe builds the Docker image for a Trisul Probe node 


## Using this Trisul-Probe image to join a distributed domain

1. Demand from the Trisul-Domain administrator the following three files
  1. domain0.cert  - the domain certificate (public key) file 
  2. probeXYZ.cert - the probe certificate (public key) file
  3. probeXYZ.cert_secret - the probe private key file 


2. Create a docker volume on your local storage for the Docker probe to use  and put the above three files in that place 


````
sudo mkdir /home/unpl/probeEAST11data
sudo cp domain0.cert /home/unpl/probeEAST11data
sudo cp probeEAST11.cert /home/unpl/probeEAST11data
sudo cp probeEAST11.cert_secret /home/unpl/probeEAST11data
````

3. Install the probe certificate into the docker 

````
docker run --name=probe1a --net=host -v /home/unpl/probeEAST11data:/trisulroot -d trisul-probe   --install-probe domain0  probeEAST11
````

4. Once installed , you can start capturing using docker run 

````
docker run --name=probe1a --net=host -v /home/unpl/probeEAST11data:/trisulroot -d trisul-probe   --interface wlp4s0 
````






