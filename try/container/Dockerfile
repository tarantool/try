FROM centos:centos7
MAINTAINER Roman Tsisyk <roman@tarantool.org>

# Add Tarantool repository
ADD tarantool_1_6.repo /etc/yum.repos.d/
# Install Tarantool and modules
RUN yum install tarantool tarantool-expirationd tarantool-queue \
    tarantool-shard tarantool-http tarantool-mysql tarantool-pg \
    tarantool-luaossl -y

# Prepare configuration
ADD container.lua /var/lib/tarantool/
RUN chown -R tarantool:tarantool /var/lib/tarantool
USER tarantool
WORKDIR /var/lib/tarantool/
CMD ./container.lua
