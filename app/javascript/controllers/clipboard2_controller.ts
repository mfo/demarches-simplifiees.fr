/**
 * Usage:
 * 1. Add `{ "data-controller": "clipboard2" }` to a parent container
 * 2. Mark copyable elements with `.copy-zone`
 * 3. Optionally use `data-to-copy` attribute to specify exact text to copy
 * 4. Optionally use `.copy-zone{ 'data-to-copy': 'coucou' }` to copy specific text
 * 5. Optionally use `data-copy-message-placeholder` to control message placement
 * 6. Optionally use `data-copy-text` / `data-copied-text` on a `.copy-zone` to override the default badge texts
 */
import { Controller } from '@hotwired/stimulus';

export class Clipboard2Controller extends Controller {
  static values = {
    copyText: String,
    copiedText: String,
    copyIconClassName: { type: String, default: 'fr-icon-clipboard-line' }
  };

  declare readonly copyTextValue: string;
  declare readonly copyIconClassNameValue: string;
  declare readonly copiedTextValue: string;

  connect(): void {
    if (!navigator.clipboard) {
      return;
    }

    this.setupChampHoverListeners();
  }

  private setupChampHoverListeners(): void {
    [...this.element.querySelectorAll<HTMLElement>('.copy-zone')]
      // cannot use innerText because of possible hidden/folded elements
      .filter(
        (wrapper) =>
          wrapper.textContent?.trim() !== '' ||
          wrapper.querySelector('.copy-zone-trigger-icon')
      )
      .forEach((wrapper) => {
        const button = this.createButton();
        this.insertButton(wrapper, button);

        button.addEventListener('focus', () => {
          this.setCopyState(button);
        });

        wrapper.addEventListener('mouseenter', () => {
          this.setCopyState(button);
        });

        wrapper.addEventListener('click', (e) => {
          // if one click on a link, we do not copy and follow the link instead
          const target = e.target as HTMLElement;
          if (target.tagName === 'A' || target.closest('a')) {
            return;
          }

          e.preventDefault();
          e.stopPropagation();
          this.copyContent(wrapper);
        });
      });
  }

  private copyContent(wrapper: HTMLElement): void {
    const button = wrapper.querySelector<HTMLButtonElement>('button.copy-btn');

    const textToCopy = (
      wrapper.dataset['toCopy'] ||
      wrapper.querySelector<HTMLElement>('[data-to-copy]')?.innerText ||
      this.getTextWithoutElement(wrapper, button)
    ).trim();

    if (document.hasFocus() && textToCopy) {
      navigator.clipboard
        .writeText(textToCopy)
        .then(() => {
          if (button) {
            this.setCopiedState(button);
          }
        })
        .catch(() => {
          // Intentional no-op. writeText() can reject when the browser refuses
          // to honor the gesture (synthetic click, focus loss, permission).
          // The badge stays in "Copy" state, so the user simply retries.
        });
    }
  }

  private getTextWithoutElement(
    wrapper: HTMLElement,
    exclude: Element | null
  ): string {
    if (!exclude) {
      return wrapper.innerText;
    }

    const clone = wrapper.cloneNode(true) as HTMLElement;
    clone.querySelector('button.copy-btn')?.remove();
    return clone.innerText;
  }

  private insertButton(wrapper: HTMLElement, button: HTMLButtonElement): void {
    const placeholder = wrapper.querySelector<HTMLElement>(
      '[data-copy-message-placeholder]'
    );

    if (placeholder) {
      placeholder.appendChild(button);
      return;
    }

    const lastChild = wrapper.lastElementChild;

    if (lastChild && lastChild.tagName !== 'BR') {
      lastChild.appendChild(button);
    } else {
      wrapper.appendChild(button);
    }
  }

  private createButton(): HTMLButtonElement {
    const button = document.createElement('button');
    button.setAttribute('type', 'button');
    button.setAttribute('aria-live', 'polite');
    button.setAttribute('aria-atomic', 'true');
    button.classList.add(
      'fr-ml-1v',
      'fr-badge',
      'fr-badge--sm',
      'fr-badge--blue-cumulus',
      'fr-badge--icon-left',
      'copy-btn'
    );
    this.setCopyState(button);
    return button;
  }

  private setCopyState(button: HTMLButtonElement): void {
    button.textContent = this.copyTextValue;
    button.classList.add(this.copyIconClassNameValue);
    button.classList.remove('fr-icon-check-line');
  }

  private setCopiedState(button: HTMLButtonElement): void {
    button.textContent = this.copiedTextValue;
    button.classList.remove(this.copyIconClassNameValue);
    button.classList.add('fr-icon-check-line');
  }
}
