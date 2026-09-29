---
name: cockpit
description: Branche le cockpit central (rnab26/Cockpit-General) sur le projet courant, ou le fait évoluer. Se déclenche quand Raphaël dit "monte un cockpit", "crée le cockpit", "branche le cockpit", "modifie le cockpit" ou équivalent, sur n'importe quel projet, quel que soit son stack.
---

# Cockpit — brancher un projet, faire évoluer le cockpit

Depuis le 28 sept. 2026, il n'y a plus UN cockpit par projet à recopier :
il y a **un cockpit central** (dépôt `rnab26/Cockpit-General`, base Supabase
centrale, schéma `cockpit`, app https://rnab26.github.io/Cockpit-General/) et un
projet s'y **branche**. Les décisions de Raphaël qui ont fondé ce modèle
sont dans `cockpit-kit/DECISIONS-2026-09-28.md` (ce dépôt) : relis-les avant
de proposer autre chose. Le kit de `cockpit-kit/` (migrations dev_items,
hook, scripts) est l'ANCIEN modèle, gardé pour l'histoire : ne l'installe
plus.

## « Monte / branche un cockpit » sur le projet courant

**Tu ne branches rien avant d'avoir posé les questions.** Correction de
Raphaël (29 sept. 2026, dépôt de Mélissa) : « ça le fait directement, ça ne
pose aucune question, ça avance comme une locomotive » — branché d'un coup,
pas fusionné sur main, chantiers de l'ancien tableau pas repris. Donc trois
temps : regarder (sans rien écrire), demander en UNE fois, puis tout faire
d'un coup.

### 1. Regarder, sans rien écrire

- Attache `rnab26/Cockpit-General` s'il n'est pas déjà dans la session
  (`add_repo`, puis clone). Lis son `README.md` et son `CLAUDE.md`.
- Le projet est-il déjà en base ?
  `cockpit/scripts/sql.sh "select slug, nom from projets"`.
- Où le projet suit-il déjà son travail ? Cherche : `PROJECT_LOG.md`,
  `TODO*`, `ROADMAP*`, une URL `claude.ai/artifact/…` dans son `CLAUDE.md`
  ou ses docs (lis-la : `Artifact` `action: "read"`, réponses avec
  `ArtifactData`), `dev_items` de Jarvis, `chantiers` du Trieur. Compte les
  chantiers ouverts.
- Branche principale du dépôt et branche courante.

### 2. Demander, en une seule fois

Un seul message, avec l'outil de questions à choix (`AskUserQuestion`) s'il
existe, sinon une liste numérotée qu'il remplit au pouce. Mots simples, pas
de jargon, 2 à 4 réponses toutes prêtes par question, ta recommandation
en premier et marquée « (recommandé) ». Les quatre choix qui comptent :

1. **Nom du projet dans le cockpit** — propose le nom que tu as déduit
   (et le slug : minuscules, tirets), une variante, « autre ».
2. **Reprendre les chantiers existants ?** — dis où tu les as trouvés et
   combien : « Oui, les N ouverts de <source> (recommandé) » / « Non, on
   part de zéro ». Sans source trouvée, dis-le et saute la question.
3. **Mettre en ligne tout de suite ?** — « Oui, sur <main> tout de suite
   (recommandé) » / « Non, laisse sur une branche, je regarde d'abord ».
4. **Mode autonome** (les sessions enchaînent seules les chantiers libres) —
   « Non pour l'instant (recommandé) » / « Oui, tout le temps » /
   « Oui, jusqu'à demain 9 h ».

Pas d'autre question : le reste (site hôte, membres) se déduit ou se
signale dans le bilan. Tu attends sa réponse ; tu n'enchaînes pas.

### 3. Tout faire d'un coup, selon ses réponses

1. Travaille sur une branche `claude/cockpit-<slug>`. Lance l'installateur
   depuis le dépôt cockpit :
   `cockpit/scripts/brancher.sh --projet <slug> --nom "<Nom>" --depot <owner/repo> --dossier <chemin du projet courant>`
   (ajoute `--site <url>` si un site hôte recevra le module embarqué). Il est
   idempotent : relançable sans rien casser, il signale un fichier existant
   différent au lieu de l'écraser.
2. Vérifie le hook pour de vrai :
   `COCKPIT_PROJET=<slug> CLAUDE_PROJECT_DIR=<chemin> bash <chemin>/.claude/hooks/cockpit-session-start.sh | jq -r .hookSpecificOutput.additionalContext | head`.
3. Reprise, s'il l'a demandée : une ligne par chantier OUVERT, insérée
   avec `scripts/cockpit-sql.sh` (ou `sql.sh`) dans `chantiers`
   (`titre` ≤ 80 car., `demande` = ses mots, `etat` = `libre`, `a_cadrer`
   ou `bloque` selon l'état réel, jamais `valide` ni `en_cours`), puis
   rangée avec `scripts/cockpit-chantier.sh --ranger <id> --section "…"`.
   Pas `--ouvrir` : il réserverait chaque chantier à ta session. Ne supprime
   jamais l'ancienne source ; ajoute-y « repris dans le cockpit le … ».
   Compte à la fin : autant de lignes en base que de chantiers repris.
4. Mode autonome, s'il l'a demandé :
   `select cockpit.regler_autonome('<slug>', null, 20, true)` (tout le
   temps) ou `regler_autonome('<slug>', '<demain 09:00 Asia/Jerusalem>')`.
5. Si le projet a des utilisateurs finaux : colle la balise imprimée par
   `brancher.sh` dans la page qui leur convient (Jinja, React, HTML : c'est
   une balise `<script>`, rien d'autre) ; ils s'ajoutent depuis l'app
   (Projets & membres → e-mail) après leur première connexion.
6. Commit (scripts, hook, settings.json, CLAUDE.md, balise) avec le pourquoi ; push
   de la branche. S'il a dit « en ligne » : `git fetch origin <main>`,
   fusion dans `<main>`, push, puis `git log origin/<main> -1` pour le
   prouver.

### 4. Bilan en trois lignes

- **Fait** : branché sous « <Nom> », N chantiers repris, en ligne sur
  <main> (ou sur la branche <x>), autonome oui/non.
- **Pas fait** : ce qui manque, et pourquoi.
- **À toi** : ce qu'il doit faire lui-même (ajouter des membres, coller la
  balise, une clé manquante) — ou « rien ».

Prérequis côté environnement cloud du projet : `SUPABASE_SERVICE_ROLE_KEY`
(la clé de la base centrale `bexiyvmdbxcwxasgslxp`), `jq`, `curl`, `python3`.
Si la clé manque, `sql.sh` le dit : signale-le à Raphaël, ne devine pas
l'état du projet.

## « Modifie le cockpit »

Une évolution du cockpit (écran, schéma, scripts, module embarqué) se fait
dans `rnab26/Cockpit-General`, jamais dans un projet branché : tous les projets en
profitent au prochain déploiement. Le dépôt cockpit se pilote lui-même
(projet `cockpit`) : réserve un chantier, signale ta progression, termine en
« à vérifier ». Une migration est idempotente et ne touche que le schéma
`cockpit`. La fonction serveur `cockpit-embed` se redéploie à la main
(`VERIFY_JWT=false scripts/deployer-fonction.sh cockpit-embed`).

## Ce que tu ne fais pas seul

Poser `valide` sur un chantier ; régénérer une `cle_embed` ; créer un projet
Supabase ou une ressource payante ; supprimer des données. Et une leçon
apprise sur un projet branché remonte dans `rnab26/Cockpit-General` (code) ou dans
`cockpit-kit/DECISIONS-*.md` de ce dépôt (décision), jamais seulement dans
le projet où elle a été découverte.
