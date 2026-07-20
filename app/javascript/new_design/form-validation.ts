import { isFormInputElement } from 'coldwired/utils';

import { delegate } from '@utils';

delegate('blur keydown', 'input, textarea', ({ target }) => {
  touch(target);
});

delegate(
  'click',
  'input[type="submit"]:not([formnovalidate])',
  ({ target }) => {
    const form = target instanceof Element ? target.closest('form') : null;
    const inputs = form ? form.querySelectorAll('input, textarea') : [];
    [...inputs].forEach(touch);
  }
);

function touch(target: EventTarget | null) {
  if (target instanceof Element) {
    target.classList.add('touched');
  }
}

// DSFR error rendering for forms opting in with data-dsfr-validation: native
// constraint validation still blocks submission, but its bubble is replaced by
// the DSFR error pattern rendered by the server (a hidden `#<input id>-error`
// element next to the input).
let dsfrInvalidForm: HTMLFormElement | null = null;

document.addEventListener(
  'invalid',
  (event) => {
    const input = event.target;
    if (!isFormInputElement(input)) return;
    if (!input.form?.hasAttribute('data-dsfr-validation')) return;

    event.preventDefault();
    toggleDsfrError(input);

    // focus the first invalid input of the validation run
    if (dsfrInvalidForm != input.form) {
      dsfrInvalidForm = input.form;
      queueMicrotask(() => (dsfrInvalidForm = null));
      input.focus();
    }
  },
  true // `invalid` does not bubble
);

delegate(
  'input change',
  'form[data-dsfr-validation] .fr-input--error',
  ({ target }) => {
    if (isFormInputElement(target)) {
      toggleDsfrError(target);
    }
  }
);

function toggleDsfrError(
  input: HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement
) {
  const group = input.closest('.fr-input-group');
  const error = document.getElementById(`${input.id}-error`);
  const invalid = !input.validity.valid;

  group?.classList.toggle('fr-input-group--error', invalid);
  input.classList.toggle('fr-input--error', invalid);
  error?.classList.toggle('hidden', !invalid);
}
