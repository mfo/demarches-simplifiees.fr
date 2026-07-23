import './process-env-shim';
import { vi, suite, test, expect, beforeEach, afterEach } from 'vitest';
import { userEvent, page } from '@vitest/browser/context';
import { createRoot, type Root } from 'react-dom/client';
import { MultipleSelect } from './Select';

vi.mock('@lingui/react/macro', () => ({
  useLingui: () => ({ t: (s: TemplateStringsArray | string) => String(s) }),
  Trans: ({ children }: { children: React.ReactNode }) => children,
  Plural: ({ _0, value }: { _0: React.ReactNode; value: number }) =>
    value === 0 ? _0 : `${value} choix sélectionnés`
}));

const sections = [
  {
    label: 'Identité',
    items: [{ label: 'Nom', value: 'nom', mandatory: true }]
  },
  {
    label: 'Adresse',
    items: [{ label: 'Domicile', value: 'domicile' }]
  }
];

suite('MultipleSelect with sections', () => {
  let container: HTMLDivElement;
  let root: Root;

  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
  });

  afterEach(() => {
    root.unmount();
    container.remove();
  });

  test('renders section headers and a mandatory asterisk', async () => {
    root.render(
      <MultipleSelect
        name="champs[]"
        sections={sections}
        value={[]}
        aria-label="Champs"
      />
    );

    await userEvent.click(page.getByRole('button'));

    await expect.element(page.getByText('Identité')).toBeInTheDocument();
    await expect.element(page.getByText('Adresse')).toBeInTheDocument();
    await expect
      .element(page.getByRole('option', { name: 'Nom *' }))
      .toBeInTheDocument();
    await expect
      .element(page.getByRole('option', { name: 'Domicile' }))
      .toBeInTheDocument();
  });

  test('shows emptyHint when nothing is selected and tags once a field is picked', async () => {
    root.render(
      <MultipleSelect
        name="champs[]"
        sections={sections}
        value={[]}
        aria-label="Champs"
        emptyHint="Affichage non personnalisé"
      />
    );

    await expect
      .element(page.getByText('Affichage non personnalisé'))
      .toBeInTheDocument();

    await userEvent.click(page.getByRole('button'));
    await userEvent.click(page.getByRole('option', { name: 'Domicile' }));

    await expect
      .element(page.getByText('Affichage non personnalisé'))
      .not.toBeInTheDocument();
    await expect
      .element(
        page.getByRole('list', { name: 'Sélection' }).getByText('Domicile')
      )
      .toBeInTheDocument();
  });
});
