---
name: cockpit
description: Monte ou fait évoluer un cockpit de développement (base Supabase dev_items/dev_log + hook de démarrage) sur le projet courant. Se déclenche quand Raphaël dit "monte un cockpit", "crée le cockpit", "modifie le cockpit" ou équivalent, sur n'importe quel projet.
---

# Cockpit de développement — installation et évolution

Ce skill installe (ou fait évoluer) sur le dépôt courant le même mécanisme de
cockpit que celui du projet Jarvis (rnab26/Jarvis-assistant) : une table
Supabase qui porte les chantiers, un hook qui l'injecte au démarrage de chaque
session, et une discipline qui évite une dizaine de pièges déjà payés une fois
ailleurs (notes écrasées, suppressions non tracées, marqueurs qui divergent,
etc. — tous documentés dans `cockpit-kit/README.md`, section finale).

## Si le cockpit n'existe pas encore sur ce dépôt

1. Lis en entier `cockpit-kit/README.md` (dans ce même repo, `rnab26/dotfiles`)
   avant de commencer — il documente le pourquoi de chaque pièce, pas
   seulement le comment.
2. Vérifie si Raphaël a déjà un projet Supabase pour CE dépôt (demande-lui, ou
   regarde s'il existe déjà des migrations `supabase/migrations/` dans le
   dépôt courant). S'il n'y en a pas encore, pose-lui la question — créer un
   nouveau projet Supabase est une ressource, potentiellement payante au-delà
   du plan gratuit, donc pas une décision à prendre seul.
3. Copie les 3 migrations de `cockpit-kit/migrations/` dans
   `supabase/migrations/` du dépôt courant (renomme-les avec le préfixe
   numérique suivant la convention déjà en place dans ce dépôt), et
   applique-les.
4. Copie `cockpit-kit/scripts/sql.sh` et `cockpit-kit/scripts/demander.sh`
   dans `scripts/` du dépôt courant (crée le dossier si besoin), rends-les
   exécutables.
5. Copie `cockpit-kit/hooks/session-start.sh` dans
   `.claude/hooks/session-start.sh` du dépôt courant, rends-le exécutable, et
   déclare-le dans `.claude/settings.json` (crée le fichier s'il n'existe
   pas) — voir `cockpit-kit/README.md` pour l'extrait JSON exact.
6. Colle et ADAPTE `cockpit-kit/CLAUDE-cockpit-template.md` dans le
   `CLAUDE.md` du dépôt courant (à la racine) — remplace les crochets par les
   vraies valeurs du projet (id Supabase, sujets sensibles propres à CE
   projet). C'est cette copie versionnée qui fait foi, pas ce skill.
7. Dis à Raphaël où poser `SUPABASE_URL` et `SUPABASE_SERVICE_ROLE_KEY`
   (variables d'environnement de l'environnement cloud Claude Code de CE
   projet, jamais dans le dépôt) — tu ne peux pas les poser toi-même.
8. **Construis l'écran visuel du cockpit — ne t'arrête pas à la base de
   données.** Une table sans écran n'est utile qu'aux sessions Claude Code
   (via le hook), pas à Raphaël qui veut le VOIR et cliquer dessus. AVANT de
   coder cet écran :
   - Identifie le stack réel du dépôt courant (`package.json` et son
     framework, `requirements.txt`/`pyproject.toml` avec `streamlit`, HTML
     brut, Java, autre) — NE PRÉSUME PAS que c'est du React/Tailwind/shadcn
     comme Jarvis. Le cockpit doit s'adapter au projet, jamais l'inverse.
   - Lis `cockpit-kit/FONCTIONNALITES.md` : c'est le cahier des charges
     fonctionnel (résumé "où j'en suis", ce qui a changé depuis la dernière
     visite, filtre/recherche/actions groupées, fil de discussion par
     chantier, ce qui attend une décision, archives, doublons) — écrit
     indépendamment du langage. Construis CES fonctions dans l'idiome du
     stack détecté, avec ses propres briques (composants natifs du
     framework, pas du JSX copié dans un projet Python).
   - Une simple liste d'une ligne par chantier n'est PAS un cockpit terminé :
     c'est le point de départ, insuffisant tel quel.
9. Vérifie que `scripts/sql.sh "select 1"` répond, commit, et dis en trois
   lignes ce qui est fait / ce qu'il reste à faire côté Raphaël (poser les
   variables d'environnement, au minimum).

## Si le cockpit existe déjà et qu'on te demande de le FAIRE ÉVOLUER

Ne reprends PAS l'installation depuis zéro. Lis le `CLAUDE.md` du dépôt
courant (sa section cockpit) pour connaître l'état réel, et n'applique que le
changement demandé — dans l'esprit des leçons du README (ne jamais écraser
une note sans l'avoir relue dans un appel séparé, ne jamais dupliquer une
règle de lecture des marqueurs à deux endroits, mesurer sur données réelles
avant de croire qu'un budget d'affichage tient).

## Ne fais jamais ça

- Ne crée pas de nouveau projet Supabase sans demander — c'est une ressource
  externe, potentiellement payante.
- Ne pose aucun secret dans le dépôt.
- Ne remplace pas ce skill ni `cockpit-kit/` par une copie modifiée sans
  prévenir Raphaël : ce dossier est la référence pour TOUS ses projets, une
  modification ici affecte silencieusement les prochaines installations
  ailleurs.
