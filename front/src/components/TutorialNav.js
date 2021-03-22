// @flow
import { css, cx } from 'emotion';
import React from 'react';
import { Link } from 'react-router-dom';
import { textStyles, colors } from '@tarantool.io/ui-kit';
import type { ParsedSections } from '../fn/splitMarkdown';

const styles = {
  list: css`
    list-style: none;
    padding-left: 0;
    margin: 0;
  `,
  item: css`
    display: block;
    border-left: solid 4px transparent;
  `,
  link: css`
    display: block;
    padding: 12px 16px;
    border-bottom: 1px solid ${colors.intentBase};
    text-decoration: none;
    color: ${colors.dark};

    &:hover {
      background-color: ${colors.intentBase};
    }
  `,
  itemActive: css`
    border-left-color: ${colors.intentWarningAccent};
  `
};

type Props = {
  className?: string,
  sections: ParsedSections,
  selectedSection?: number
}

export const TutorialNav = (
  { className, sections, selectedSection = 0 }: Props
) => (
  <ul className={cx(styles.list, className)}>
    {sections.map(({ h2, path }, i) => (
      <li
        className={cx(
          styles.item,
          { [styles.itemActive]: i === selectedSection }
        )}
      >
        <Link className={cx(textStyles.basic, styles.link)} to={path}>{h2}</Link>
      </li>
    ))}
  </ul>
);
