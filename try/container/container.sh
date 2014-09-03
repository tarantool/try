#!/bin/sh

# Change current dir to script dir
cd $(dirname $(readlink -f "$0"))

IMAGE_TAG=tarantool
MEMORY=512m
CORES=1

cron() {
    # Regenerate container image
    docker build -t ${IMAGE_TAG} --no-cache=true --rm=true . 2>&1 >/dev/null |grep -v Uploading

    # Remove all stopped containers
    stopped=$(docker ps -a|grep Exited|awk '{print $1}')
    if [ -n "${stopped}" ]; then
        docker rm ${stopped} > /dev/null
    fi

    # Remove all unused images
    unused=$(docker images|grep "^<none>" |awk '{print $3}')
    if [ -n "${unused}" ]; then
        docker rmi ${unused} > /dev/null
    fi
}

start() {
    container_id=$(docker run -m ${MEMORY} -c ${CORES} -d ${IMAGE_TAG})
    if [ $? -ne 0 ]; then
        return 1
    fi
    docker inspect ${container_id}
}

stop() {
    docker stop $1 > /dev/null
    rc=$?
    # Try to remove image in fork
    docker rm $1 &> /dev/null &
    return ${rc}
}

case $1 in
cron)
    cron
    ;;
start)
    start
    ;;
stop)
    if [ -z "$2" ]; then
        echo "Usage: $0 stop container_id"
        exit 1
    fi
    shift
    stop $*
    ;;
*)
    echo "Usage $0 start | stop | cron"
    exit 1
esac

# vim: set ts=4 sw=4 et
