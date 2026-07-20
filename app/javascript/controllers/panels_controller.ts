import { ApplicationController } from './application_controller';
import { toggle, hide } from '@utils';

// Reveals one named panel and hides the others. Panels are targets marked
// with a `data-panels-name` attribute; actions select them by the `name`
// action param.
//
//   <div data-controller="panels">
//     <a href="#" data-action="panels#show" data-panels-name-param="foo">Foo</a>
//     <div class="hidden" data-panels-target="panel" data-panels-name="foo">…</div>
//   </div>
export class PanelsController extends ApplicationController {
  static targets = ['panel'];
  declare readonly panelTargets: HTMLElement[];

  show(event: Event & { params: { name: string } }) {
    if (event.currentTarget instanceof HTMLAnchorElement) {
      event.preventDefault();
    }
    for (const panel of this.panelTargets) {
      toggle(panel, panel.dataset.panelsName == event.params.name);
    }
  }

  hideAll() {
    this.panelTargets.forEach(hide);
  }
}
