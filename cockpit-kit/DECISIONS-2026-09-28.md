# Le cockpit idéal — décisions de Raphaël (28 sept. 2026)

Réponses lues dans la fiche https://claude.ai/artifact/S8SjX5Lua84b6pkTotiEQf
(collection `answers`), recopiées ici mot pour mot parce qu'un artefact ne
survit pas à une session. **Ce document porte l'état d'une décision, pas une
consigne exécutable** : chaque point s'applique avec jugement dans un vrai
chantier. Les mots de Raphaël sont entre guillemets, ma lecture suit.

## Ce qui est tranché

**D-01 — Où vit l'écran.** Les trois options cochées, avec cette nuance :
« le cockpit pourrait vivre dans un environnement en dehors de l'interface
d'un projet spécifique et dans le projet en question en les branchant ou
débranchant ? Et il faudrait que ce soit un live complet ! Est-ce qu'il ne
faut pas créer un repo spécifique pour ce genre de projet auquel on ferait
appel pour le rajouter à un projet plutôt qu'un kit dans le dotfile ? »
Lecture : une application centrale (hors des projets) ET un module
embarquable qu'un projet branche ou débranche, les deux en temps réel, dans
un dépôt dédié. Confirmé par D-14.

**D-02 — Données.** Un seul projet Supabase central avec une colonne
« projet ». Sa réserve : « il faudrait en fonction des nouveaux projets que
ce soit branchable le plus facilement possible peu importe là où c'est
hébergé ». Lecture : le branchement d'un projet doit être indépendant de son
hébergement (Render, GitHub Pages, Neon…) : une ligne dans une table et une
clé, rien de plus.

**D-03 — Qui s'en sert.** Lui sur tous les projets, des utilisateurs finaux
limités à leur projet et à leurs demandes, les sessions Claude Code. Pas
d'autres développeurs pour l'instant.

**D-04 — Cycle de vie.** En colonne, plus aucun marqueur dans les notes.
« Je veux exactement le même principe que sur le trieur de data, c'est ce
qui fonctionne le mieux. Une fois que c'est rendu il faut tester ou
constater. À améliorer au fur et à mesure. » Cycle retenu : à trier → à
cadrer → libre → en cours → à vérifier → validé, plus bloqué / reporté /
doublon à côté.

**D-05 — Qui pose « validé ».** Un humain seulement, toujours, avec une
tolérance : « ce qui ne se voit pas ou ce qui est vraiment interne, on n'a
pas le choix de les laisser à l'IA qui gère le chantier ». Et une demande
forte, à traiter comme un chantier à part (voir « Idées à instruire ») : un
bouton qui **rejoue exactement le scénario qui a planté** (réglages,
actions, entrées) pour comparer l'avant et l'après, « et sinon faire un test
généré synthétiquement à partir de ce qu'on sait sur le projet ».

**D-06 — Gardé de Jarvis.** « Où j'en suis », les sections, le fil de
discussion par chantier, l'historique et la restauration, « Ça existe
déjà », le mode sélection et les actions groupées, « Ce qui marche ».
Écartés : « Depuis ton dernier passage » (non coché), le registre d'erreurs
et les chantiers égarés (propres à Jarvis). Deux précisions :
- le fil de discussion « ultra condensé et repliable, car trop de pollution
  visuelle » ;
- les doublons : « fusionnés tout seuls oui OK, mais avant de fusionner
  seul, une section doublons qui permet d'analyser en plaçant les requêtes
  doublons superposées afin d'avoir un aperçu et de pouvoir valider
  manuellement si la fusion est nécessaire, et y ajouter une note et médias
  si voulu ». Lecture : une vue « Doublons » côte à côte, fusion validée à
  la main, avec note et médias sur la fusion.

