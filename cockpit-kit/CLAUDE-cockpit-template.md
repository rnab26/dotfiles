<!--
Bloc à coller dans le CLAUDE.md du nouveau projet (à la racine du dépôt), et à
adapter aux crochets [ENTRE CROCHETS]. C'est cette copie versionnée, pas la
mémoire d'une session, qui fait foi — une session déjà ouverte qui ne peut plus
relire ce fichier doit pouvoir se référer à cette section telle quelle.
-->

## Cockpit de développement (chantiers)

Ce projet a un cockpit interne — une vraie table Supabase, pas des notes dans
une conversation qui s'oublient d'une session à l'autre.

- **Projet Supabase** : `[ID_DU_PROJET]`
- **Tables** : `dev_items` (chantiers), `dev_log` (journal de bord et
  questions), `dev_items_historique` (chaque note gardée), `dev_items_supprimes`
  (chaque suppression tracée).

### Au démarrage de CHAQUE session, avant toute autre chose

**Normalement rien à faire : c'est déjà chargé.** Un hook de démarrage
(`.claude/hooks/session-start.sh`) lit la base à chaque ouverture de session et
injecte l'état du projet dans le contexte.

Si ce bloc n'apparaît pas, ou dit que le cockpit n'a pas pu être chargé, lis à
la main :

```bash
scripts/sql.sh "select id, title, status, priority, notes, claimed_by, claim_expires_at from dev_items where archived_at is null order by priority desc, created_at"
scripts/sql.sh "select created_at, author, kind, body, answered_at, item_id from dev_log order by created_at desc limit 30"
scripts/sql.sh "select title, notes, archived_at from dev_items where archived_at is not null order by archived_at desc limit 15"
```

Une question dont la réponse est déjà dans les notes d'un chantier ou dans le
journal ne doit pas être reposée à l'humain.

**AVANT DE RÉÉCRIRE UNE NOTE, RELIS-LA — dans un appel SÉPARÉ.**
`update dev_items set notes = …` écrase tout, et une note vit souvent depuis
plusieurs sessions : elle porte des décisions déjà prises, ce qui a été écarté,
ce qui a été vérifié. Le `select` doit précéder l'`update`, pas l'accompagner —
groupés dans le même appel, on lit le texte APRÈS l'avoir détruit. La bonne
forme est d'AJOUTER à la note, pas de la remplacer. (Un trigger garde quand
même l'ancienne version dans `dev_items_historique`, mais ne compte pas dessus
pour excuser d'écraser sans relire — c'est un filet, pas une autorisation.)

**En terminant un chantier**, marque-le fait et archive-le, avec une note qui
référence le commit :

```bash
scripts/sql.sh "update dev_items set status = 'done', archived_at = now(), notes = 'Fait : <résumé court>. Commit <hash>.' where id = '<id>'"
```

**Ne laisse jamais un travail sans trace.** Si tu t'arrêtes en cours de route,
que tu es interrompu, ou que le sujet change : écris où tu en es dans les
notes du chantier ou dans `dev_log` avant de lâcher.

**Et si c'est du travail à faire, ça devient un CHANTIER — pas une note.** Tout
ce que tu n'as pas pu avancer, tout ce qui attend une décision, et tout bug
découvert sans le corriger, doit exister comme une ligne de `dev_items`
ouverte. Une trouvaille écrite seulement dans `dev_log` est perdue dès qu'une
douzaine de messages passent — le hook de démarrage n'en injecte que les
dernières.

Écris le chantier de façon **autoportante** : ce qui a déjà été répondu, ce qui
a été vérifié (et ce qui a été écarté, pour qu'on ne le repropose pas), le
fichier concerné, et le marqueur `[LIBRE]` ou `[À CADRER AVEC LUI AVANT DE
COMMENCER]`.

### Les marqueurs des notes, en tête, entre crochets

`[LIBRE]` : spécifié de bout en bout, aucune décision ni accès à obtenir — à
prendre sans rien demander.

`[À CADRER AVEC [PRÉNOM] AVANT DE COMMENCER]` : ne pas coder avant sa réponse.

`[BLOQUÉ PAR : <id ou nom du chantier>]` : dépend d'un autre chantier.

`[LIVRÉ — RESTE À CONSTATER]` : le code existe et est vérifié, mais seul un
essai réel (sur l'appareil, avec un vrai compte, etc.) peut confirmer que ça
marche vraiment. N'archive JAMAIS avant cette confirmation.

Ces marqueurs se lisent en TÊTE de la note, jamais ailleurs : une note longue
peut citer un autre marqueur en passant, le prendre pour celui du chantier
ferait faire ou éviter la mauvaise chose.

### Une question : `scripts/demander.sh`, jamais un document externe

```bash
scripts/demander.sh --question "On garde le mot-à-mot combien de temps ?" \
  --pourquoi "Supprimer est irréversible, garder ne l'est pas." \
  --chantier <uuid-du-chantier> \
  --option "Sans limite|Rien n'est jamais supprimé.|recommande" \
  --option "30 jours|Un mois glissant, puis on efface."

scripts/demander.sh --action --question "Dépose LA_CLE dans les secrets" \
  --pourquoi "Sans elle, telle fonctionnalité ne peut pas se vérifier."
```

La question devient une ligne de `dev_log`, injectée au démarrage de CHAQUE
session suivante tant qu'il n'y a pas de réponse. Avant de poser une question,
relis les notes du chantier et le journal — une question déjà répondue et
reposée est ce qui épuise le plus.

### Travail en parallèle : réserver un chantier et se parler

Plusieurs sessions travaillent parfois sur ce dépôt en même temps.

```bash
scripts/sql.sh "select claim_dev_item('<id du chantier>', '<nom de ta branche>', 120)"
```

`false` = une autre session est déjà dessus, prends-en un autre. La
réservation expire après le délai en minutes. En terminant :

```bash
scripts/sql.sh "select release_dev_item('<id>', '<ta branche>')"
```

Pour parler à une autre session, écris dans `dev_log` avec le préfixe
`Pour la session … :` — c'est la convention qui distingue un message
inter-sessions d'une vraie question à l'humain.

**Ne prends pas un gros lot d'un coup.** Réserve ce que tu traites maintenant
et laisse le reste libre.

### Requêtes SQL : `scripts/sql.sh`, jamais l'outil MCP Supabase

L'outil MCP `execute_sql` impose un pop-up de validation à chaque appel, sans
réglage pour le désactiver. `scripts/sql.sh` passe par l'API HTTPS et la
fonction `exec_sql` : aucune validation, mais accès total à la base (DDL et
suppressions comprises). **Demande toujours confirmation avant un `drop`, un
`delete` massif ou un `truncate`.**

**Une seule instruction par appel quand tu attends un résultat** — grouper
plusieurs `select` séparés par `;` s'exécute mais ne renvoie AUCUNE ligne, en
silence. Grouper est bon pour des écritures liées dont on n'attend pas de
lignes ; vérifie toujours dans un appel séparé après.
