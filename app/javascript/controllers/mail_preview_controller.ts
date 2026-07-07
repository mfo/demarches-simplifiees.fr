import { ApplicationController } from './application_controller';

// Slack added to the measured email height: `scrollHeight` is rounded to an integer,
// so without a small margin the last row of the email would be clipped by the iframe's
// hidden overflow.
const HEIGHT_SLACK = 4;

// Natural width of the mailer document: 620px of content + 16px of body margins.
// Keep in sync with the .mail-preview-frame width in mail_template_edit.scss.
const EMAIL_WIDTH = 636;

// Manages the email preview iframe.
//
// - Fit: shrinks the fixed-width mailer document (620px content + 16px body margins =
//   636px) to the column width via CSS `zoom` (exposed as `--mail-preview-scale`), so
//   the email fills the width, its thin borders stay crisp, and — since `zoom` scales
//   layout — the card sizes to the zoomed email on its own.
// - Height: sizes the iframe to the email's own content height and hides its inner
//   scrollbars, so it shows the whole email and the card (not the iframe) owns the
//   vertical scroll — no double scrollbar.
// - Double buffering: a live preview update appends a new iframe. It is loaded
//   off-screen and only revealed — replacing the previous one — once fully loaded,
//   so the visible preview never flashes (no blank, font swap or logo reflow).
export class MailPreviewController extends ApplicationController {
  static targets = ['frame'];

  declare readonly frameTargets: HTMLIFrameElement[];

  #resizeObserver?: ResizeObserver;
  #lastWidth = 0;

  connect(): void {
    this.#resizeObserver = new ResizeObserver(() => this.#fit());
    this.#resizeObserver.observe(this.element);
  }

  disconnect(): void {
    this.#resizeObserver?.disconnect();
  }

  frameTargetConnected(frame: HTMLIFrameElement): void {
    // The first frame is the one rendered in the page; later ones come from a
    // live-preview update and load off-screen before replacing it.
    if (this.frameTargets.length === 1) {
      this.#whenLoaded(frame, () => this.#onFrameLoad(frame));
      return;
    }

    frame.classList.add('mail-preview-frame--pending');
    this.#whenLoaded(frame, () => {
      // A newer update may already be pending; let it win.
      if (frame === this.frameTargets[this.frameTargets.length - 1]) {
        this.#promote(frame);
      } else {
        frame.remove();
      }
    });
  }

  // Runs `cb` once the iframe has loaded — right away if it is already loaded. On a
  // Turbo navigation the iframe can finish loading (cached preview) before Stimulus
  // attaches the listener, so a plain `load` handler would miss the event and the
  // preview would never be measured.
  #whenLoaded(frame: HTMLIFrameElement, cb: () => void): void {
    if (this.#isLoaded(frame)) {
      cb();
    } else {
      frame.addEventListener('load', cb, { once: true });
    }
  }

  #isLoaded(frame: HTMLIFrameElement): boolean {
    try {
      const doc = frame.contentDocument;
      // A blank/pending document has an empty body; the real email doesn't.
      return (
        doc?.readyState === 'complete' && (doc.body?.childElementCount ?? 0) > 0
      );
    } catch {
      return false;
    }
  }

  #promote(frame: HTMLIFrameElement): void {
    for (const other of this.frameTargets) {
      if (other !== frame) other.remove();
    }
    frame.classList.remove('mail-preview-frame--pending');
    this.#onFrameLoad(frame);
  }

  #onFrameLoad(frame: HTMLIFrameElement): void {
    this.#hideInnerScrollbars(frame);
    this.#measure(frame);
  }

  #hideInnerScrollbars(frame: HTMLIFrameElement): void {
    try {
      const html = frame.contentDocument?.documentElement;
      if (html) html.style.overflow = 'hidden';
    } catch {
      // iframe not same-origin accessible yet
    }
  }

  #measure(frame: HTMLIFrameElement): void {
    const doc = frame.contentDocument;
    if (!doc) return;

    const apply = () => {
      frame.style.height = `${doc.documentElement.scrollHeight + HEIGHT_SLACK}px`;
    };
    apply();
    // The web-font swap can grow the content after this first measure; re-apply once
    // the iframe's fonts are ready so the email isn't clipped.
    doc.fonts?.ready.then(apply).catch(() => {});
  }

  #fit(): void {
    // Use `offsetWidth` (the full box, scrollbar included), not `clientWidth`: it
    // stays constant whether the vertical scrollbar is showing or not, so the zoom
    // never oscillates — no need to reserve a scrollbar gutter.
    const available = (this.element as HTMLElement).offsetWidth;
    if (available === this.#lastWidth) return;
    this.#lastWidth = available;

    const scale = Math.max(0.05, Math.min(1, available / EMAIL_WIDTH));
    (this.element as HTMLElement).style.setProperty(
      '--mail-preview-scale',
      String(scale)
    );
  }
}
