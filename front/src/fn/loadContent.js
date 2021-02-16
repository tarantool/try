// @flow
import { updateImagesPaths } from './splitMarkdown';

const prefix = process.env.REACT_APP_MD_URL || '';

const loadMDFile = (fileName: string) =>
  fetch(`${prefix}/${fileName}`)
    .then(response => {
      const { status, statusText } = response;

      if(status !== 200) {
        throw new Error(`${status} ${statusText}`);
      }

      return response.text();
    })
    .then(text => updateImagesPaths(text, prefix));

export const loadTutorialContent = () => loadMDFile('index.md');

export const loadPopupContent = () => loadMDFile('popup.md');
