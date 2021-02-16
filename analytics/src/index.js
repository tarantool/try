let isGoogleLoaded = false

const loadGoogle = () => {
  if (!isGoogleLoaded) {
    /*eslint-disable */
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
    /*eslint-enable */
    isGoogleLoaded = true
  }
};

window.__analytics_module__ = ({ type: analyticsType, key, options }) => {
  setTimeout(() => {
    window.tarantool_enterprise_core.analyticModule.effect(({
      type,
      action,
      category,
      label,
      value,
      url
    }) => {

      switch (type) {
        case 'pageview': {
          switch (analyticsType) {
            case 'ga': {
              window.ga('send', 'pageview', url)
              break;
            }
          }
          break;
        }
        case 'action': {
          switch (analyticsType) {
            case 'ga': {
              window.ga('send', 'event', category + '', action + '', label + '', value);
              break;
            }
          }
          break;
        }
      }
    })
  }, 100)
  switch(analyticsType) {
    case 'ga': {
      loadGoogle()
      let cookieSettings = 'auto'
      if (options && options.cookie_domain) {
        cookieSettings = { cookieDomain: options.cookie_domain }
      }
      window.ga('create', `UA-${key}`, cookieSettings);
      window.ga('send', 'pageview');
      break;
    }
    case 'metrika': {
      break;
    }
  }


};
