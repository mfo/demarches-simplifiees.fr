import { ApplicationController } from './application_controller';

declare const window: Window &
  typeof globalThis & {
    dsfr?: (el: HTMLElement) => { modal: { disclose: () => void } };
  };

export default class AutoOpenModalController extends ApplicationController {
  connect(): void {
    // Wait for DSFR to initialize the modal (indicated by data-fr-js-modal attribute)
    this.waitForDsfrAndDisclose();
  }

  private waitForDsfrAndDisclose(): void {
    if (
      window.dsfr &&
      this.element.getAttribute('data-fr-js-modal') === 'true'
    ) {
      window.dsfr(this.element as HTMLElement).modal.disclose();
    } else {
      requestAnimationFrame(() => this.waitForDsfrAndDisclose());
    }
  }
}
