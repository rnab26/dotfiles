#!/usr/bin/env bash
# Installe les plugins Claude Code de Raphaël dans la session cloud courante.
#
# Pourquoi : la machine d'une session cloud est effacée à la fin ; ce qui est
# installé à la main disparaît. Le script d'installation de l'environnement
# cloud (« Setup script ») lance ce fichier à chaque nouvelle session, sur
# tous les dépôts :
#   curl -fsSL https://raw.githubusercontent.com/rnab26/dotfiles/main/scripts/installer-plugins.sh | bash
# Une seule source de vérité : ajouter / retirer un plugin = modifier CE
# fichier sur main, la session suivante le prend.
#
# Idempotent, et ne fait JAMAIS échouer le démarrage : un plugin qui ne
# s'installe pas affiche un avertissement, la session démarre quand même.
#
# Source des commandes : fiche « Les 4 plug-ins Claude Code à installer pour
# vibecoder » (@buildwithmathias), vérifiées le 2026-11-01 avec Claude Code
# 2.1.316. Instagram (13 skills /ig-*, Jake Schincariol, MIT) ajouté le
# 2026-11-18 à la demande de Raphaël, testé avec Claude Code 2.1.327.
# OmniRoute volontairement absent (bascule sur d'autres modèles, demande une
# page locale et des clés tierces : décision de Raphaël en attente).

export PATH="$HOME/.local/bin:/opt/node22/bin:$PATH"
ok() { echo "[plugins] OK  $*"; }
ko() { echo "[plugins] ÉCHEC $* (la session démarre quand même)"; }

if command -v claude >/dev/null 2>&1; then
  # marketplace (dépôt GitHub) | plugin@marketplace
  while read -r repo plugin; do
    [ -z "$repo" ] && continue
    claude plugin marketplace add "$repo" >/dev/null 2>&1 || true   # déjà ajoutée = pas grave
    if claude plugin install "$plugin" >/dev/null 2>&1; then ok "$plugin"; else ko "$plugin"; fi
  done <<'LIST'
DietrichGebert/ponytail ponytail@ponytail
addyosmani/agent-skills agent-skills@addy-agent-skills
Jakeschincariol/instagram-agent-skill instagram-agent@instagram-agent-skill
heygen-com/hyperframes hyperframes@hyperframes
LIST
else
  ko "commande claude introuvable : ponytail, agent-skills, instagram-agent, hyperframes"
fi

# Skills de l'annuaire skills.sh (guide « Find Skills », 18 nov. 2026) : dépôt | skills.
# Volontairement absents : pptx, pdf, docx, xlsx, canvas-design (déjà fournis par
# anthropic-skills) et brand-guidelines (charte graphique d'Anthropic, pas la nôtre).
# </dev/null : npx lit l'entrée standard et viderait la liste sinon.
while read -r repo skills; do
  [ -z "$repo" ] && continue
  if npx -y skills add "$repo" -s $skills -a claude-code -g -y --copy </dev/null >/dev/null 2>&1; then
    ok "$skills"; else ko "$repo ($skills)"; fi
done <<'SKILLS'
vercel-labs/skills find-skills
anthropics/skills frontend-design
nextlevelbuilder/ui-ux-pro-max-skill ui-ux-pro-max
coreyhaines31/marketingskills copywriting seo-audit social
emilkowalski/skills apple-design
SKILLS

# Graphify : paquet PyPI « graphifyy » (deux y), la commande s'appelle graphify.
if pip3 install -q --user graphifyy >/dev/null 2>&1 \
   || pip3 install -q --user --break-system-packages graphifyy >/dev/null 2>&1; then
  if graphify install --platform claude >/dev/null 2>&1; then ok graphify; else ko "graphify install"; fi
else
  ko "pip install graphifyy"
fi
exit 0
