# Migration API Entreprise v4 et résilience

## Contexte

Bug remonté par le ministère de la Culture (mail de Corentin, mai 2026) : des établissements en base avec données partielles (entreprise_siren NULL).

Investigation : depuis des années, les erreurs 429 (rate limit) de l'API Entreprise étaient traitées comme des 404 (SIRET introuvable). L'adapter mappait tous les codes 4xx sur une même exception `ResourceNotFound`. Conséquence : perte silencieuse de données, pas de retry, pas de Sentry. ~13k établissements corrompus identifiés.

Ce bug a révélé trois problèmes structurels :
1. La gestion d'erreur par exceptions masquait la sémantique HTTP
2. L'appel à `EntrepriseAdapter` (2e requête) était un vestige inutile depuis la v3
3. Aucune coordination de rate limiting entre les workers Sidekiq

## Décisions

On traite les trois problèmes structurels avec quatre briques complémentaires : gestion d'erreur explicite (Dry::Monads), migration vers l'API v4 avec coexistence des nomenclatures NAF, rate limiting server-driven par pool, et circuit breaker par provider.

### Gestion d'erreur explicite avec Dry::Monads [#13101](https://github.com/demarche-numerique/demarche.numerique.gouv.fr/pull/13101)

**Choix** : remplacer la hiérarchie d'exceptions (7 classes) par des `Dry::Monads` Result types avec pattern matching. C'est aussi la direction actuelle du projet que de passer les appels d'API via des `Dry::Monads`.

**Pourquoi** : les exceptions aplatissaient la sémantique — 429, 451, 404 devenaient tous `ResourceNotFound`. Avec les monads, chaque appelant doit gérer chaque cas explicitement (`type:`, `retryable:`, `code:`).

**Alternative rejetée** : conserver les exceptions mais avec une hiérarchie plus fine (ex. `RateLimitError < RetryableError`). Rejeté car les exceptions restent faciles à ignorer (un `rescue` trop large et on retombe dans le même piège). Les monads forcent le pattern matching exhaustif.

### Migration v3→v4 de l'endpoint INSEE établissements [#13177](https://github.com/demarche-numerique/demarche.numerique.gouv.fr/pull/13177)

**Choix** : migrer de v3/insee/etablissements vers v4/insee/sirene/etablissements. On en a profité pour supprimer `EntrepriseAdapter` et `EntrepriseJob` (2e appel API pour les données unité légale). C'était de la dette technique : les données unité légale étaient déjà incluses dans la réponse établissement depuis la v3, mais on n'avait jamais supprimé le 2e appel.

**Pourquoi** : l'endpoint v3 était déprécié (sera maintenu tant que les fournisseurs de données répondent). Le 2e appel brûlait du rate limit pour rien à chaque création d'établissement.

### Coexistence NAF Rev2 / NAF 2025 [#13179](https://github.com/demarche-numerique/demarche.numerique.gouv.fr/pull/13179)

