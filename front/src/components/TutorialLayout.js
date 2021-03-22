// @flow
import { css, cx } from 'emotion';
import React from 'react';
import type { ParsedSections } from '../fn/splitMarkdown';
import { TutorialSection } from './TutorialSection';
import { TutorialNav } from './TutorialNav';

const { AppTitle } = window.tarantool_enterprise_core.components;

const styles = {
  wrap: css`
    display: flex;
    flex-direction: row;
    align-items: flex-start;
  `,
  section: css`
    flex-grow: 1;
    width: 300px;
  `,
  contentsTable: css`
    flex-shrink: 0;
    width: 280px;
    margin-left: 38px;
  `
};

type Props = {
  className?: string,
  sections: ParsedSections,
  selectedSection: number
}

export const TutorialLayout = (
  { className, sections, selectedSection }: Props
) => (
  <div className={cx(styles.wrap, className)}>
    <AppTitle title={sections[selectedSection].h2} />
    <TutorialSection
      className={cx(styles.section, className)}
      sections={sections}
      selectedSection={selectedSection}
    />
    <TutorialNav
      className={styles.contentsTable}
      sections={sections}
      selectedSection={selectedSection}
    />
  </div>
);
