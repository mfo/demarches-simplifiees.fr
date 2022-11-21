import { httpRequest } from '@utils';
import { ApplicationController } from './application_controller';

export class BatchOperationController extends ApplicationController {
  static targets = ['input', 'all']

  declare readonly allTarget: HTMLInputElement;
  declare readonly inputTargets: HTMLInputElement[];

  connect() {
  }

  onCheckAll(event) {
    this.inputTargets.forEach((e) => e.checked = event.target.checked)
  }
  onSelectOperation() {
    const element = this.element as HTMLFormElement;

    this.element.submit();
  }
}
