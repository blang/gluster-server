FROM ubuntu:14.04
MAINTAINER Benedikt Lang <mail@blang.io>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -q

# generate a local to suppress warnings
RUN locale-gen en_US.UTF-8

RUN apt-get install -y wget attr software-properties-common psmisc

RUN add-apt-repository ppa:semiosis/ubuntu-glusterfs-3.5 && \
	apt-get update -q && \
	apt-get install -y glusterfs-server

VOLUME ["/data", "/var/lib/glusterd"]
EXPOSE 111 111/udp 24007 24009 49152
CMD ["/usr/sbin/glusterd","-N"]
