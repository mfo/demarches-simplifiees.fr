import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } };
  declare delayValue: number;

  connect() {
    setTimeout(() => this.element.remove(), this.delayValue);
  }
}
