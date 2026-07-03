import {
  Select as AriaSelect,
  Autocomplete,
  SelectValue,
  Button,
  Popover,
  Virtualizer,
  ListLayout,
  useFilter
} from 'react-aria-components';
import type {
  SelectProps as AriaSelectProps,
  AutocompleteProps
} from 'react-aria-components';
import { useState, useMemo, useRef, useCallback, type Key } from 'react';
import { flushSync } from 'react-dom';
import * as s from 'superstruct';
import { Plural } from '@lingui/react/macro';

import './react-aria/components/Select.css';
import { SearchField } from './react-aria/components/SearchField';
import {
  DropdownListBox as SelectListBox,
  DropdownItem as SelectItem
} from './react-aria/components/ListBox';
import {
  type Item,
  SingleSelectProps,
  MultipleSelectProps
} from './react-aria/props';
import { TagGroup } from './react-aria/components/TagGroup';

type SelectionMode = 'single' | 'multiple';
type SelectProps<M extends SelectionMode = 'single'> = AriaSelectProps<
  Item,
  M
> & {
  items: Item[];
  value: M extends 'single' ? string | null : string[];
  labelId?: string;
  ariaLabelledbyPrefix?: string;
  alwaysShowKey?: string;
};
type AutocompleteFilter = NonNullable<AutocompleteProps<Item>['filter']>;

function Select<M extends SelectionMode = 'single'>({
  items,
  labelId,
  ariaLabelledbyPrefix,
  alwaysShowKey,
  ...props
}: SelectProps<M>) {
  const { contains } = useFilter({ sensitivity: 'base', numeric: true });
  const filter = useCallback<AutocompleteFilter>(
    (textValue, inputValue, node) => {
      if (alwaysShowKey && node.value?.value == alwaysShowKey) {
        return true;
      }
      return contains(textValue, inputValue);
    },
    [contains, alwaysShowKey]
  );

  if (!props['aria-label'] && labelId && ariaLabelledbyPrefix) {
    props['aria-labelledby'] = `${ariaLabelledbyPrefix} ${labelId}`;
  }

  return (
    <AriaSelect {...props}>
      {props.selectionMode == 'single' ? (
        <Button className="fr-select">
          <SelectValue />
        </Button>
      ) : (
        <MultipleSelectValue />
      )}
      <Popover
        className="react-aria-Popover select-popover"
        style={{ display: 'flex', flexDirection: 'column' }}
      >
        <Autocomplete<Item> filter={filter}>
          <SearchField autoFocus style={{ margin: 4 }} />
          <Virtualizer layout={ListLayout}>
            <SelectListBox items={items}>
              {(item) => <SelectItem id={item.value}>{item.label}</SelectItem>}
            </SelectListBox>
          </Virtualizer>
        </Autocomplete>
      </Popover>
    </AriaSelect>
  );
}

function MultipleSelectValue() {
  const selectButtonRef = useRef<HTMLButtonElement>(null);
  return (
    <SelectValue<Item>>
      {({ selectedItems, state, defaultChildren }) => (
        <>
          <Button className="fr-select" ref={selectButtonRef}>
            <span className="react-aria-SelectValue" data-placeholder>
              <Plural
                value={selectedItems.length}
                _0={defaultChildren}
                one="1 choix sélectionné"
                other="# choix sélectionnés"
              />
            </span>
          </Button>
          <TagGroup
            items={selectedItems.filter((item) => item != null)}
            onRemove={(value) => {
              if (Array.isArray(state.value)) {
                state.setValue(state.value.filter((k) => k !== value));
              }
            }}
            fallbackFocusRef={selectButtonRef}
            aria-label="Sélection"
          />
        </>
      )}
    </SelectValue>
  );
}

export function SingleSelect(maybeProps: SelectProps<'single'>) {
  const {
    value: initialValue,
    className,
    ...props
  } = useMemo(() => s.create(maybeProps, SingleSelectProps), [maybeProps]);
  const [value, setValue] = useState<string | null>(() => initialValue);
  const changeDispatchRef = useRef<HTMLInputElement>(null);

  const dispatchChange = () => {
    changeDispatchRef.current?.dispatchEvent(
      new Event('change', { bubbles: true })
    );
  };

  const onChange = (key: Key | null) => {
    flushSync(() => {
      setValue(key ? String(key) : null);
    });
    dispatchChange();
  };

  return (
    <>
      <Select
        className={`fr-ds-select_single react-aria-Select ${className ?? ''}`}
        selectionMode="single"
        value={value}
        onChange={onChange}
        {...props}
      />
      <input ref={changeDispatchRef} type="hidden" />
    </>
  );
}

export function MultipleSelect(maybeProps: SelectProps<'multiple'>) {
  const {
    value: initialValue,
    className,
    name,
    ...props
  } = useMemo(() => s.create(maybeProps, MultipleSelectProps), [maybeProps]);
  const [value, setValue] = useState<string[]>(() => initialValue);
  const changeDispatchRef = useRef<HTMLInputElement>(null);

  const dispatchChange = () => {
    changeDispatchRef.current?.dispatchEvent(
      new Event('change', { bubbles: true })
    );
  };

  const onChange = (keys: Key[]) => {
    flushSync(() => {
      setValue(keys.map(String));
    });
    dispatchChange();
  };

  // `name` is destructured out above so the `{...props}` spread no longer carries
  // it into <Select>. Otherwise react-aria's hidden <select multiple> picks up the
  // name and the browser submits its selected options in DOM (collection) order —
  // losing the user's selection order. The explicit hidden inputs below carry the
  // form value in selection order instead.
  return (
    <>
      <Select
        className={`fr-ds-select_multiple react-aria-Select ${className ?? ''}`}
        selectionMode="multiple"
        value={value}
        onChange={onChange}
        {...props}
      />
      {value.length === 0 ? (
        <input ref={changeDispatchRef} type="hidden" name={name} value="" />
      ) : (
        value.map((v, i) => (
          <input
            key={v}
            ref={i === 0 ? changeDispatchRef : undefined}
            type="hidden"
            name={name}
            value={v}
          />
        ))
      )}
    </>
  );
}
