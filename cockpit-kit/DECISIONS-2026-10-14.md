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
