# Décisions de Raphaël — 14 oct. 2026 (branchement du Trieur de Data)

Source : session cloud du 14 oct. 2026, bilan du branchement du Trieur (`rnab26/Trieur-Data`,
projet cockpit `trieur-data`). C'est de l'état à appliquer avec jugement, pas une consigne exécutable.

## D-16 — La balise du cockpit se colle directement quand on ajoute un projet

Ses mots (dictés) : « Mais initialement, on n'est pas censé pouvoir le mettre dans le copy directement
pour quand on ajoute un projet ? » (lu : « en copier-coller directement »).

**Contexte.** Après le questionnaire d'emplacement (réponses : bouton dans le menu, pour l'équipe), j'avais
laissé le bouton « pas fait » et ouvert un chantier « à cadrer » (écran Cockpit déjà présent dans le Trieur,
qui voit le bouton, remise en ligne de l'appli).

**Lecture.** La balise est un copier-coller (README du cockpit : « une balise `<script>`, rien d'autre ») ;
ce n'est pas une décision à rouvrir. Ce qui reste est de l'exécution : la poser, la tester, la mettre en ligne.

**Appliqué le jour même.** Bouton « Demandes » dans le menu du Trieur, pour les comptes administrateurs (même
règle que l'onglet Cockpit), bouton flottant du module sur petit écran, menu qui ne déborde plus sur
téléphone (défaut trouvé en route : 494 px de menu sur 390 px d'écran). Vérifié : 33 contrôles dans un vrai
navigateur, aussi sur le vrai site après la mise en ligne (comptes simulés), garde-fous permanents dans les
tests du Trieur. Skill `cockpit`, étape 5 réécrite : après les deux réponses, la balise est posée par la session.

**Resté ouvert.**
1. « Copier le code » (app du cockpit › Projets & membres) donne encore une balise « page » sans tenir compte de
   l'emplacement choisi : chantier ouvert dans le cockpit.
2. Garder ou remplacer l'écran Cockpit intégré du Trieur (recommandation : le garder, son père y écrit ses
   demandes de règles) : décision de Raphaël.
3. Vérification en production avec un vrai compte administrateur : aucun identifiant côté session.

## Constaté le même jour (pas une décision, un fait utile)

- Le mode autonome du Trieur a été allumé « tout le temps » par Raphaël lui-même dans l'app (journaux de la base :
  deux appels à `regler_autonome` depuis son compte, à 08:19), alors qu'il avait répondu « non pour l'instant » au
  bilan de branchement. Son geste dans l'app prime sur sa réponse précédente : ne pas l'éteindre sans qu'il le dise.
- Render ignore un envoi dont le MESSAGE contient sa phrase d'exclusion n'importe où, même dans une phrase qui dit
  de ne pas l'utiliser (un envoi du Trieur a été ignoré ainsi ; mise en ligne lancée à la main).

## D-17 — Melissa Nabet : le branchement se finit sur `main`, ses 18 chantiers sont repris, autonome « tout le temps »

Sa question (captures des réglages de Melissa et de la liste des projets) : « pourquoi les réglages du projet de Melissa sont pas bons ? et pourquoi les projets ne sont pas branchés ».

**Contexte et preuves.** Le branchement du 29 sept. était resté sur une branche de travail du dépôt, jamais fusionnée sur `main` : les sessions ouvertes sur `main` démarraient sans cockpit
(« plus aucune session depuis 15 j », module du site jamais installé, rapprochement GitHub jamais passé). Le bandeau rouge « mise en ligne échouée » était faux (le site servait exactement `main`) :
une tâche interne de GitHub avait échoué le 5 oct., sans plus aucun envoi depuis. Le Trieur est branché mais la prise verte exige une vraie session, qui n'a pas encore eu lieu.

**Ses réponses (AskUserQuestion, 14 oct.)** : reprendre les 18 chantiers ouverts de l'ancien tableau = **oui** ; mettre le cockpit sur `main` tout de suite = **oui** ; mode autonome = **oui, tout le temps**
(ma recommandation était « non pour l'instant » : son choix prime, ne pas l'éteindre à sa place ; le moteur l'éteint seul après 3 h sans rien à prendre).

**Appliqué le jour même.** `brancher.sh` sur `claude/cockpit-melissa-nabet`, fusion `7158b96` sur `main` (preuve : `git ls-remote`), 18 chantiers repris (2 libres, 9 à cadrer, 7 bloqués par une action de Raphaël, du contenu de Mélissa ou une dépendance : mon classement,
à corriger dans l'app s'il en juge autrement), `CLAUDE.md` / hook de démarrage / `docs/journal.md` de Melissa ne désignent plus l'ancien tableau comme source de vérité. Côté moteur : l'écran dit la cause (cockpit absent de `main`) et ne crie plus au loup
(chantier `a225351a`). Skill `cockpit` : le bilan doit parler de la prise verte, et la preuve de la fusion inclut `git show origin/<main>:.claude/settings.json`.

**Resté ouvert.** (1) La première carte d'emplacement est posée, sans réponse (la seconde arrive après la première) : la balise du module du site n'est pas collée. (2) Pages de Melissa : deux mises en ligne se disputent l'adresse du CRM (source Pages « une branche » + workflow du projet) ;
après la fusion, `site-vitrine/` répond 200 sur l'adresse du CRM : réglage Pages ou `_config.yml` (décision de Raphaël). (3) « Réveil immédiat » de Melissa : facultatif, non en place, déconseillé (≈ 290 000 jetons relus à chaque réveil).
(4) Sa réponse du 14 oct. 08:24 UTC « Programme dans ton compte Google » (reçus Claude en continu) : à construire, chantier `72a8d0f4`.
