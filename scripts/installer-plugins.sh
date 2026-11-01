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
# 2.1.316. OmniRoute volontairement absent (bascule sur d'autres modèles,
# demande une page locale et des clés tierces : décision de Raphaël en attente).

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
LIST
else
  ko "commande claude introuvable : ponytail, agent-skills"
fi

# Graphify : paquet PyPI « graphifyy » (deux y), la commande s'appelle graphify.
if pip3 install -q --user graphifyy >/dev/null 2>&1 \
   || pip3 install -q --user --break-system-packages graphifyy >/dev/null 2>&1; then
  if graphify install --platform claude >/dev/null 2>&1; then ok graphify; else ko "graphify install"; fi
else
  ko "pip install graphifyy"
fi
exit 0
