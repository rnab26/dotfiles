# Kit cockpit — réutilisable sur n'importe quel projet

Extrait du cockpit du projet Jarvis (Supabase + Claude Code), débarrassé de
tout ce qui lui est propre (voix, Android, notifications). Ce qui reste est le
mécanisme générique : une table qui porte les chantiers, un hook qui l'injecte
au démarrage de chaque session, une discipline qui évite les pièges déjà payés
une fois ailleurs.

## Ce que contient le kit

```
migrations/
  0001_cockpit_base.sql        dev_items, dev_log, claim/release, RLS
  0002_cockpit_historique.sql  trigger anti-écrasement + trace des suppressions
  0003_exec_sql.sql            fonction exec_sql (pour scripts/sql.sh)
scripts/
  sql.sh                       exécuter du SQL sans popup de validation
  demander.sh                  poser une question DANS le cockpit
hooks/
  session-start.sh             injecte l'état du cockpit à chaque démarrage
CLAUDE-cockpit-template.md     bloc à coller dans le CLAUDE.md du nouveau projet
```

## Installation dans un nouveau projet

1. **Crée (ou réutilise) un projet Supabase**, note son URL et sa clé
   `service_role`.

2. **Applique les trois migrations dans l'ordre**, via le tableau de bord
   Supabase (SQL Editor) ou l'outil MCP Supabase une seule fois (avant que
   `exec_sql` existe, tu n'as pas encore de moyen de l'éviter) :
   ```
   0001_cockpit_base.sql
   0002_cockpit_historique.sql
   0003_exec_sql.sql
   ```

3. **Copie les scripts dans le nouveau dépôt** :
   ```bash
   cp scripts/sql.sh <nouveau-dépôt>/scripts/sql.sh
   cp scripts/demander.sh <nouveau-dépôt>/scripts/demander.sh
   chmod +x <nouveau-dépôt>/scripts/sql.sh <nouveau-dépôt>/scripts/demander.sh
   ```

4. **Copie le hook** :
   ```bash
   mkdir -p <nouveau-dépôt>/.claude/hooks
   cp hooks/session-start.sh <nouveau-dépôt>/.claude/hooks/session-start.sh
   chmod +x <nouveau-dépôt>/.claude/hooks/session-start.sh
   ```
   Déclare-le dans `<nouveau-dépôt>/.claude/settings.json` (crée le fichier
   s'il n'existe pas) :
   ```json
   {
     "hooks": {
       "SessionStart": [
         { "hooks": [{ "type": "command", "command": ".claude/hooks/session-start.sh" }] }
       ]
     }
   }
   ```

