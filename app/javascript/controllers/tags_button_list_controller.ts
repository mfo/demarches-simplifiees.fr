import { ApplicationController } from './application_controller';

// Reveals/hides the optional & conditional tag buttons of one category when its
// "voir les champs facultatifs" checkbox is toggled.
export class TagsButtonListController extends ApplicationController {
  static targets = ['hint', 'optionalItem'];

  declare readonly hintTargets: HTMLElement[];
  declare readonly optionalItemTargets: HTMLElement[];

  toggleOptional(event: Event) {
    const visible = (event.target as HTMLInputElement).checked;

    for (const hint of this.hintTargets) {
      hint.classList.toggle('hidden', !visible);
    }
    for (const item of this.optionalItemTargets) {
      item.classList.toggle('hidden', !visible);
    }
  }
}
