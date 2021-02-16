// @flow
import {
  combine,
  createStore,
  createEffect,
  createEvent
} from 'effector';
import { loadTutorialContent, loadPopupContent } from '../fn/loadContent';
import {
  splitMarkdownSections,
  type ParsedSections
} from '../fn/splitMarkdown';
import { PROJECT_NAME } from '../constants';

export type WelcomeModalState = 'loading' | 'visible' | 'hidden';

const $tutorialSections = createStore<ParsedSections | null>(null);
const $tutorialSectionsLoding = createStore<bool>(false);
const $tutorialSectionsError = createStore<string | null>(null);
const $welcomeModalContent = createStore<string | null>(null);
const $currentSection = createStore<string | null>(null);
const $welcomeModalState = createStore<WelcomeModalState>('loading');

export const sectionChange = createEvent<string>('Changing tutorial section');
export const welcomeModalClose = createEvent<mixed>();
export const sectionsErrorModalClose = createEvent<mixed>();

export const $welcomeModal = combine({
  state: $welcomeModalState,
  content: $welcomeModalContent
});

export const $tutorial = combine({
  currentSection: $currentSection,
  tutorialSections: $tutorialSections,
  tutorialSectionsError: $tutorialSectionsError,
  tutorialSectionsLoding: $tutorialSectionsLoding
});

export const loadTutorialFx = createEffect<void, ParsedSections | null, Error>({
  handler: async () => {
    return await loadTutorialContent()
      .then(text => splitMarkdownSections(text, PROJECT_NAME));
  }
});

export const loadPopupFx = createEffect<void, string, Error>({
  async handler() {
    return await loadPopupContent()
  }
});

// init
$currentSection
  .on(sectionChange, (_, v) => v);

$welcomeModalContent
  .on(loadPopupFx.doneData, (_, str) => str);

$welcomeModalState
  .on(loadPopupFx.done, () => 'visible')
  .on(loadPopupFx.fail, () => 'hidden')
  .on(welcomeModalClose, () => 'hidden');

$tutorialSections
  .on(loadTutorialFx.doneData, (_, v) => v);

$tutorialSectionsError
  .on(loadTutorialFx.failData, (_, err) => err && err.message)
  .on(sectionsErrorModalClose, () => null);

$tutorialSectionsLoding
  .on(loadTutorialFx.doneData, () => false)
  .on(loadTutorialFx.failData, () => false)
  .on(loadTutorialFx, () => true);
