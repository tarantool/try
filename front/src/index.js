// @flow
import * as React from 'react';
import { matchPath } from 'react-router';
import { SVGImage } from '@tarantool.io/ui-kit';
import { ConnectedApp } from './components/App';
import menuIcon from './menu-icon.svg';
import { PROJECT_NAME } from './constants';
import { sectionChange, loadTutorialFx } from './store';

const projectPath = path => `/${PROJECT_NAME}/${path}`;
const { tarantool_enterprise_core } = window;

loadTutorialFx();

tarantool_enterprise_core.history.listen(
  ({ pathname }) => {
    const match = matchPath(pathname, {
      path: `/${PROJECT_NAME}/:sectionId`,
      exact: true,
      strict: false
    })

    if (match && match.params) {
      sectionChange(match.params.sectionId)
    }
  }
);

if (tarantool_enterprise_core.history.location.pathname.indexOf(`/${PROJECT_NAME}`) !== 0) {
  tarantool_enterprise_core.history.replace(projectPath(''));
}

tarantool_enterprise_core.register(
  PROJECT_NAME,
  [
    {
      label: 'Tutorial',
      path: `/${PROJECT_NAME}/`,
      icon: <SVGImage glyph={menuIcon} />
    }
  ],
  ConnectedApp,
  'react',
  null
);
