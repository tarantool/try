# Tarantool Analytic Effect Module


## Usage

Generate bundle with google analytics. Use bundle method with options. Option could be analytic key(`ga`) or metrika key(`metrika`).

You could use ga_options for extra args for Google Analytics. Now support cookie_domain. [More info here.](https://developers.google.com/analytics/devguides/collection/analyticsjs/cookies-user-id?hl=ru)

Example:
```
local front = require('frontend-core')
local analytics = require('analytics')

front.add('analytics_static', analytics.static_bundle)
front.add('ga', analytics.use_bundle({ ga = '22120502-2' }))

front.init(router)

httpd:start()

```
