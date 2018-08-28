# Based on https://github.com/davide/docker-zerotier/blob/master/Dockerfile
FROM ubuntu:16.04
MAINTAINER Ivan Shvedunov <ivan4th@gmail.com>

COPY zt-gpg-key /tmp/

RUN echo "deb http://download.zerotier.com/debian/xenial xenial main" \
      >/etc/apt/sources.list.d/zerotier.list && \
    apt-key add /tmp/zt-gpg-key && \
    apt-get update && apt-get install -y curl gnupg && \
    apt-get install -y zerotier-one=1.2.12 && \
    tar -C / -cvf /zerotier.tar var/lib/zerotier-one

EXPOSE 9993/udp

COPY entrypoint.sh /
CMD ["/entrypoint.sh"]
