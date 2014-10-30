try.tarantool.org
=================

#### Interactive Tarantool web console.

Turn Tarantool into an HTTP server and a load balancer and provide an interactive Lua console to a bunch of Tarantool instances running in a Linux container.

#### Installation

You can start tarantool-try on your host.
Prerequisites:
* tarantool 
http://tarantool.org
* docker
http://www.docker.com/
* tarantool http https://github.com/tarantool/http/ (use luarocks https://github.com/tarantool/rocks )

```
git clone https://github.com/tarantool/try
```
Build docker image:
```
cd /try/container/
sudo docker build -t tarantool .
```
Add user to group `docker`:
```
sudo echo usermod -a -G docker $USER
```
Start try-tarantool web server:
```
tarantool start.lua
```
Web server runs on `localhost:11111` by default.
You can change host, port and tarantool configuration in start.lua
