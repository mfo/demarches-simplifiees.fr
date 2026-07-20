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
