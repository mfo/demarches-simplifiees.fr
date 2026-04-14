import { ApplicationController } from './application_controller';
import { httpRequest } from '@utils';

declare const window: Window &
  typeof globalThis & {
    dsfr?: (el: HTMLElement) => { modal: { disclose: () => void } };
  };

export default class extends ApplicationController {
  static targets = ['modal'];
  declare readonly modalTarget: HTMLElement;
  declare readonly hasModalTarget: boolean;

  private abortController?: AbortController;

  connect(): void {
    if (this.hasModalTarget) {
      this.abortController = new AbortController();
      const { signal } = this.abortController;
      this.modalTarget.addEventListener('dsfr.conceal', this.onConceal, {
        signal
      });
    }
  }

  disconnect(): void {
    this.abortController?.abort();
  }

  openWithIds(event: CustomEvent): void {
    const ids: string[] = event.detail?.ids ?? [];
    this.modalTarget.dataset.dossierIds = ids.join(',');

    this.waitForDsfrAndDisclose();
  }

  addBatchIdsToUrl(event: Event): void {
    const dossierIds = this.modalTarget.dataset.dossierIds;
    if (!dossierIds) return;

    const link = event.currentTarget as HTMLAnchorElement;
    const url = new URL(link.href);
    url.searchParams.delete('dossier_ids[]');
    dossierIds
      .split(',')
      .filter(Boolean)
      .forEach((id) => url.searchParams.append('dossier_ids[]', id));
    link.href = url.toString();
  }

  private onConceal = (): void => {
    this.reset();
  };

  private reset = async (): Promise<void> => {
    const resetUrl = (this.element as HTMLElement).dataset.resetUrl;
    if (!resetUrl) return;
    await httpRequest(resetUrl, { method: 'POST' }).turbo();
  };

  private waitForDsfrAndDisclose(): void {
    if (
      window.dsfr &&
      this.modalTarget.getAttribute('data-fr-js-modal') === 'true'
    ) {
      window.dsfr(this.modalTarget).modal.disclose();
    } else {
      requestAnimationFrame(() => this.waitForDsfrAndDisclose());
    }
  }
}
