import type {
  ErrorEvent,
  EventHint,
  Exception,
  StackFrame
} from '@sentry/browser';
import { ResponseError } from '@utils';

// Our own code is always served from Vite's asset directory. Anything thrown
// from elsewhere (browser extensions, scripts injected by in-app browsers,
// proxies or bookmarklets, inline scripts of a page saved to disk…) is not
// something we can fix.
const BUNDLE_FILENAME = /\/vite\/assets\/[^/?#]+\.js(?:[?#]|$)/;

// Filenames the browser reports when it has no real location to give.
const OPAQUE_FILENAMES = new Set([
  '',
  '<anonymous>',
  '[native code]',
  'undefined'
]);

// Failures to load one of our own chunks are worth knowing about even though
// the browser reports them without a usable stacktrace: a spike right after a
// deploy points at a CDN or cache problem on our side.
const MODULE_LOAD_ERRORS = [
  /Importing a module script failed/,
  /dynamically imported module/
];

// Errors thrown by DSFR, Turbo, React… are ours: those libraries are bundled
// into our assets, so their frames match BUNDLE_FILENAME too.
export function isFromOurBundle(exception: Exception | undefined): boolean {
  const frame = originFrame(exception);
  return frame != null && BUNDLE_FILENAME.test(frame.filename ?? '');
}

// Sentry orders frames from outermost to innermost, so the throw site is the
// last frame carrying a real filename. Wrappers such as Sentry's own timer
// instrumentation sit in outer frames and must not count.
function originFrame(exception: Exception | undefined): StackFrame | undefined {
  const frames = exception?.stacktrace?.frames ?? [];
  for (let i = frames.length - 1; i >= 0; i--) {
    const filename = frames[i].filename ?? '';
    if (!OPAQUE_FILENAMES.has(filename)) {
      return frames[i];
    }
  }
  return undefined;
}

function isModuleLoadError(exception: Exception | undefined): boolean {
  const value = exception?.value ?? '';
  return MODULE_LOAD_ERRORS.some((re) => re.test(value));
}

// A request that never reached us, or that we answered with a 5xx, is an
// availability problem: the server side is already reported by the Rails
// project, and the client side has nothing to fix. Errors our own code asked
// Sentry to capture (e.g. autosave failures shown to the user with an event
// id) are not concerned: only unhandled rejections are dropped.
function isAvailabilityError(error: unknown): boolean {
  return (
    error instanceof ResponseError &&
    (error.isNetworkError || error.response.status >= 500)
  );
}

export function shouldDropEvent(event: ErrorEvent, hint: EventHint): boolean {
  const exception = event.exception?.values?.at(-1);
  if (exception?.mechanism?.handled !== false) {
    return false;
  }
  if (isAvailabilityError(hint.originalException)) {
    return true;
  }
  if (isModuleLoadError(exception)) {
    return false;
  }
  return !isFromOurBundle(exception);
}
