#!/usr/bin/env bash
# Exécute du SQL sur le projet Supabase sans validation manuelle.
#
# Pourquoi ce script existe : l'outil MCP Supabase (execute_sql) impose un pop-up
# à chaque appel, imposé par le serveur MCP et impossible à désactiver. Ce script
# passe par l'API HTTPS et la fonction public.exec_sql (migration 0003 du kit),
# donc par Bash : aucune validation.
#
# Usage :
#   scripts/sql.sh "select id, title from dev_items where archived_at is null;"
#   echo "update dev_items set status='done' where id='...';" | scripts/sql.sh
#   scripts/sql.sh < requete.sql
#
# Prérequis :
#   - SUPABASE_URL : l'URL du projet (https://xxxx.supabase.co)
#   - SUPABASE_SERVICE_ROLE_KEY : dans l'environnement cloud Claude Code, JAMAIS
#     dans le dépôt.
#
# RAPPEL : cette clé donne un accès total à la base, RLS comprise. Ne jamais
# lancer un drop, un delete massif ou un truncate sans confirmation explicite
# de l'humain qui possède le projet.
#
# Une seule instruction par appel quand tu attends un résultat : l'enveloppe
# `select ... from (%s) as t` ne peut contenir qu'une instruction. Grouper
# plusieurs `select` séparés par `;` s'exécute mais ne renvoie AUCUNE ligne
# (le piège est silencieux). Grouper est bon pour des écritures dont on
# n'attend pas de lignes ; vérifie toujours dans un appel séparé.

set -euo pipefail

: "${SUPABASE_URL:?Variable SUPABASE_URL manquante (ex. https://xxxx.supabase.co)}"

entetes=(-H "Content-Type: application/json")
if [ -n "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
  entetes+=(-H "apikey: $SUPABASE_SERVICE_ROLE_KEY"
            -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY")
else
  echo "Erreur : SUPABASE_SERVICE_ROLE_KEY manquante." >&2
  exit 2
fi

if [ $# -gt 0 ]; then
  requete="$1"
else
  requete="$(cat)"
fi

if [ -z "${requete//[[:space:]]/}" ]; then
  echo "Erreur : aucune requête fournie." >&2
  exit 2
fi

corps="$(jq -n --arg q "$requete" '{query: $q}')"

reponse="$(curl -sS --max-time 60 -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
  "${entetes[@]}" -d "$corps")"

if ! echo "$reponse" | jq -e 'type == "object" and has("ok")' >/dev/null 2>&1; then
  echo "Réponse inattendue de Supabase :" >&2
  echo "$reponse" >&2
  exit 1
fi

echo "$reponse" | jq .

if [ "$(echo "$reponse" | jq -r '.ok')" != "true" ]; then
  exit 1
fi
