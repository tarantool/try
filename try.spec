Summary: try.tarantool.org service
Name: try
Version: master
Release: 1
License: BSD
URL: http://try.tarantool.org
Group: Utilities/Console
Source0: https://github.com/tarantool/try/archive/master.zip

%description
Try tarantool is interactive Tarantool console

######################################################
%prep  
%setup -q %{name}-master

%build

%install
mkdir -p  %{buildroot}%{_bindir}
mkdir -p  %{buildroot}%{_datadir}/tarantool/try_tarantool
mkdir -p  %{buildroot}%{_datadir}/tarantool/try_tarantool/container
mkdir -p  %{buildroot}%{_datadir}/doc/tarantool/try_tarantool/README
mkdir -p  %{buildroot}%{_datadir}/tarantool/try_tarantool/templates
mkdir -p  %{buildroot}%{_datadir}/tarantool/try_tarantool/public/js
mkdir -p  %{buildroot}%{_datadir}/tarantool/try_tarantool/public/css


install -m 755 start.lua  %{buildroot}%{_bindir}/try_tarantool
install -m 755 container/tool.sh  %{buildroot}%{_bindir}/try_tarantool_container
install -m 755 try_tarantool.lua %{buildroot}%{_datadir}/tarantool/try_tarantool/init.lua
install -m 644 README.md  %{buildroot}%{_datadir}/doc/tarantool/try_tarantool/README.md
install -m 644 templates/index.html  %{buildroot}%{_datadir}/tarantool/try_tarantool/templates/index.html
install -m 644 public/js/jquery-1.7.1.min.js  %{buildroot}%{_datadir}/tarantool/try_tarantool/public/js/jquery-1.7.1.min.js
install -m 644 public/js/jquery.mousewheel-min.js  %{buildroot}%{_datadir}/tarantool/try_tarantool/public/js/jquery.mousewheel-min.js
install -m 644 public/js/jquery.terminal-min.js  %{buildroot}%{_datadir}/tarantool/try_tarantool/public/js/jquery.terminal-min.js
install -m 644 public/css/jquery.terminal.css  %{buildroot}%{_datadir}/tarantool/try_tarantool/public/css/jquery.terminal.css
install -m 644 container/Dockerfile %{buildroot}%{_datadir}/tarantool/try_tarantool/container/Dockerfile
install -m 644 container/Dockerfile %{buildroot}%{_datadir}/tarantool/try_tarantool/container/container.lua

%files
%defattr(-,root,root,-)
%{_datadir}/doc/tarantool/try_tarantool/README.md
%{_datadir}/tarantool/try_tarantool/init.lua
%{_datadir}/tarantool/try_tarantool/public/js/jquery-1.7.1.min.js
%{_datadir}/tarantool/try_tarantool/public/js/jquery.mousewheel-min.js
%{_datadir}/tarantool/try_tarantool/public/js/jquery.terminal-min.js
%{_datadir}/tarantool/try_tarantool/public/css/jquery.terminal.css
%{_datadir}/tarantool/try_tarantool/templates/index.html
%{_datadir}/tarantool/try_tarantool/container/Dockerfile
%{_datadir}/tarantool/try_tarantool/container/container.lua
%{_bindir}/try_tarantool_container
%{_bindir}/try_tarantool
