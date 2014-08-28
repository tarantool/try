Summary: try.tarantool.org service
Name: try
Version: 1.0
Release: 1
License: BSD
URL: http://try.tarantool.org
Group: Utilities/Console
Source0: try.tar.gz

%description
Try tarantool is interactive Tarantool console

######################################################
%prep

%setup -q -n %{name}

%build

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_sysconfdir}/cron.d
mkdir -p %{buildroot}%{_sysconfdir}/sudoers.d
mkdir -p %{buildroot}%{_datadir}/tarantool/try_tarantool
mkdir -p %{buildroot}%{_datadir}/tarantool/try_tarantool/container
mkdir -p %{buildroot}%{_datadir}/doc/tarantool/try_tarantool/README
mkdir -p %{buildroot}%{_datadir}/tarantool/try_tarantool/templates
mkdir -p %{buildroot}%{_datadir}/tarantool/try_tarantool/public/js
mkdir -p %{buildroot}%{_datadir}/tarantool/try_tarantool/public/css

sed -i "s#APP_DIR = '.'#APP_DIR = '%{_datadir}/tarantool/try_tarantool'#" try_tarantool.lua
sed -i "s#START_LXC = 'sudo ./container/try_tarantool_container.sh start '#START_LXC = 'sudo %{_bindir}/try_tarantool_container start'#" try_tarantool.lua
sed -i "s#RM_LXC = 'sudo ./container/try_tarantool_container.sh stop '#RM_LXC = 'sudo %{_bindir}/try_tarantool_container stop'#" try_tarantool.lua

echo -e '0 4 *** root %{_bindir}/try_tarantool_container cron'> %{buildroot}%{_sysconfdir}/cron.d/try_tarantool
echo -e '%tarantool ALL = %{_bindir}/try_tarantool_container start, \\\n%{_bindir}/try_tarantool_container stop *'> %{buildroot}%{_sysconfdir}/sudoers.d/try_tarantool


install -m 755 container/try_tarantool_container.sh  %{buildroot}%{_bindir}/try_tarantool_container
install -m 644 container/Dockerfile %{buildroot}%{_datadir}/tarantool/try_tarantool/container/Dockerfile
install -m 644 container/container.lua %{buildroot}%{_datadir}/tarantool/try_tarantool/container/container.lua
install -m 755 start_try_tarantool.lua  %{buildroot}%{_bindir}/try_tarantool
install -m 755 try_tarantool.lua %{buildroot}%{_datadir}/tarantool/try_tarantool/init.lua
install -m 644 templates/index.html  %{buildroot}%{_datadir}/tarantool/try_tarantool/templates/index.html
install -m 644 public/js/jquery-1.7.1.min.js  %{buildroot}%{_datadir}/tarantool/try_tarantool/public/js/jquery-1.7.1.min.js
install -m 644 public/js/jquery.mousewheel-min.js  %{buildroot}%{_datadir}/tarantool/try_tarantool/public/js/jquery.mousewheel-min.js
install -m 644 public/js/jquery.terminal-min.js  %{buildroot}%{_datadir}/tarantool/try_tarantool/public/js/jquery.terminal-min.js
install -m 644 public/css/jquery.terminal.css  %{buildroot}%{_datadir}/tarantool/try_tarantool/public/css/jquery.terminal.css
install -m 644 README.md  %{buildroot}%{_datadir}/doc/tarantool/try_tarantool/README.md

%files
%defattr(-,root,root,-)
%{_sysconfdir}/cron.d/try_tarantool
%{_sysconfdir}/sudoers.d/try_tarantool
%{_bindir}/try_tarantool_container
%{_datadir}/tarantool/try_tarantool/container/Dockerfile
%{_datadir}/tarantool/try_tarantool/container/container.lua
%{_bindir}/try_tarantool
%{_datadir}/tarantool/try_tarantool/init.lua
%{_datadir}/tarantool/try_tarantool/templates/index.html
%{_datadir}/tarantool/try_tarantool/public/js/jquery-1.7.1.min.js
%{_datadir}/tarantool/try_tarantool/public/js/jquery.mousewheel-min.js
%{_datadir}/tarantool/try_tarantool/public/js/jquery.terminal-min.js
%{_datadir}/tarantool/try_tarantool/public/css/jquery.terminal.css
%{_datadir}/doc/tarantool/try_tarantool/README.md

