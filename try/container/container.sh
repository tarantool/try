#!/bin/sh

# Change current dir to script dir
cd $(dirname $(readlink -f "$0"))

IMAGE_TAG=tarantool/try

cron() {
    # Regenerate container image
    docker build -t ${IMAGE_TAG} --no-cache=true --rm=true . 2>&1 >/dev/null |grep -v Uploading

    # Remove all stopped containers
    stopped=$(docker ps -a|grep Exited|awk '{print $1}')
    if [ -n "${stopped}" ]; then
        docker rm ${stopped} > /dev/null
    fi
}

case $1 in
cron)
    cron
    ;;
*)
    echo "Usage $0 cron"
    exit 1
esac

# vim: set ts=4 sw=4 et
