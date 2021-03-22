// @flow
import * as React from 'react';
import { connect } from 'effector-react';
import { Router, Switch, Route, Redirect } from 'react-router-dom';
import type { Location } from 'react-router';
import {
  Button,
  Modal,
  PageLayoutWithRef,
  SplashErrorNetwork,
  SectionPreloader,
  Text
} from '@tarantool.io/ui-kit';
import { type ParsedSections } from '../fn/splitMarkdown';
import { getScrollableParent } from '../fn/getScrollableParent';
import { TutorialLayout } from '../components/TutorialLayout';
import { WelcomePopup } from '../components/WelcomePopup';
import { PROJECT_NAME } from '../constants';
import { $tutorial, sectionsErrorModalClose } from '../store';

const projectPath = path => `/${PROJECT_NAME}/${path}`;
const { components: { AppTitle }, history } = window.tarantool_enterprise_core;

type Props = {
  location: Location,
  tutorialSections?: ParsedSections,
  tutorialSectionsLoding: bool,
  currentSection?: string,
  tutorialSectionsError: string | null
};

export class App extends React.Component<Props> {
  pageLayoutRef = React.createRef<HTMLElement>();

  componentDidUpdate(prevProps: Props) {
    if (this.props.location !== prevProps.location) {
      if (this.pageLayoutRef && this.pageLayoutRef.current) {
        const scrollableParent = getScrollableParent(this.pageLayoutRef.current);
        scrollableParent.scrollTo(0, 0);
      }
    }
  }

  render() {
    const {
      currentSection,
      tutorialSections,
      tutorialSectionsError,
      tutorialSectionsLoding
    } = this.props;

    if (tutorialSectionsLoding) {
      return <SectionPreloader />;
    }

    if (tutorialSectionsError) {
      return (
        <SplashErrorNetwork
          title='Ошибка загрузки руководства'
          details={tutorialSectionsError}
          description={<>
            Но вы можете воспользоваться сервисом
          </>}
        />
      );
    }

    return tutorialSections
      ? (
        <PageLayoutWithRef heading='Tutorial' ref={this.pageLayoutRef}>
          <AppTitle title='Tutorial' />
          <WelcomePopup />
          <Router history={history}>
            <Switch>
              <Route
                path={projectPath(':sectionId')}
                render={({ match: { params: { sectionId } } }) => {
                  const sectionIndex = tutorialSections.findIndex(
                    ({ id }) => id === sectionId
                  );

                  if (sectionIndex === -1) {
                    return (
                      <Redirect
                        to={projectPath(tutorialSections[0].id)}
                        push={false}
                      />
                    );
                  }

                  return (
                    <TutorialLayout
                      sections={tutorialSections}
                      selectedSection={parseInt(sectionIndex, 10)}
                    />
                  )
                }}
              />
              <Route
                render={() => (
                  <Redirect
                    to={projectPath(currentSection || tutorialSections[0].id)}
                    push={false}
                  />
                )}
              />
            </Switch>
          </Router>
        </PageLayoutWithRef>
      )
      : 'Fail'
  }
}

export const ConnectedApp = connect(App)($tutorial);
