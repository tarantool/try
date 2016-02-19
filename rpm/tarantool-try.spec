Name: tarantool-try
Version: 1.0.0
Release: 1%{?dist}
Summary: try.tarantool.org service
Group: Applications/Databases
License: BSD
URL: https://github.com/tarantool/try
Source0: https://github.com/tarantool/try/archive/%{version}/try-%{version}.tar.gz
BuildArch: noarch
BuildRequires: tarantool >= 1.6.8.0
BuildRequires: python >= 2.6.0
BuildRequires: python-jinja2 >= 2.7.0
BuildRequires: make
Requires: tarantool >= 1.6.8.0
Requires: tarantool-http >= 1.0.0
Requires: docker >= 1.8.2
Requires: coreutils
Requires: anacron

%description
A Tarantool web demo.

%define luadir %{_datadir}/tarantool/try
%define containersh %{luadir}/container/container.sh

%description
An interactive web-console for Tarantool.

%prep
%setup -q -n %{name}-%{version}

%build
make -C templates

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
install -m 644 try/templates/blank.html  %{buildroot}%{luadir}/templates/blank.html

install -d %{buildroot}%{luadir}/public

install -d %{buildroot}%{luadir}/public/js
install -m 644 try/public/js/jquery.mousewheel-min.js %{buildroot}%{luadir}/public/js/
install -m 644 try/public/js/jquery.terminal-min.js  %{buildroot}%{luadir}/public/js/

install -d %{buildroot}%{luadir}/public/theme/
install -m 644 try/public/theme/jquery.terminal.css  %{buildroot}%{luadir}/public/theme/
install -m 644 try/public/theme/design.css  %{buildroot}%{luadir}/public/theme/
install -m 644 try/public/theme/pygmentize.css  %{buildroot}%{luadir}/public/theme/
install -d %{buildroot}%{luadir}/public/theme/fonts
install -m 644 try/public/theme/fonts/HelveticaNeue.eot  %{buildroot}%{luadir}/public/theme/fonts/
install -m 644 try/public/theme/fonts/HelveticaNeue.svg  %{buildroot}%{luadir}/public/theme/fonts/
install -m 644 try/public/theme/fonts/HelveticaNeue.ttf  %{buildroot}%{luadir}/public/theme/fonts/
install -m 644 try/public/theme/fonts/HelveticaNeue.woff  %{buildroot}%{luadir}/public/theme/fonts/
install -m 644 try/public/theme/fonts/HelveticaNeue-Bold.eot  %{buildroot}%{luadir}/public/theme/fonts/
install -m 644 try/public/theme/fonts/HelveticaNeue-Bold.svg  %{buildroot}%{luadir}/public/theme/fonts/
install -m 644 try/public/theme/fonts/HelveticaNeue-Bold.ttf  %{buildroot}%{luadir}/public/theme/fonts/
install -m 644 try/public/theme/fonts/HelveticaNeue-Bold.woff  %{buildroot}%{luadir}/public/theme/fonts/

install -d %{buildroot}%{_sysconfdir}/tarantool/instances.available/
install -m 644 start.lua %{buildroot}%{_sysconfdir}/tarantool/instances.available/try.lua

%post
echo "Generating Docker images"
%{luadir}/container/container.sh cron || :

%files
%doc README.md
%{!?_licensedir:%global license %doc}
%license LICENSE
%{_sysconfdir}/cron.d/%{name}
%{_sysconfdir}/tarantool/instances.available/try.lua
%{luadir}/*

%changelog
* Thu Feb 18 2016 Roman Tsisyk <roman@tarantool.org> 1.0-1
- Initial version of the RPM spec.
