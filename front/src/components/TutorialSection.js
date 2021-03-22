// @flow
import { css, cx } from 'emotion';
import React from 'react';
import { withRouter } from 'react-router-dom';
import type { History } from 'react-router';
import { Button, ControlsPanel, Markdown } from '@tarantool.io/ui-kit';
import type { ParsedSections } from '../fn/splitMarkdown';

const styles = {
  wrap: css`
    padding: 40px;
    background: white;
    border: 1px solid #E8E8E8;
    border-radius: 4px;
  `,
  rightControls: css`
    margin-top: 60px;
    justify-content: flex-end;
  `
};

type Props = {
  className?: string,
  history: History,
  sections: ParsedSections,
  selectedSection?: number
}

export const TutorialSection = withRouter((
  {
    className,
    history,
    sections,
    selectedSection = 0
  }:
Props
) => (
  <div className={cx(styles.wrap, className)}>
    <Markdown text={sections[selectedSection].text} />
    <ControlsPanel
      className={styles.rightControls}
      controls={[
        ...selectedSection > 0
          ? [
            <Button
              text='Назад'
              className='meta_TryCartridgeTutorial_PrevPage'
              size='l'
              onClick={() => history.push(sections[selectedSection - 1].path)}
            />
          ]
          : [],
        ...selectedSection < sections.length - 1
          ? [
            <Button
              text='Далее'
              className='meta_TryCartridgeTutorial_NextPage'
              intent='primary'
              size='l'
              onClick={() => history.push(sections[selectedSection + 1].path)}
            />
          ]
          : []
      ]}
      thin
    />
  </div>
));
