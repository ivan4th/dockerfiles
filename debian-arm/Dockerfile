# ARM emulation environment
FROM ubuntu:16.04
MAINTAINER ivan4th <ivan4th@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

COPY stage*.sh /
COPY kernel_config /
COPY init /
COPY run_qemu.sh /usr/bin/
COPY stop_qemu.sh /usr/bin/

# uncomment to use a custom kernel (untested)
# COPY vmlinuz /

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    gcc-arm-linux-gnueabihf qemu debootstrap gcc git libc6-dev \
    xz-utils netcat screen e2fsprogs cpio genext2fs ca-certificates \
    make bc && \
    chmod +x /stage*.sh && \
    chmod +x /usr/bin/run_qemu.sh /usr/bin/stop_qemu.sh && \
    /stage1.sh && \
    apt-get purge -y gcc git libc6-dev gcc-arm-linux-gnueabihf \
            e2fslibs-dev debootstrap strace gdb libc6-dev perl make bc genext2fs && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /usr/share/doc /var/cache/debconf/* /usr/share/man /stage1.sh /initrd && \
    cd /usr/share/locale/ && ls -1 | grep -v en | xargs rm -rf
