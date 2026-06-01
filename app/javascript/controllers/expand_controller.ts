import { ApplicationController } from './application_controller';
import { toggle, toggleExpandIcon } from '@utils';

export class ExpandController extends ApplicationController {
  static targets = ['content', 'icon'];

  declare readonly contentTarget: HTMLElement;
  declare readonly iconTarget: HTMLElement;

  toggle(event: Event) {
    event.preventDefault();
    toggle(this.contentTarget);
    toggleExpandIcon(this.iconTarget);

    const expanded = !this.contentTarget.classList.contains('hidden');
    const ariaTarget =
      this.element.querySelector('[aria-expanded]') ??
      (event.currentTarget as HTMLElement);
    ariaTarget.setAttribute('aria-expanded', String(expanded));
  }
}
