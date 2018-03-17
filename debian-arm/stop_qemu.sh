#!/bin/bash
ssh qemu shutdown -h now >& /dev/null &
echo "Waiting for QEMU to stop..." 1>&2
for ((i = 0; i < 500; i++)); do
    sleep 2
    if ! pgrep qemu-system-arm >/dev/null; then
        echo "Done waiting for QEMU to stop." 1>&2
        exit 0
    fi
    echo "..." 1>&2
done
echo "Timed out waiting for QEMU to stop." 1>&2
exit 1