5. **Pose les variables d'environnement** dans l'environnement cloud Claude
   Code du nouveau projet (jamais dans le dépôt) :
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`

6. **Colle et adapte `CLAUDE-cockpit-template.md`** dans le `CLAUDE.md` du
   nouveau dépôt, à la racine. Remplace `[ID_DU_PROJET]` et les crochets, et
   *rends propre au projet* : le nom des thèmes attendus, les sujets sensibles
   qui exigent ton accord avant que du code parte, etc. Cette copie versionnée
   est celle qui compte — pas la mémoire d'une session.

7. **Vérifie** :
   ```bash
   SUPABASE_URL=https://xxxx.supabase.co SUPABASE_SERVICE_ROLE_KEY=... \
     scripts/sql.sh "select 1"
   ```
   Puis ouvre une session Claude Code sur le nouveau dépôt et regarde si le
   bloc « État du projet au démarrage de cette session » apparaît.

## Comment le réutiliser au quotidien

- **Créer un chantier** : une ligne dans `dev_items` (`insert into dev_items
  (user_id, title, notes, status, priority, theme) values (...)`), avec un
  marqueur en tête de `notes` (`[LIBRE]` ou `[À CADRER...]`).
- **Ouvrir une session dessus** : elle lit le hook, choisit un chantier, le
  réserve (`claim_dev_item`), code, pousse, l'archive avec le commit.
- **Poser une question** : `scripts/demander.sh`, jamais un document externe —
  la réponse arrive dans `dev_log` et remonte au démarrage de la session
  suivante.
- **Plusieurs sessions en parallèle** : chacune réserve ce qu'elle prend,
  libère en terminant, se parle via `dev_log` avec le préfixe `Pour la
  session … :`.

## Les dix pièges déjà payés, et pourquoi le kit est câblé comme ça

Chacun a coûté du temps ou une perte réelle sur le projet d'origine avant
d'être corrigé — les corrections sont dans le kit dès le départ, pas à
redécouvrir :

1. **Une note écrasée par une écriture concurrente ou pressée** → le trigger
   de `0002_cockpit_historique.sql` garde l'ancienne version, quel que soit le
   chemin d'écriture.
2. **Une suppression (`DELETE`) invisible, aucune trace** → table de trace
   *sans* clé étrangère en cascade vers `dev_items` : elle survit à la
   suppression qu'elle décrit.
3. **Deux lectures différentes du même marqueur qui finissent par diverger**
   (un composant d'affichage et un script autonome qui ne sont pas d'accord
   sur ce que `[LIBRE]` veut dire) → une seule fonction qui décide, réutilisée
   partout ; si deux runtimes ne peuvent pas partager le code, un contrôle
   automatique fait tourner les deux implémentations sur les mêmes cas.
4. **Une valeur texte libre (comme `theme`) qui dérive sans qu'on le
   remarque** → n'ajoute une table de référence (« sections déclarées ») que
   si tu en as vraiment besoin, et alors un contrôle qui *signale* l'écart
   sans jamais corriger tout seul.
5. **Un composant testé avec un jeu de données inventé qui explose en usage
   réel** (peu d'items, textes courts, jamais à l'échelle) → teste l'affichage
   sur de VRAIES données à la vraie échelle avant de croire qu'un budget
   visuel tient.
6. **Un contrôle qui vérifie sa propre reformulation** (il cherche un mot dans
   le code plutôt que l'effet réel) → essaie chaque contrôle à l'ENVERS
   (casse volontairement ce qu'il garde) avant de lui faire confiance.
7. **Un même `kind` qui porte deux sens opposés** (une vraie demande vs un
   compte rendu de session) → `pourquoi` est obligatoire sur toute question
   posée par `demander.sh`, c'est ce qui les distingue structurellement.
8. **Des chantiers dictés/créés en double**, jamais remarqués sur une longue
   liste → si les chantiers sont créés en volume (voix, import), ajoute une
   détection de recouvrement mesurée sur de vraies données, pas un seuil
   choisi à l'instinct.
9. **Une question posée hors de la base** (document externe, fiche, message
   séparé) → perdue ou dédoublée. `demander.sh` écrit toujours dans `dev_log`.
10. **Un "done" en base qui ne l'est pas vraiment** (une session marque son
    chantier fini sur sa propre branche sans jamais la fusionner) → celui qui
    orchestre plusieurs sessions vérifie la fusion réelle (`git merge-base
    --is-ancestor`) avant de croire le statut de la base, et fusionne
    lui-même si besoin.

## Ce qui n'est volontairement PAS dans le kit

- Les sections déclarées (`dev_sections`), le résumé "Où j'en suis", les
  notifications, l'UI React du cockpit : utiles chez Jarvis, mais pas
  nécessaires pour que le principe marche. Ajoute-les seulement si le besoin
  se fait vraiment sentir — la table + le hook suffisent pour démarrer.
- Un registre d'erreurs applicatives (`jarvis_erreurs`) : spécifique à un
  produit qui a des utilisateurs et des pannes à tracer. Un chantier de dépôt
  interne n'en a pas forcément besoin.
- Tout ce qui touche à la voix ou à une app mobile : propre à Jarvis, aucun
  rapport avec le mécanisme du cockpit lui-même.
