import { Controller } from '@hotwired/stimulus';
import debounce from 'debounce';
import invariant from 'tiny-invariant';

export type Detail = Record<string, unknown>;

// see: https://www.quirksmode.org/blog/archives/2008/04/delegating_the.html
const FOCUS_EVENTS = ['focus', 'blur'];
const ACTIVE_EVENTS = ['wheel'];

export class ApplicationController extends Controller {
  #debounced = new Map<() => void, ReturnType<typeof debounce>>();
  #listeners: {
    target: EventTarget;
    eventName: string;
    callback: EventListener;
    options: AddEventListenerOptions;
  }[] = [];

  // Subclasses overriding disconnect() must call super.disconnect().
  disconnect(): void {
    for (const { target, eventName, callback, options } of this.#listeners) {
      target.removeEventListener(eventName, callback, options);
    }
    this.#listeners = [];
    this.#cancelAllDebounced();
  }

  protected debounce(fn: () => void, interval: number): void {
    this.globalDispatch('debounced:added');

    let debounced = this.#debounced.get(fn);
    if (!debounced) {
      const wrapper = () => {
        fn.bind(this)();
        this.#deleteDebounced(fn);
      };

      debounced = debounce(wrapper, interval);

      this.#debounced.set(fn, debounced);
    }
    debounced();
  }

  protected cancelDebounce(fn: () => void) {
    const debounced = this.#debounced.get(fn);
    if (debounced) {
      debounced.clear();
      this.#deleteDebounced(fn);
    }
  }

  #deleteDebounced(fn: () => void) {
    this.#debounced.delete(fn);
    if (this.#debounced.size == 0) {
      this.globalDispatch('debounced:empty');
    }
  }

  #cancelAllDebounced() {
    if (this.#debounced.size == 0) {
      return;
    }
    for (const debounced of this.#debounced.values()) {
      debounced.clear();
    }
    this.#debounced.clear();
    this.globalDispatch('debounced:empty');
  }

  protected globalDispatch<T = Detail>(type: string, detail?: T): void {
    this.dispatch(type, {
      detail: detail as object,
      prefix: '',
      target: document.documentElement
    });
  }

  protected on<HandlerEvent extends Event = Event>(
    target: EventTarget,
    eventName: string,
    handler: (event: HandlerEvent) => void
  ): void;
  protected on<HandlerEvent extends Event = Event>(
    eventName: string,
    handler: (event: HandlerEvent) => void
  ): void;
  protected on<HandlerEvent extends Event = Event>(
    targetOrEventName: EventTarget | string,
    eventNameOrHandler: string | ((event: HandlerEvent) => void),
    handler?: (event: HandlerEvent) => void
  ): void {
    if (typeof targetOrEventName == 'string') {
      invariant(typeof eventNameOrHandler != 'string', 'handler is required');
      this.onTarget(this.element, targetOrEventName, eventNameOrHandler);
    } else {
      invariant(
        typeof eventNameOrHandler == 'string',
        'event name is required'
      );
      invariant(handler, 'handler is required');
      this.onTarget(targetOrEventName, eventNameOrHandler, handler);
    }
  }

  protected onGlobal<HandlerEvent extends Event = Event>(
    eventName: string,
    handler: (event: HandlerEvent) => void
  ): void {
    this.onTarget(document.documentElement, eventName, handler);
  }

  private onTarget<HandlerEvent extends Event = Event>(
    target: EventTarget,
    eventName: string,
    handler: (event: HandlerEvent) => void
  ): void {
    const callback = (event: Event): void => {
      handler(event as HandlerEvent);
    };
    const options = {
      capture: FOCUS_EVENTS.includes(eventName),
      passive: ACTIVE_EVENTS.includes(eventName) ? false : undefined
    };
    target.addEventListener(eventName, callback, options);
    this.#listeners.push({ target, eventName, callback, options });
  }
}
