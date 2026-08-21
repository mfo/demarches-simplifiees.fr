import { fileURLToPath } from 'node:url';

import { playwright } from '@vitest/browser-playwright';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  // `vite.config.ts` declares this alias relative to vite-plugin-ruby's root,
  // and vitest does not load that config. Without it the dependency scan throws
  // on the first test that reaches `@utils`, vite then skips pre-bundling
  // altogether, and unrelated React tests get a null `react` module.
  resolve: {
    alias: {
      '@utils': fileURLToPath(
        new URL('./app/javascript/shared/utils.ts', import.meta.url)
      )
    }
  },
  test: {
    globals: true,
    browser: {
      enabled: true,
      provider: playwright(),
      headless: true,
      // Les fichiers de test partagent la même page (une iframe chacun) alors
      // que la souris et le clavier Playwright sont globaux à la page : deux
      // tests interactifs simultanés se volent le focus et ferment mutuellement
      // leurs popovers (SelectSections / ComboBoxSections).
      fileParallelism: false,
      instances: [
        { browser: 'chromium' },
        { browser: 'firefox' },
        { browser: 'webkit' }
      ]
    }
  }
});
