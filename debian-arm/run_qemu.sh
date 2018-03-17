#!/bin/bash
screen -dmS qemu qemu-system-arm -M vexpress-a9 -m 256 -cpu cortex-a9 -nographic -no-reboot -sd "$1" -kernel /arm/vmlinuz -append "root=/dev/mmcblk0 console=ttyAMA0 rw rootwait" -net user,hostfwd=tcp::20022-:22 -net nic
echo "Waiting for QEMU..." 1>&2
for ((i = 0; i < 500; i++)); do
    if nc -w 2 localhost 20022 </dev/null 2>/dev/null | grep -q SSH; then
        echo "Done waiting for QEMU." 1>&2
        exit 0
    fi
    echo "..." 1>&2
    sleep 0.3
done
echo "Timed out waiting for QEMU." 1>&2
screen -dr
exit 1
