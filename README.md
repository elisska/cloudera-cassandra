# cloudera-cassandra

This is a POC version of managing Cassandra cluster via Cloudera Manager. 

## Prerequisites

* Python 2.7+ (to create parcel's manifest)
* Maven
* Cloudera's **cm_ext** (a tool for making CM parcels and CSDs). Install it on your workstation like so:

1. `mkdir -p ~/github; cd ~/github`
2. `git clone https://github.com/cloudera/cm_ext; cd cm_ext`
3. `mvn package`

## Instructions

Tested on CentOS 6.5, Cloudeta Manager 5.6.0 (newer versions like 5.7 etc not tested), Datastax Cassandra 2.2.6.

### Parcel
1. Create the DATASTAX\_CASSANDRA parcel: `./build_parcel.sh <Version> <Distro>`. Example: `./build_parcel.sh 2.2.6 el6`
2. Serve the parcel: `./serve-parcel.sh`
3. In CM, add your machine to the list of `Remote Parcel Repository URLs` and click `Check for New Parcels`.
4. Download, Distribute, Activate. No need to restart the cluster as this parcel is not a dependency for any service.

### CSD
1. Create the CSD: `./build_csd.sh <Version>`. Example: ` ./build_csd.sh 1.0`. The CSD version is independent of the 
parcel version.
2. Copy the CSD jar (`DATASTAX-CASSANDRA-1.0.jar`) to CM host at `/opt/cloudera/csd/` and change the ownership of the jar to `﻿cloudera-scm:cloudera-scm`
3. Restart CM `service cloudera-scm-server restart`
4. Restart _Cloudera Management Service_ from the CM UI.
5. Install the Cassandra service with _Add a service_ option in CM (note that some workaround in the cluster installation is needed as for now - **you may add only 1 seed during initial service startup**)

**Note**: Step 3 and 4 can be avoided by using the 
[experimental](https://github.com/cloudera/cm_ext/wiki/CSD-Developer-Tricks-and-Tools#partial-installation-development-mode-only) api for installing CSDs without restarting CM.

### Things to do next

1. Rolling Cassandra start - start seeds one by one, wait for seeds to start, start rest of nodes
2. Rolling restart - done in service.sdl but requires Cloudera Enterprise license
3. Node decommissionin
4. Remove node from a cluster
5. Add Max heap and New Size JVM options
6. Add gracefull service stop
7. Add JMX security settings for using JXM not only on localhost
8. Add Cassandra ring status and health checks as separate commands
9. Add parameters for multi-datacenter and cross-rack support (now there is a hardcode to dc1 and rack1)
10. Add optional command to bootstrap individual nodes
 
### Your contribution is highly appreciated!!!
