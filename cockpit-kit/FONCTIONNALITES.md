# L'écran visuel du cockpit — le QUOI, jamais le COMMENT

Ce fichier décrit ce que l'écran du cockpit doit permettre de FAIRE, sans
présumer du langage ni du framework. `cockpit-kit/migrations/` et
`cockpit-kit/scripts/` donnent la même base de données quel que soit le
projet ; CET écran, lui, doit être reconstruit dans l'idiome du projet
courant — React, Streamlit, HTML+JS, Java/Swing, un CLI... peu importe, tant
que les fonctionnalités ci-dessous sont là.

**Avant de construire quoi que ce soit** : identifie le stack réel du dépôt
courant (présence de `package.json` → JS/TS et son framework, de
`requirements.txt`/`pyproject.toml` avec `streamlit` → Streamlit, de `pom.xml`
→ Java, un simple `index.html` → HTML/JS vanilla, etc.) et construis l'écran
avec les briques NATIVES de ce stack — les composants shadcn/ui de Jarvis
n'existent pas ailleurs, ne les copie pas, retrouve l'ÉQUIVALENT du stack en
face. Une liste brute d'une ligne par chantier n'est PAS un cockpit : c'est le
point de départ que quasiment tous les stacks permettent en cinq minutes,
insuffisant tel quel.

## Les fonctionnalités attendues, par ordre d'impact mesuré sur Jarvis

Chacune vient d'un vrai reproche de l'utilisateur sur le cockpit d'origine,
gardé ici comme preuve que ce n'est pas du confort superflu.

### 1. Un résumé qui répond à "où j'en suis", sans tout lire

Sa plainte d'origine : « je ne sais plus où mettre le nez [...] je ne sais pas
ce qui avance, ce qui n'avance pas. » Toute l'information existait déjà dans
la liste des chantiers ; ce qui manquait était une VUE AGRÉGÉE.

Quatre nombres par thème/section, pas plus (une cinquième colonne oblige à
relire un tableau au lieu de lire une réponse) :
- ce qui BOUGE (réservé, quelqu'un est dessus maintenant) ;
- ce qui a été LIVRÉ récemment (fenêtre réglable — "aujourd'hui" par défaut) ;
- ce qui attend une décision ou un geste de l'utilisateur ;
- ce qui DORT (ouvert, personne dessus, rien qui bloque).

Un chantier bloqué ou reporté explicitement ne compte dans AUCUNE des
quatre colonnes — les compter forcerait une case qui ne dit pas la vérité.

### 2. Ce qui a changé depuis la dernière visite

Plusieurs sessions ou plusieurs jours peuvent s'écouler entre deux passages.
Un bandeau qui dit : combien de chantiers livrés, combien de nouveaux,
combien de messages ADRESSÉS à l'utilisateur (pas le bruit interne entre
sessions) — avec un bouton pour marquer "vu" qui ne se remet PAS à jour tout
seul à l'affichage (sinon le bandeau disparaît avant d'avoir été lu).

Le repère de dernière visite doit survivre au changement d'appareil/onglet
si l'utilisateur en a plusieurs (stocké côté serveur, pas seulement en local),
et ne doit JAMAIS reculer si deux sessions écrivent en même temps.

### 3. Un classement qui reflète comment l'utilisateur pense son projet, pas la base

Le champ `theme` (texte libre) permet de grouper sans imposer une liste
fermée à l'avance. Si le projet grossit, une table de "sections déclarées"
(nom, ordre, description) peut s'y ajouter — mais alors il FAUT un contrôle
qui signale un thème utilisé sans section déclarée (jamais une correction
automatique silencieuse, qui créerait des sections en double pour une faute
de frappe).

### 4. Chercher, filtrer, agir sur plusieurs chantiers à la fois

Sur une liste qui dépasse une vingtaine d'éléments (elle finit toujours par
y arriver), il faut au minimum : une recherche texte, un filtre par statut,
et la possibilité d'agir sur plusieurs chantiers en une seule opération
(changer leur statut, les archiver) plutôt qu'un par un — en UNE requête,
pas une boucle qui laisse le travail à moitié fait si la connexion coupe au
milieu.

### 5. Le fil de discussion d'un chantier, et le journal général

Chaque chantier peut porter sa propre conversation (questions, réponses,
comptes rendus) — visible en dépliant le chantier, avec la personne qui a
écrit et quand. Le journal général (toutes les entrées, tous chantiers
confondus) reste consultable à part, mais ne doit jamais mélanger ce qui est
adressé à l'utilisateur avec ce que des sessions se disent entre elles pour
se coordonner (une convention simple suffit : un préfixe reconnu du type
"Pour telle session :").

### 6. Ce qui attend une décision, séparé de tout le reste

Une carte ou un onglet séparé qui ne montre QUE les questions/actions non
répondues (`dev_log` où `kind` est `question` ou `action` et `answered_at`
est vide), avec les options proposées cliquables si il y en a, et un endroit
pour répondre en texte libre. C'est la fonctionnalité qui a le plus justifié
tout le reste : sans elle, une vraie décision se noie dans le bruit.

### 7. Les archives, consultables mais hors du chemin principal

Un chantier terminé quitte la liste active mais reste consultable (jamais de
perte). Repliées par défaut — la liste active est ce qu'on veut voir
d'abord.

### 8. Détection de doublons (si la création se fait en volume ou à la voix)

Seulement si le projet crée beaucoup de chantiers vite (dictée, import) :
un signal — jamais un blocage — quand un nouveau titre ressemble beaucoup à
un chantier déjà existant, ouvert OU archivé (proposer un vrai déjà-livré
évite de refaire un travail fait). Mesure le seuil sur les VRAIS titres du
projet avant de choisir un chiffre — un seuil deviné à l'instinct produit
soit trop de fausses alertes (plus lu du tout), soit aucune détection.

## Ce qui est explicitement HORS de ce cahier des charges

- Toute fonctionnalité vocale, mobile ou notification push — propre à Jarvis,
  aucun rapport avec le principe du cockpit.
- Un design imposé (couleurs, composants précis) — c'est au stack et au goût
  du projet de le décider, ce fichier ne parle que de fonctions.
- Les sessions autonomes déclenchées par une Routine horaire — utile si
  l'utilisateur le demande explicitement, jamais par défaut.
