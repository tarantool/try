FROM centos:centos7
MAINTAINER Roman Tsisyk <roman@tarantool.org>

# Add Tarantool repository
ADD CentOS-Tarantool.repo /etc/yum.repos.d/
# Install Tarantool
RUN yum install tarantool tarantool-modules -y

# Prepare configuration
RUN adduser -d /var/lib/tarantool -s /sbin/nologin tarantool 
ADD container.lua /var/lib/tarantool/
RUN chown -R tarantool:tarantool /var/lib/tarantool
USER tarantool
WORKDIR /var/lib/tarantool/
CMD ./container.lua
