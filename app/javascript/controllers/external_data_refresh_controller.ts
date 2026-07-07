import { ApplicationController } from './application_controller';

export class ExternalDataRefreshController extends ApplicationController {
  static targets = ['refreshDataInput', 'refreshButton'];

  declare readonly refreshDataInputTarget: HTMLInputElement;
  declare readonly refreshButtonTarget: HTMLButtonElement;

  connect() {
    this.onGlobal('autosave:error', () => this.reset());
  }

  trigger() {
    this.refreshButtonTarget.disabled = true;
    this.refreshDataInputTarget.value = '1';
    this.refreshDataInputTarget.dispatchEvent(
      new Event('change', { bubbles: true })
    );
  }

  private reset() {
    this.refreshDataInputTarget.value = '';
    this.refreshButtonTarget.disabled = false;
  }
}
