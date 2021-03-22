local bundle = require('analytics.bundle')
local uuid = require('uuid')
local json = require('json')

return {
    use_bundle = function(options)
        if options.ga == nil and options.metrika == nil then
            return nil, error('no provide credentials for GA or metrika')
        end

        local res = ''

        if options.ga ~= nil then
            local ga_init_options = json.encode({
                type = 'ga',
                key = options.ga,
                options = options.ga_options
            })
            res = 'window.__analytics_module__(' .. ga_init_options .. ');'
        end

        if options.metrika ~= nil then
            local metrika_init_options = json.encode({
                type = 'metrika',
                key = options.metrika,
                options = options.metrika_options
            })
            res = 'window.__analytics_module__(' .. metrika_init_options .. ');'
        end

        return {
            [uuid.str() .. '.js'] = {
                body = res,
                mime = 'application/javascript',
                is_entry = true
            }
        }
    end,
    static_bundle = bundle,
}
