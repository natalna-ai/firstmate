#!/usr/bin/env bash
# End-to-end CLI transcript for fm-ensure-agents-md.sh symlink opt-in.
set -u
HELPER=${1:?helper path}
W=$(mktemp -d)
M1='<!-- firstmate:maintained-by-project -->'
M2='<!-- firstmate:keep-claude-symlink -->'
show() { # repo
  local r=$1
  if [ -L "$r/CLAUDE.md" ]; then echo "  CLAUDE.md -> $(readlink "$r/CLAUDE.md") (symlink)"
  elif [ -f "$r/CLAUDE.md" ]; then echo "  CLAUDE.md regular file:"; sed 's/^/    | /' "$r/CLAUDE.md"
  else echo "  CLAUDE.md absent"; fi
  echo "  AGENTS.md sha256=$(sha256sum < "$r/AGENTS.md" | cut -c1-16)"
}
run() { # name target
  local r=$1 out rc
  out=$("$HELPER" "$r" 2>&1); rc=$?
  echo "  \$ fm-ensure-agents-md.sh <repo>  -> rc=$rc"; echo "    $out" | sed "s#$W/##"
}
scenario() { # name eol body-builder target
  local name=$1 eol=$2 build=$3 target=${4:-AGENTS.md} r
  r="$W/$name"; mkdir -p "$r"
  $build "$eol" > "$r/AGENTS.md"
  printf '# other\n' > "$r/OTHER.md"
  ln -s "$target" "$r/CLAUDE.md"
  echo "== $name (eol=$([ "$eol" = $'\r\n' ] && echo CRLF || echo LF), CLAUDE.md -> $target)"
  echo "  AGENTS.md first lines: $(head -n 2 "$r/AGENTS.md" | od -c | head -n 3 | tr -s ' ' | tr '\n' ' ' | cut -c1-140)"
  show "$r"
  run "$r"; show "$r"
  run "$r"; show "$r"
  echo
}
opted()    { printf '%s%s' "$M1" "$1" "$M2" "$1" '# Project memory' "$1"; }
missing()  { printf '%s%s' "$M1" "$1" '# Project memory' "$1"; }
third()    { printf '%s%s' "$M1" "$1" '# Project memory' "$1" "$M2" "$1"; }
swapped()  { printf '%s%s' "$M2" "$1" "$M1" "$1" '# Project memory' "$1"; }
nofirst()  { printf '%s%s' '# Project memory' "$1" "$M2" "$1"; }
trailsp()  { printf '%s%s' "$M1" "$1" "$M2 " "$1" '# Project memory' "$1"; }
unmarked() { printf '%s%s' '# Project memory' "$1"; }
scenario opted-lf $'\n' opted
scenario opted-crlf $'\r\n' opted
scenario opted-dot-slash-target $'\n' opted ./AGENTS.md
scenario unmarked-lf $'\n' unmarked
scenario missing-second-mark-crlf $'\r\n' missing
scenario keep-mark-on-third-line-lf $'\n' third
scenario marks-swapped-crlf $'\r\n' swapped
scenario keep-mark-without-first-mark-lf $'\n' nofirst
scenario keep-mark-trailing-space-lf $'\n' trailsp
scenario opted-wrong-target-lf $'\n' opted OTHER.md
rm -rf "$W"