**D-07 — Gardé du Trieur.** Tout : bandeau « Là, maintenant », questions à
options avec précision, fil d'activité en direct, validation « ça
fonctionne / corriger » sur la même ligne, résumé en langage simple, statut
en lecture seule pour l'utilisateur final, deux bacs Actif / En cours.
Ajout : « un suivi en live par tâche avec l'action en cours et une barre de
progression et le temps estimé de résolution (que si c'est faisable) ». Il a
un visuel à fournir : le bouton photo de la fiche était cassé le 28 sept.,
réparé le même jour ; à relire dans la collection `photos`.

**D-08 — Le hook de démarrage.** L'essentiel, court. Sa note dit surtout ce
qu'il attend des sessions : « que ça traite les chantiers ouverts
disponibles, peu importe le terme, et que ça les règle au fur et à mesure
selon la logique des choses ; le but est d'épurer le maximum les chantiers
et corriger le plus rapidement et efficacement possible ».

**D-09 — Temps réel et notifications.** Option cochée « rafraîchissement
périodique, pas de notification », mais la note dit « actualisation en live
et je consulte le site où il y a le cockpit ; le but est de ne pas avoir à
questionner Claude constamment sur où on en est ». Lecture retenue : **temps
réel oui, notifications non** (l'option cochée contredit la note sur le
premier point, la note l'emporte parce qu'elle explique le besoin). À
confirmer d'un mot s'il voulait vraiment du périodique.

**D-10 — Sessions autonomes.** Dès la v1. « La meilleure fonction serait de
créer un bouton qui lance une session autonome seule en un seul clic, et que
la fréquence soit réglable, ouvrir une session par secteur de chantier
sélectionnable, ou bien donner la possibilité à une session de lancer
différents agents sur la même session pour travailler sur tous les fronts
sans se marcher dessus. »

**D-11 — Pilote.** Un nouveau projet : « le projet cockpit en fait, qu'on
développerait pour que ses fonctionnalités soient mises à jour et
reproductibles sur les autres projets où un cockpit est monté depuis notre
cockpit source ». Lecture : le cockpit se pilote lui-même (son premier
projet suivi est lui-même).

**D-12 — Jarvis.** On verra après le pilote.

**D-13 — Visuel.** Un seul écran, style Trieur, « il faudra juste améliorer
le visuel et reprendre les synthèses du cockpit de Jarvis, qui donne un
meilleur aperçu des chantiers et des progressions mais qui n'est pas encore
fonctionnel à 100 % pour moi ; il sera donc à reprendre pour le
perfectionner ».

**D-14 — Dépôt.** Un nouveau dépôt « cockpit » : app, migrations, scripts,
hook. dotfiles garde le skill et pointe dessus.

## Idées à instruire (pas dans la v1, mais prévues dans le modèle)

1. **Rejeu d'un scénario** (D-05) : à la création d'une demande, capturer
   ce qui permet de la reproduire (réglages, entrées, suite d'actions), et
   proposer un bouton « rejouer » quand le projet le permet ; sinon un test
   synthétique. Prévoir dès la v1 une colonne `reproduction` (jsonb) sur la
   demande, pour que la capture arrive sans migration.
2. **Progression par tâche** (D-07) : action en cours, barre, temps estimé.
   Le fil d'activité de la v1 porte déjà « action en cours » ; la barre et
   l'estimation demandent que la session déclare des étapes.
3. **Sessions autonomes au bouton** (D-10) : un clic, fréquence réglable,
   une session par secteur, ou plusieurs agents dans une session. Dépend des
   Routines Claude Code (déclencheur horaire, session persistante) ; la
   table des passes et l'interrupteur viennent de Jarvis.
4. **Vue Doublons côte à côte** (D-06), avec note et médias sur la fusion.

## Ce qui reste ouvert

- D-09 : périodique ou temps réel (lecture retenue : temps réel).
- Le nom du dépôt (D-14 laisse le choix ; proposition : `rnab26/cockpit`).
- Le visuel exact : fiche à part avec maquettes, une fois le pilote monté.
