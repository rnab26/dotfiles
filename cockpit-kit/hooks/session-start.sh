#!/usr/bin/env bash
# Injecte l'état vivant du cockpit dans le contexte, à chaque démarrage de session.
#
# Pourquoi : sans ça, il faut coller un prompt du type « lis les chantiers et le
# journal » à chaque ouverture de session. Ce hook le fait à la place. Il lit la
# BASE, pas un fichier : le contenu est donc toujours à jour, même si le dépôt
# n'a pas bougé depuis des jours.
#
# Le hook ne doit JAMAIS faire échouer le démarrage d'une session. Toute erreur
# est rattrapée et transformée en note explicative dans le contexte.

set -uo pipefail

RACINE="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SQL="$RACINE/scripts/sql.sh"

interroger() {
  "$SQL" "$1" 2>/dev/null \
    | jq -r 'if (.rows | type) != "array" or (.rows | length) == 0 then ""
             else (.rows[0] | if type == "object" then (to_entries[0].value // "") else (. // "") end)
             end' 2>/dev/null \
    || echo ""
}

emettre() {
  jq -n --arg c "$1" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
}

if [ ! -x "$SQL" ]; then
  emettre "Cockpit non chargé : $SQL est introuvable ou non exécutable. Lis les chantiers et le journal à la main (voir CLAUDE.md)."
  exit 0
fi

# Groupés par thème, pas à plat : un sujet se traite en entier, pas chantier par
# chantier. La priorité haute passe devant.
chantiers=$(interroger "select coalesce(string_agg(bloc, chr(10) || chr(10) order by urgence, taille desc, th), '(aucun)') as t from (select coalesce(nullif(trim(theme), ''), 'À classer') as th, min(case when priority = 'high' then 1 else 2 end) as urgence, count(*) as taille, '### ' || coalesce(nullif(trim(theme), ''), 'À classer') || ' (' || count(*) || ')' || chr(10) || string_agg(format('- %s | %s | %s | %s%s%s', id, title, status, priority, case when claimed_by is not null and claim_expires_at > now() then ' | PRIS PAR ' || claimed_by else '' end, case when coalesce(notes, '') <> '' then chr(10) || '    ' || left(replace(notes, chr(10), ' '), 160) else '' end), chr(10) order by priority desc, created_at) as bloc from dev_items where archived_at is null group by 1) g")

# CE QUI ATTEND UNE DÉCISION HUMAINE — jamais dans un document externe, toujours
# dans dev_log. Revient ici tant qu'il n'y a pas de réponse : aucune session ne
# peut la reposer sans le savoir, ni avancer en croyant qu'elle est tranchée.
attentes=$(interroger "select coalesce(string_agg(format('- %s | %s | pose le %s%s%s%s%s', case when kind = 'action' then 'IL DOIT LE FAIRE' else 'IL DOIT DECIDER' end, author, to_char(created_at, 'DD/MM HH24:MI'), case when item_id is not null then ' | chantier ' || item_id else '' end, chr(10) || '    ' || left(replace(body, chr(10), ' '), 300), case when coalesce(pourquoi, '') <> '' then chr(10) || '    pourquoi : ' || left(replace(pourquoi, chr(10), ' '), 200) else '' end, case when jsonb_typeof(options) = 'array' then chr(10) || '    options proposees : ' || (select string_agg(o->>'libelle' || case when o->>'recommande' = 'true' then ' (recommandee)' else '' end, ' | ') from jsonb_array_elements(options) o) else '' end), chr(10) order by case when kind = 'action' then 0 else 1 end, created_at), '(rien)') as t from dev_log where answered_at is null and kind in ('question', 'action')")

# SES RÉPONSES, à part et sur une fenêtre plus large que le journal général : le
# journal n'en injecte que douze entrées toutes familles confondues, une réponse
# donnée avant-hier en sortirait et la question se reposerait pour rien.
reponses=$(interroger "select coalesce(string_agg(format('- %s%s%s', to_char(created_at, 'DD/MM HH24:MI'), case when item_id is not null then ' | chantier ' || item_id else '' end, chr(10) || '    ' || left(replace(body, chr(10), ' '), 400)), chr(10) order by created_at desc), '(aucune)') as t from (select * from dev_log where kind = 'reponse' order by created_at desc limit 12) r")

journal=$(interroger "select coalesce(string_agg(format('- %s | %s | %s%s%s', to_char(created_at, 'DD/MM HH24:MI'), author, kind, case when answered_at is not null then ' (repondu)' else '' end, chr(10) || '    ' || left(replace(body, chr(10), ' '), 300)), chr(10) order by created_at desc), '(vide)') as t from (select * from dev_log order by created_at desc limit 12) d")

livres=$(interroger "select coalesce(string_agg(format('- %s (%s)', title, to_char(archived_at, 'DD/MM')), chr(10) order by archived_at desc), '(aucun)') as t from (select * from dev_items where archived_at is not null order by archived_at desc limit 8) a")

if [ -z "$chantiers" ] && [ -z "$journal" ]; then
  emettre "Cockpit non chargé : la base n'a rien renvoyé. Réessaie à la main avec scripts/sql.sh et signale-le si ça échoue encore."
  exit 0
fi

contexte=$(cat <<FIN
# État du projet au démarrage de cette session

Chargé automatiquement depuis la base. Ne fais pas répéter ce qui est déjà écrit
ci-dessous. Les notes sont tronquées — utilise \`scripts/sql.sh\` pour le détail
complet d'un chantier.

## Chantiers en cours, groupés par thème
Format : id | titre | statut | priorité | réservation
Marqueurs en tête des notes (convention à documenter dans le CLAUDE.md du projet) :
[À CADRER AVANT DE COMMENCER] = ne pas coder, en discuter d'abord avec l'humain.
[LIBRE] = à prendre sans rien demander.

${chantiers:-(non chargé)}

## Ce qui attend une décision ou un geste humain
${attentes:-(non chargé)}

## Ses dernières réponses (fenêtre large, pour ne pas les faire répéter)
${reponses:-(non chargé)}

## Journal de bord (12 dernières entrées)
${journal:-(non chargé)}

## Livré récemment
${livres:-(non chargé)}

## Avant de commencer

1. **Réserve** un chantier avant d'y toucher :
   \`select claim_dev_item('<id>', '<nom de ta branche>', 120);\`
   \`false\` = une autre session est dessus, prends-en un autre.
2. **Relis toujours les notes dans un appel SÉPARÉ avant de les modifier** —
   \`update ... set notes = ...\` ÉCRASE tout : lis d'abord, complète ensuite.
3. **Une trouvaille non traitée devient un chantier** (ligne de \`dev_items\`),
   jamais juste une remarque perdue dans le journal.
4. **Libère la réservation** en terminant :
   \`select release_dev_item('<id>', '<ta branche>');\`
FIN
)

emettre "$contexte"
