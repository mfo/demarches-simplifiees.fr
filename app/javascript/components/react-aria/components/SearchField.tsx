'use client';
import {
  Button,
  Input,
  SearchField as AriaSearchField,
  type SearchFieldProps as AriaSearchFieldProps
} from 'react-aria-components';
import './SearchField.css';

export interface SearchFieldProps extends AriaSearchFieldProps {
  placeholder?: string;
}

export function SearchField({ placeholder, ...props }: SearchFieldProps) {
  return (
    <AriaSearchField {...props}>
      <span className="fr-icon-search-line fr-icon--sm" aria-hidden="true" />
      <Input placeholder={placeholder} className="react-aria-Input fr-input" />
      <Button className="clear-button">
        <span className="fr-icon-close-line fr-icon--xs" aria-hidden="true" />
      </Button>
    </AriaSearchField>
  );
}
