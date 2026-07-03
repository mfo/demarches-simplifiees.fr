import { useRef, type RefObject } from 'react';
import { flushSync } from 'react-dom';
import { useLingui } from '@lingui/react/macro';

import type { Item } from '../props';

export function TagGroup({
  items,
  onRemove,
  fallbackFocusRef,
  className,
  'aria-label': ariaLabel
}: {
  items: Item[];
  onRemove: (value: string) => void;
  fallbackFocusRef: RefObject<HTMLElement | null>;
  className?: string;
  'aria-label'?: string;
}) {
  const tagListRef = useRef<HTMLUListElement>(null);
  const { t } = useLingui();

  if (items.length === 0) return null;

  return (
    <ul
      ref={tagListRef}
      className={className ?? 'fr-tag-list'}
      aria-label={ariaLabel}
    >
      {items.map((item, index) => (
        <li key={item.value}>
          <button
            type="button"
            className="fr-tag fr-tag--sm fr-tag--dismiss"
            aria-label={t`Supprimer ${item.label}`}
            onClick={() => {
              flushSync(() => {
                onRemove(item.value);
              });
              const buttons =
                tagListRef.current?.querySelectorAll<HTMLButtonElement>(
                  'button.fr-tag--dismiss'
                );
              if (buttons && buttons.length > 0) {
                buttons[Math.min(index, buttons.length - 1)].focus();
              } else {
                fallbackFocusRef.current?.focus();
              }
            }}
          >
            {item.label}
          </button>
        </li>
      ))}
    </ul>
  );
}
