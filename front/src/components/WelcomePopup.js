// @flow
import React from 'react';
import { Button, Markdown, Modal } from '@tarantool.io/ui-kit';
import { useStore } from 'effector-react';
import { $welcomeModal, loadPopupFx, welcomeModalClose } from '../store';

loadPopupFx();

export const WelcomePopup = () => {
  const { state, content } = useStore($welcomeModal);

  return (
    <Modal
      footerControls={[
        <Button text='Приступить' size='l' intent='primary' onClick={welcomeModalClose} />
      ]}
      onClose={welcomeModalClose}
      title='Начните изучать платформу Tarantool'
      visible={state === 'visible'}
      wide
    >
      <Markdown text={content} />
    </Modal>
  );
}
