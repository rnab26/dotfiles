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

1. Attache `rnab26/Cockpit-General` s'il n'est pas déjà dans la session
   (`add_repo`, puis clone). Lis son `README.md` et son `CLAUDE.md`.
2. Choisis le slug du projet (minuscules, tirets : `facepro`, `trieur`,
   `melissa-site`) et vérifie qu'il n'existe pas déjà :
   `cockpit/scripts/sql.sh "select slug, nom from projets"`.
3. Lance l'installateur depuis le dépôt cockpit, vers le dépôt courant :
   `cockpit/scripts/brancher.sh --projet <slug> --nom "<Nom>" --depot <owner/repo> --dossier <chemin du projet courant>`
   (ajoute `--site <url>` si un site hôte recevra le module embarqué). Il est
   idempotent : relançable sans rien casser, il signale un fichier existant
   différent au lieu de l'écraser.
4. Vérifie le hook pour de vrai :
   `COCKPIT_PROJET=<slug> CLAUDE_PROJECT_DIR=<chemin> bash <chemin>/.claude/hooks/cockpit-session-start.sh | jq -r .hookSpecificOutput.additionalContext | head`.
5. Si le projet suivait déjà ses chantiers ailleurs (`PROJECT_LOG.md`,
   `dev_items` de Jarvis, `chantiers` du Trieur, fiche artefact), **propose**
   une reprise des chantiers OUVERTS dans le cockpit (une ligne par chantier,
   `etat` selon leur état réel, `demande` = leurs mots), et fais-la une fois
   Raphaël d'accord. Ne supprime jamais l'ancienne source.
6. Si le projet a des utilisateurs finaux : colle la balise imprimée par
   `brancher.sh` dans la page qui leur convient (Jinja, React, HTML : c'est
   une balise `<script>`, rien d'autre), et ajoute-les au projet depuis
   l'app (Projets & membres → e-mail) une fois qu'ils se sont connectés une
   première fois.
7. Commit du dépôt courant (scripts, hook, settings.json, CLAUDE.md) avec le
   pourquoi ; bilan en trois lignes à Raphaël : ce qu'il peut faire, ce qu'il
   ne peut pas encore, ce qui lui reste (ajouter des membres, coller la balise).

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
