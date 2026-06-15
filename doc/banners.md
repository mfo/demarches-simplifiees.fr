# Bannières du site

Les bannières sont des messages d'information affichés en haut des pages
(par exemple : « Maintenance prévue ce soir de 22h à 23h »).

Elles sont propres à chaque instance et se gèrent depuis l'espace **Manager**,
à l'adresse `/manager/banners`, accessible aux super admins. Aucune variable
d'environnement ni redéploiement n'est nécessaire : toute modification est
appliquée **immédiatement**.

## Les cinq bannières

| Bannière | Où elle s'affiche |
|----------|-------------------|
| **Bannière globale** | Sur toutes les pages, pour tout le monde |
| **Bannière instructeurs** | Sur toutes les pages, pour les instructeurs |
| **Bannière usagers** | Sur toutes les pages, pour les usagers, administrateurs, experts et gestionnaires |
| **Page de connexion** | Sur les pages de connexion et d'inscription des usagers |
| **Connexion manager** | Sur la page de connexion du Manager |

Chaque bannière a un seul champ à renseigner : son **contenu**.

## Publier et dépublier

- **Pour publier** : saisissez le contenu et cliquez sur « Enregistrer ».
  La bannière apparaît aussitôt sur le site.
- **Pour la retirer** : videz le champ contenu et cliquez sur « Enregistrer ».
  Elle disparaît aussitôt.

Il n'y a pas de date de début ou de fin à programmer : l'affichage se contrôle
uniquement en remplissant ou en vidant le contenu.

## Mise en forme du texte

Le contenu accepte quelques balises HTML simples (texte en gras, lien cliquable, etc.).
La liste des balises autorisées est rappelée directement dans l'interface, au-dessus des
bannières, avec un exemple complet prêt à copier.

Toute balise non autorisée (titres, listes, scripts…) est automatiquement retirée à
l'affichage : le contenu reste volontairement court et sur une seule ligne.
