# Gluster Server

This repository will help to create a GlusterFS server cluster using docker containers.

This example setup needs 2 servers and several dns entries. 
Serversnames are core-1 and core-2, with the following dns entries:
- core-1 -> gluster.core-1.mydomain
- core-2 -> gluster.core-1.mydomain

Use round-robin dns to core-1 and core-2 on the client.

Both servers are identical on this setup and use the same volume mounts.

Take care to use a private network since all ports are opened to the host interface.
The hosts /data directory filesystem needs to be glusterfs compatible, btrfs, xfs etc.

## Build

Build the docker image
```bash
docker build -t blang/gluster-server .
```

It's also available on dockerhub as `blang/gluster-server`.


## Bootstrap
Servers need a setup with some manual steps.

### On both servers
```bash
mkdir -p /data/glusterserver/data
mkdir -p /data/glusterserver/vols
mkdir -p /data/glusterserver/etc
cp hosts /data/glusterserver/etc/hosts
```

Create self-reference in containers /etc/hosts for each file:
```bash
echo "127.0.0.1 gluster.core-%i.mydomain" >> /data/glusterserver/etc/hosts
```
Replace %i with current host number. Otherwise gluster will not work.

### On core-2
Start gluster server non-interactive since setup is done on core-1.

```bash
docker run --privileged -v /data/glusterserver/data:/data -v /data/glusterserver/metadata:/var/lib/glusterd -v /data/glusterserver/etc/hosts:/etc/hosts -p 24007:24007 -p 24009:24009 -p 49152:49152 blang/gluster-server
```

### On core-1
Start shell on core-1:
```bash
docker run --privileged -v /data/glusterserver/data:/data -v /data/glusterserver/metadata:/var/lib/glusterd -v /data/glusterserver/etc/hosts:/etc/hosts -p 24007:24007 -p 24009:24009 -p 49152:49152 -i -t blang/gluster-server /bin/bash
```

Inside the core-1 container:
```bash
# should return 127.0.0.1
ping gluster.core-1.mydomain

# core-2 should be reachable via private network
ping gluster.core-2.mydomain

# start glusterd
glusterd

# connect to core-2
gluster peer probe gluster.core-2.mydomain

# create volume 'datastore'
gluster --mode=script volume create datastore replica 2 gluster.core-1.mydomain:/data/datastore gluster.core-2.mydomain:/data/datastore

# start volume
gluster volume start datastore

# info should return replicated set with 2 bricks
gluster volume info datastore

# status should print both nodes to be online 
gluster volume status datastore
```

Stop both containers now, if everything was successful, your containers are ready to go.

## Production
Run on each server:

```bash
docker run --privileged -v /data/glusterserver/data:/data -v /data/glusterserver/metadata:/var/lib/glusterd -v /data/glusterserver/etc/hosts:/etc/hosts -p 24007:24007 -p 24009:24009 -p 49152:49152 blang/gluster-server
```

Both server will connect to each other and heal automatically.
If you need to interact with the gluster interface later, start one of those servers in shell mode, start `glusterd` and use `gluster help`.