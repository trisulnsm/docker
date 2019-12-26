Docker : trisul-hub
===================

trisul-hub contains the Hub Component of Trisul Network Analytics 


The use case for distributed Trisul Hubs are :

1. HA - high availability 
2. Scaling - when a single Hub is not sufficient to handle data coming in from the probes.


## Enable HA Domain


** HA Mode: Requires a production license on the Hub nodes. 


In High Availability mode , Trisul is resilient to these three scenarios. 

 - a single probe failure
 - a single hub failure

This image can be used to be resilient to a single hub failure. 

### the Router  element

There is an element in a Trisul domain called a "router". This authorizes and connects all other
members of the domain like config, probe, hub, web, query nodes.  The router provides the 
'control plane' for Trisul - once connected the probes , hubs , and web elements talk directly to each other.

If the router fails, then these  control operations cannot be performed.  

There for for HA mode the first step is to create a Backup HA router. This requires you to create a new
domain certificate.




