package = 'analytics'
version = 'scm-1'
source  = {
    url = 'https://gitlab.com/tarantool/tarantool.io/analytics',
    branch = 'master',
}
dependencies = {
    'lua >= 5.1',
}
build = {
    type = 'make';
    install = {
        lua = {
            ['analytics'] = 'analytics.lua',
            -- ['analytics.bundle'] -- installed with make
        },
    },
    install_variables = {
        INST_LUADIR="$(LUADIR)",
    },

}
