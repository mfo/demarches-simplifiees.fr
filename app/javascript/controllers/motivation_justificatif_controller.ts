import { ApplicationController } from './application_controller';
import { show, hide } from '@utils';

// Optional justificatif attached to a motivation form: a button reveals the
// file input, selecting a file reveals a delete button which clears the input.
export class MotivationJustificatifController extends ApplicationController {
  static targets = ['suggest', 'import', 'input', 'delete'];
  declare readonly suggestTarget: HTMLElement;
  declare readonly importTarget: HTMLElement;
  declare readonly inputTarget: HTMLInputElement;
  declare readonly deleteTarget: HTMLElement;

  connect() {
    const form =
      this.element.closest('form') ?? this.element.querySelector('form');
    if (form) {
      this.on(form, 'reset', () => hide(this.deleteTarget));
    }
  }

  showImport() {
    show(this.importTarget);
    hide(this.suggestTarget);
  }

  fileSelected() {
    if (this.inputTarget.value != '') {
      show(this.deleteTarget);
    }
  }

  delete() {
    this.inputTarget.value = '';
    hide(this.deleteTarget);
  }
}
