// Shim pour les tests vitest en mode browser : react-aria référence
// `process.env.NODE_ENV` (non défini dans le navigateur). Importé en premier
// pour s'exécuter avant le chargement des dépendances react-aria.
const g = globalThis as unknown as {
  process?: { env: Record<string, string> };
};
g.process ??= { env: {} };
g.process.env ??= {};
g.process.env.NODE_ENV ??= 'development';
