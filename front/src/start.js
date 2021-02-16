import '@tarantool.io/frontend-core';
import './index';

// Gap
import React from 'react';
const Root = () => 'Gap';
window.tarantool_enterprise_core.register(
  'Gap',
  [{ label: 'Gap', path: `/gap/` }],
  Root,
  'react',
  null
);

window.tarantool_enterprise_core.install();
