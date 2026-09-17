#!/usr/bin/env bash
# Poser une question à l'humain — DANS le cockpit, jamais dans un document externe.
#
# CE QUE ÇA REMPLACE, et pourquoi. Un artefact (fiche externe) publié pour poser
# une question vit hors du dépôt et hors de la base : son URL doit être recopiée
# quelque part sous peine d'être perdue pour la session suivante, et rien
# n'empêche deux sessions de poser la même question à deux endroits différents
# avec deux réponses différentes.
#
# Ici, la question est une ligne de `dev_log`. Le hook de démarrage l'injecte
# dans le contexte de CHAQUE session tant qu'elle n'a pas de réponse. Rien à
# recopier, rien à perdre.
#
# DEUX FAMILLES, à ne pas confondre :
#   --question (par défaut) : l'humain DÉCIDE. Propose des options avec --option.
#   --action : l'humain FAIT quelque chose de son côté (créer une clé, tester un
#              geste) et dit où il en est. Ne prend pas d'options.
#
# --pourquoi est OBLIGATOIRE, et ce n'est pas cosmétique : c'est aussi ce qui
# distingue une VRAIE question/action d'un compte rendu de session qui utiliserait
# le même `kind`. Sans lui, le cockpit ne peut pas savoir ce qui attend une
# décision humaine et ce qui est juste une note interne entre sessions.
#
# Usage :
#   scripts/demander.sh --question "On garde le mot-à-mot combien de temps ?" \
#     --pourquoi "Supprimer est irréversible, garder ne l'est pas." \
#     --chantier <uuid> \
#     --option "Sans limite|Rien n'est jamais supprimé.|recommande" \
#     --option "30 jours|Un mois glissant, puis on efface."
#
#   scripts/demander.sh --action --question "Dépose LA_CLE dans les secrets" \
#     --pourquoi "Sans elle, telle fonctionnalité ne peut pas se vérifier."

set -euo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

question=""
pourquoi=""
chantier=""
auteur="${DEV_SESSION:-$(git -C "$RACINE" rev-parse --abbrev-ref HEAD 2>/dev/null || echo inconnue)}"
kind="question"
options=()

while [ $# -gt 0 ]; do
  case "$1" in
    --question)  question="${2:-}"; shift 2 ;;
    --pourquoi)  pourquoi="${2:-}"; shift 2 ;;
    --chantier)  chantier="${2:-}"; shift 2 ;;
    --auteur)    auteur="${2:-}"; shift 2 ;;
    --option)    options+=("${2:-}"); shift 2 ;;
    --action)    kind="action"; shift ;;
    -h|--help)   sed -n '2,40p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "Argument inconnu : $1" >&2; exit 2 ;;
  esac
done

if [ -z "${question//[[:space:]]/}" ]; then
  echo "Erreur : --question est obligatoire." >&2
  exit 2
fi

if [ -z "${pourquoi//[[:space:]]/}" ]; then
  echo "Erreur : --pourquoi est obligatoire — c'est ce qui distingue une demande qui attend une décision d'un simple compte rendu de session." >&2
  exit 2
fi

if [ "$kind" = "action" ] && [ ${#options[@]} -gt 0 ]; then
  echo "Erreur : --action et --option ne vont pas ensemble. Pour une action, l'humain dit où il en est (fait / pas encore / ça bloque), il ne choisit pas." >&2
  exit 2
fi

# Le user_id devrait être passé explicitement pour un cockpit multi-utilisateur :
# adapte cette sous-requête à ton schéma (ici, on prend le premier utilisateur
# connu de dev_items, comme dans un cockpit mono-utilisateur).
sql="$(
  QUESTION="$question" POURQUOI="$pourquoi" CHANTIER="$chantier" AUTEUR="$auteur" KIND="$kind" \
  OPTIONS="$(printf '%s\n' ${options[@]+"${options[@]}"})" python3 - <<'PY'
import json, os, sys

def litteral(valeur):
    if valeur is None:
        return "null"
    return "$cockpit$" + valeur + "$cockpit$"

options = []
for ligne in os.environ["OPTIONS"].splitlines():
    if not ligne.strip():
        continue
    morceaux = ligne.split("|")
    libelle = morceaux[0].strip()
    if not libelle:
        continue
    aide = morceaux[1].strip() if len(morceaux) > 1 and morceaux[1].strip() else None
    recommande = len(morceaux) > 2 and morceaux[2].strip().lower().startswith("recommand")
    options.append({"cle": libelle, "libelle": libelle, "aide": aide, "recommande": recommande})

if any("$cockpit$" in (o["libelle"] + (o["aide"] or "")) for o in options):
    sys.exit("Une option contient le délimiteur $cockpit$ : renomme-la.")

question = os.environ["QUESTION"]
pourquoi = os.environ["POURQUOI"] or None
chantier = os.environ["CHANTIER"] or None
for texte in (question, pourquoi or "", os.environ["AUTEUR"]):
    if "$cockpit$" in texte:
        sys.exit("Le texte contient le délimiteur $cockpit$ : reformule.")

print(f"""insert into dev_log (user_id, item_id, author, kind, body, pourquoi, options)
values (
  (select user_id from dev_items limit 1),
  {litteral(chantier) if chantier else 'null'}{'::uuid' if chantier else ''},
  {litteral(os.environ["AUTEUR"])},
  {litteral(os.environ["KIND"])},
  {litteral(question)},
  {litteral(pourquoi) if pourquoi else 'null'},
  {litteral(json.dumps(options, ensure_ascii=False)) + '::jsonb' if options else 'null'}
);""")
PY
)"

printf '%s' "$sql" | "$RACINE/scripts/sql.sh" > /dev/null

"$RACINE/scripts/sql.sh" "select id, kind, author, to_char(created_at, 'DD/MM HH24:MI') as pose_a, left(body, 80) as question from dev_log order by created_at desc limit 1"

cat <<'FIN'

La question est posée et sera injectée au démarrage de chaque session tant
qu'il n'y a pas de réponse — n'insiste pas ailleurs, et ne la repose pas dans
un document externe.
FIN
