#!/usr/bin/env python

import codecs
import jinja2

env = {'page':{'slug':'try', 'title': 'Tarantool - Try'}}

envir = jinja2.Environment( loader = jinja2.DictLoader({
    'base'      : codecs.open('base', 'r', encoding='utf-8').read(),
    'menu'      : codecs.open('menu', 'r', encoding='utf-8').read(),
    'try.html'  : codecs.open('try.html', 'r', encoding='utf-8').read()
}) )

codecs.open('../try/templates/index.html', 'w', encoding='utf-8').write(envir.get_template('try.html').render(**env))