Le [breaking change v3→v4](https://entreprise.api.gouv.fr/catalogue/insee/etablissements#historique) concerne la grappe `activite_principale` :

```json
// v3 — NAF Rev2 uniquement
{
    "activite_principale": {
        "code": "8411Z",
        "libelle": "Administration publique générale",
        "nomenclature": "NAFRev2"
    }
}

// v4 — NAF 2025 par défaut, Rev2 déplacée
{
    "activite_principale": {
        "code": "84.11",
        "libelle": "Administration publique générale",
        "nomenclature": "NAFRev2025"
    },
    "activite_principale_naf_rev2": {
        "code": "8411Z",
        "libelle": "Administration publique générale",
        "nomenclature": "NAFRev2"
    }
}
```

Côté demarche.numerique.gouv.fr, on stocke les deux nomenclatures et on les expose selon la surface :

```
Flux de données NAF selon la version d'API :

                    API Entreprise
                         │
           ┌─────────────┴─────────────┐
           v3 (dépréciée)              v4
           │                           │
    activite_principale         activite_principale
    ┌──────────────┐            ┌──────────────┐
    │ code: 8411Z  │            │ code: 84.11  │
    │ NAFRev2      │            │ NAFRev2025   │
    └──────┬───────┘            └──────┬───────┘
           │                           │
           │                    activite_principale_naf_rev2
           │                    ┌──────────────┐
           │                    │ code: 8411Z  │
           │                    │ NAFRev2      │
           │                    └──────┬───────┘
           │                           │
           └─────────┬─────────────────┘
                     ▼
              Etablissement
           ┌─────────────────┐
           │ naf      (Rev2) │ ← GraphQL: naf, libelleNaf
           │ naf_2025        │ ← GraphQL: naf2025, libelleNaf2025
           └─────────────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
    Exports      Filtres      GraphQL
   (Rev2 only)  (Rev2+2025)  (Rev2+2025)
```

**Choix** : exposer les deux nomenclatures en parallèle. Les consommateurs migrent à leur rythme.

| Surface | Comportement |
|---------|-------------|
| GraphQL | `naf`/`libelleNaf` (Rev2) + `naf2025`/`libelleNaf2025` |
| Exports standard | Rev2 uniquement (pas de breaking change) |
| Export templates | NAF 2025 disponible comme colonne optionnelle |
| Filtres/colonnes | `libelle_naf_2025` ajouté |

**Pourquoi** : les consommateurs API (collectivités, éditeurs) parsent le NAF Rev2. Un remplacement casserait leurs intégrations sans préavis.

**Alternative rejetée** : remplacer Rev2 par NAF 2025 directement avec une période de dépréciation. Rejeté car les consommateurs n'ont pas de canal de notification fiable — on ne peut pas garantir qu'ils seraient prévenus à temps.

### Rate limiting server-driven per-pool [#13180](https://github.com/demarche-numerique/demarche.numerique.gouv.fr/pull/13180)

**Choix** : calibration du compteur Redis depuis les headers `RateLimit-*` de chaque réponse HTTP. Pas de limite hardcodée, pas de `sleep`.

**Pourquoi** :
- API Entreprise applique des limites différentes par pool (250, 100, 50, 5 req/min)
- Un compteur global bloquerait tout quand seul un pool à 5 req/min est saturé
- Les headers calibrent dynamiquement — si les limites changent côté serveur, on s'adapte sans déployer

```
API Entreprise — Pools et rate limits

Pool 250 req/min (défaut)
├── v4/insee/sirene/etablissements/{id}              (EtablissementJob)
├── v3/dgfip/etablissements/{id}/chiffres_affaires   (ExercicesJob)
├── v4/djepva/api-association/{id}                   (AssociationJob)
├── v3/infogreffe/rcs/{id}/extrait_kbis              (ExtraitKbisJob)
├── v3/european_commission/{id}/numero_tva            (TvaJob)
└── v3/banque_de_france/{id}/bilans                  (BilansBdfJob)

Pool 100 req/min
└── v4/urssaf/{id}/attestation_vigilance             (AttestationSocialeJob)

Pool 50 req/min
├── v3/gip_mds/etablissements/{id}/effectifs_mensuels   (EffectifsJob)
└── v3/gip_mds/unites_legales/{id}/effectifs_annuels    (EffectifsAnnuelsJob)

Pool 5 req/min
└── v4/dgfip/{id}/attestation_fiscale                (AttestationFiscaleJob)
```

Extrait de logs — les 4 pools en une même fenêtre (2026-05-26 10:13:12) :

```
[2026-05-26T10:13:12+02:00] endpoint=/v3/infogreffe/rcs/unites_legales/418166096/extrait_kbis status=200 ratelimit-limit=250 ratelimit-remaining=210
[2026-05-26T10:13:12+02:00] endpoint=/v4/djepva/api-association/associations/open_data/418166096 status=404 ratelimit-limit=250 ratelimit-remaining=207
[2026-05-26T10:13:12+02:00] endpoint=/v3/banque_de_france/unites_legales/418166096/bilans status=403 ratelimit-limit=250 ratelimit-remaining=206
[2026-05-26T10:13:12+02:00] endpoint=/v4/urssaf/unites_legales/418166096/attestation_vigilance status=403 ratelimit-limit=100 ratelimit-remaining=99
[2026-05-26T10:13:12+02:00] endpoint=/v3/gip_mds/etablissements/41816609600069/effectifs_mensuels/05/annee/2026 status=403 ratelimit-limit=50 ratelimit-remaining=42
[2026-05-26T10:13:12+02:00] endpoint=/v3/gip_mds/unites_legales/418166096/effectifs_annuels/2025 status=403 ratelimit-limit=50 ratelimit-remaining=41
[2026-05-26T10:13:12+02:00] endpoint=/v4/dgfip/unites_legales/418166096/attestation_fiscale status=403 ratelimit-limit=5 ratelimit-remaining=4
```

→ Chaque pool a son propre compteur. Si le pool 5 est vide, les pools 250/100/50 continuent de fonctionner.

**Alternative rejetée** : rate limiter client-side avec des limites hardcodées (ex. gem `rack-throttle` ou compteur Redis fixe). Rejeté car les limites varient par pool et peuvent changer côté API Entreprise sans préavis — des valeurs hardcodées deviendraient fausses silencieusement.

**Évolution** : la v1 (#13180) utilisait un `DECR` optimiste avant chaque appel + calibration probabiliste. La v2 (#13206) a simplifié en calibration systématique sur chaque réponse (le `DECR` dérivait sur les séries de 502).

### Circuit breaker fail-open par provider [#13208](https://github.com/demarche-numerique/demarche.numerique.gouv.fr/pull/13208)

Il y a une recommandation d'API Entreprise, on [la suit](https://entreprise.api.gouv.fr/developpeurs#incidents-et-maintenances).

**Choix** : un cron (2 min) interroge les 9 ping routes officielles d'API Entreprise. Résultat caché dans Redis (TTL 5 min). Les jobs vérifient le statut avant exécution. C'est l'approche recommandée par API Entreprise.

**Pourquoi** :
- Certains providers sont down plusieurs jours (TVA Commission Européenne : 55% uptime sur 90j)
- Les jobs vers un provider mort brûlent du rate limit pour rien et saturent les queues Sidekiq
- Les ping routes sont gratuites et sans rate limit

Un provider down consomme du rate limit comme un appel normal — logs prod (TVA Commission Européenne, pool 250) :

```
[2026-05-26T09:27:59+02:00] endpoint=/v3/european_commission/unites_legales/418166096/numero_tva status=502 ratelimit-limit=250 ratelimit-remaining=142  ← échec, -1
[2026-05-26T09:27:59+02:00] endpoint=/v3/infogreffe/rcs/unites_legales/418166096/extrait_kbis status=200 ratelimit-limit=250 ratelimit-remaining=141  ← succès, -1 aussi

(...)

[2026-05-26T09:29:04+02:00] endpoint=/v3/european_commission/unites_legales/418166096/numero_tva status=502 ratelimit-limit=250 ratelimit-remaining=245
[2026-05-26T09:29:40+02:00] endpoint=/v3/european_commission/unites_legales/418166096/numero_tva status=502 ratelimit-limit=250 ratelimit-remaining=117  ← 128 req brûlées en 36s
[2026-05-26T09:29:59+02:00] endpoint=/v3/european_commission/unites_legales/418166096/numero_tva status=502 ratelimit-limit=250 ratelimit-remaining=50   ← pool presque vide
[2026-05-26T09:30:21+02:00] endpoint=/v3/european_commission/unites_legales/418166096/numero_tva status=502 ratelimit-limit=250 ratelimit-remaining=204  (nouvelle fenêtre)
[2026-05-26T09:31:50+02:00] endpoint=/v3/european_commission/unites_legales/418166096/numero_tva status=502 ratelimit-limit=250 ratelimit-remaining=103  ← rebelote
```

→ Un 502 coûte -1 comme un 200. À l'échelle, les jobs TVA vident le budget des autres endpoints du même pool (INSEE, Kbis, RNA, chiffres d'affaires...).

**Fail-open** : si Redis ou le cron sont down, les jobs passent normalement. On préfère quelques 429 (gérés proprement par le rate limiter) à un blocage total.

**Sentry : `ProviderDownError` exclu du reporting** : quand un provider est down pendant des jours (ex. TVA Commission Européenne, 55% uptime), chaque retry Sidekiq remontait une `RetryableError` dans Sentry — 63k occurrences pour `european_commission/numero_tva` seul. Aucun signal utile : le cron de health check monitore déjà l'état des providers. On a introduit `ProviderDownError < RetryableError`, exclu via `Sentry.config.excluded_exceptions`. Sidekiq continue de retry avec backoff, mais Sentry reste propre. Les `RetryableError` classiques (rate limit, erreurs transitoires) restent reportées normalement.

**Re-enqueue par raise, pas à la main** : la version initiale ré-enfilait les jobs manuellement (`perform_later`) quand un provider était down, sans lever d'erreur. Problème : sans raise, Sidekiq ne compte pas de tentative → pas de backoff exponentiel → les jobs se ré-enfilent immédiatement en boucle. Conséquence : engorgement des queues Sidekiq constaté en production (vendredi 2026-05-30). Corrigé en levant une `RetryableError` pour que Sidekiq gère le backoff nativement.

```
Re-enqueue manuel vs Sidekiq natif :

  ❌ perform_later (avant)              ✅ raise RetryableError (après)

  Job exécuté                           Job exécuté
       │                                     │
  provider down?                        provider down?
       │ oui                                 │ oui
       ▼                                     ▼
  perform_later(args)                   raise RetryableError
       │                                     │
  Sidekiq voit :                        Sidekiq voit :
  "job terminé OK"                      "job échoué, attempt +1"
       │                                     │
  attempt = 0                           attempt = 1, 2, 3...
  retry_count = 0                       backoff = 16s, 31s, 96s...
  backoff = 0                                │
       │                                     ▼
       ▼                                retry avec espacement
  nouveau job immédiat                  croissant
       │                                     │
       ▼                                     ▼
  nouveau job immédiat                  provider revient → OK
       │
       ▼
  💥 engorgement queue
```

### Backfill basse priorité pour ne pas se faire blacklister [#13179](https://github.com/demarche-numerique/demarche.numerique.gouv.fr/pull/13179)

**Choix** : la maintenance task ne consomme que le surplus de rate limit (pause quand remaining < 200 sur 250/min).

**Pourquoi** : le trafic usager temps réel (recherche SIRET, dépôt de dossier) a toujours la priorité. Le backfill des 6M d'établissements (enrichissement NAF 2025) peut prendre des jours, c'est acceptable.

Note : les ~13k établissements corrompus par le bug initial ont été corrigés en amont pour valider l'efficacité du rate limiter en production.

## Chronologie des PRs

```
Bug report (mail Corentin)
    │
    ▼
#13101  Dry::Monads — erreurs explicites et typées
    │
    ▼
#13177  Migration v3→v4, suppression EntrepriseAdapter
    │
    ├──────────────────┐
    ▼                  ▼
#13180  Rate limiter   #13179  Exposer NAF 2025
    │                      (GraphQL, filtres, exports,
    ▼                       backfill 6M)
#13206  Simplification calibration
    │
    ▼
#13207  Mode dégradé sur 429
    │
    ▼
#13208  Circuit breaker par provider
```

## Conséquences

- Tout nouvel appel API Entreprise doit utiliser `Dry::Monads` et gérer chaque cas explicitement (Success/Failure avec pattern matching)
- Les jobs API Entreprise doivent passer par le `RateLimiter` et vérifier le `HealthChecker` avant exécution
- Les nouveaux champs NAF doivent exposer les deux nomenclatures (Rev2 + NAF 2025) jusqu'à décision explicite de dépréciation
- Le circuit breaker et le rate limiter sont complémentaires : le circuit breaker évite de brûler du rate limit sur des providers morts, le rate limiter gère la pression sur les providers vivants
- On dispose désormais d'un pattern réutilisable pour backfiller les ~6M d'établissements sans se faire blacklister : maintenance task qui ne consomme que le surplus de rate limit

## Ce qui reste

- [x] Valider que le circuit breaker se comporte bien sur les providers instables (TVA, effectifs)
- [x] Phase 3 cleanup (~2 semaines post-merge) : supprimer `EntrepriseAdapter`, `EntrepriseJob`, `ENTREPRISE_RESOURCE_NAME` (conservés pour rolling deploy)
- [ ] Merge #13179 (exposition NAF 2025)
- [ ] Monitorer le backfill NAF 2025 via maintenance_tasks
- [ ] Décider de l'exposition NAF 2025 dans l'UI (actuellement exposé en exports, filtres et API uniquement)
- [ ] Converger le nommage : `naf` vs `naf_2025` vs `libelle_naf_2025` — faut-il renommer `naf` en `naf_rev2` pour la symétrie ?
