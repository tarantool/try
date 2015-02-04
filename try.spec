Summary: try.tarantool.org service
Name: tarantool-try-module
Version: 1.0
Release: 1
License: BSD
BuildArch: noarch
URL: http://try.tarantool.org
Group: Utilities/Console
Requires: docker
Requires: tarantool >= 1.6.3
Source0: tarantool-try-module.tar.gz

%global debug_package %{nil}

%define luadir %{_datadir}/tarantool/try
%define containersh %{luadir}/container/container.sh

%description
Try tarantool is interactive Tarantool console

######################################################
%prep

%setup -q -n %{name}

%build

%install

install -d %{buildroot}%{luadir}
sed -i "s#APP_DIR = .*#APP_DIR = '%{luadir}'#" try/init.lua
install -m 644 try/init.lua %{buildroot}%{luadir}

install -d %{buildroot}%{_sysconfdir}/cron.d
echo -e '0 4 * * * root %{containersh} cron'> %{buildroot}%{_sysconfdir}/cron.d/%{name}

install -d %{buildroot}%{luadir}/container
install -m 644 try/container/CentOS-Tarantool.repo %{buildroot}%{luadir}/container/
install -m 644 try/container/Dockerfile %{buildroot}%{luadir}/container/
install -m 755 try/container/container.lua %{buildroot}%{luadir}/container/
install -m 755 try/container/container.sh %{buildroot}%{luadir}/container/

install -d %{buildroot}%{luadir}/templates
install -m 644 try/templates/index.html  %{buildroot}%{luadir}/templates/index.html

install -d %{buildroot}%{luadir}/public

install -d %{buildroot}%{luadir}/public/js
install -m 644 try/public/js/jquery.mousewheel-min.js %{buildroot}%{luadir}/public/js/
install -m 644 try/public/js/jquery.terminal-min.js  %{buildroot}%{luadir}/public/js/

install -d %{buildroot}%{luadir}/public/theme/
install -m 644 try/public/theme/jquery.terminal.css  %{buildroot}%{luadir}/public/theme/
install -m 644 try/public/theme/design.css  %{buildroot}%{luadir}/public/theme/
install -m 644 try/public/theme/pygmentize.css  %{buildroot}%{luadir}/public/theme/

install -d %{buildroot}%{_sysconfdir}/tarantool/instances.available/
install -m 644 start.lua %{buildroot}%{_sysconfdir}/tarantool/instances.available/try.lua

%files
%defattr(-,root,root,-)
%doc README.md
%{_sysconfdir}/cron.d/%{name}
%{_sysconfdir}/tarantool/instances.available/try.lua
%{luadir}/*
