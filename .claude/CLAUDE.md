# CLAUDE.md global — Raphaël

Ce fichier s'applique à toutes mes sessions Claude Code, tous projets confondus.
Les règles spécifiques à un projet (stack, historique technique) vivent dans le
CLAUDE.md de ce projet et complètent celui-ci — elles ne le remplacent pas.

## Qui je suis

Entrepreneur, plusieurs projets en parallèle, codeur débutant qui travaille en
binôme avec Claude Code. Je communique en français. Je travaille souvent depuis
mobile (Android/iOS) et je veux limiter les allers-retours manuels.

## Comment travailler avec moi

- **Mode Plan par défaut** pour toute tâche non-triviale (3 étapes ou plus, ou
  décision d'architecture). Présente ton plan et attends ma validation avant de
  coder. Si quelque chose part dans le mauvais sens en cours de route, arrête-toi
  et repropose un plan plutôt que de continuer à pousser dans la mauvaise direction.
- **Explique tes décisions techniques importantes** en une ou deux phrases avant
  de les implémenter — je suis débutant et j'apprends en même temps.
- **Procède par petites étapes vérifiables**, pas par gros blocs de code d'un coup.
- **Sois direct et honnête**, y compris pour me pousser à reconsidérer une mauvaise
  idée. Je préfère un retour franc à une validation systématique.

## Contraintes techniques permanentes

- **Jamais de credentials en dur dans le code.** Utiliser les mécanismes d'auth
  natifs de la plateforme (ex : Supabase Auth) ou des variables d'environnement.
- **Ne pas réinventer les composants UI** si une brique existante et éprouvée
  fait le travail (ex : shadcn/ui + Tailwind pour le front). Réserver le code
  custom aux cas où rien d'existant ne convient.
- **Le repo Git (branche main) est la source de vérité.** Ne pas laisser dériver
  le code déployé et le code versionné.
- **Stack par défaut sauf raison contraire** : Supabase (Auth + Postgres +
  Storage) côté backend, React + Tailwind + shadcn/ui côté front, hébergement
  statique type GitHub Pages quand c'est adapté au projet.

## Workflow

- Utilise `/rewind` plutôt que de me faire recommencer de zéro si une
  modification part dans une mauvaise direction.
- Ajoute au CLAUDE.md du projet concerné toute règle ou piège récurrent qu'on
  découvre ensemble, pour ne pas avoir à le rappeler à chaque session.
- Pour les sujets à fort enjeu (données financières, credentials, actions
  irréversibles) : toujours prévoir une étape de validation humaine explicite
  avant exécution, même si le reste du flux est automatisé.

## Contexte de vie utile

Basé en Israël, entrepreneur depuis la fin de l'adolescence, actif sur plusieurs
domaines (immobilier/proptech, outils SaaS internes, automatisation). Apprécie
qu'on lui propose des solutions existantes/éprouvées plutôt que du sur-mesure
systématique, pour limiter le temps de développement et le tâtonnement visuel.
