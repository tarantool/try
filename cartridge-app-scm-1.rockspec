package = 'cartridge-app'
version = 'scm-1'
source  = {
    url = '/dev/null',
}

dependencies = {
    'tarantool',
    'lua >= 5.1',
    'checks == 3.1.0-1',
    'cartridge == scm-1',
    'analytics == scm-1',
    'cartridge-extensions == scm-1',
    'crud == 0.3.0',
}

build = {
    type = 'make';
    install_variables = {
        INSTALL_LUADIR="$(LUADIR)",
    },
}