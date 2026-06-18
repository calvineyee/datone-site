#!/usr/bin/env bash
# predeploy-check.sh — deterministic content gate for datone-site.
# Blocks deploy if spec.html / faq.html contain fabricated/forbidden claims,
# or are missing the verified corrected phrasing, or robots.txt lacks AI crawlers.
# Exit 1 = do NOT deploy. Added 2026-06-17 after an agent pipeline repeatedly
# tried to ship un-corrected (fabricated) spec content. Trust this, not "✅ done".
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
FAIL=0

FORBIDDEN='discover each other|negotiate tasks|negotiate|intermediary fees|export or delete|data portability|multi-party workflows'

check_forbidden() {
  local f="$1"
  if [ ! -f "$DIR/$f" ]; then echo "  ✗ MISSING file: $f"; FAIL=1; return; fi
  local hits; hits=$(grep -nEi "$FORBIDDEN" "$DIR/$f")
  if [ -n "$hits" ]; then
    echo "  ✗ $f has FORBIDDEN phrases:"; echo "$hits" | sed 's/^/       /'; FAIL=1
  else
    echo "  ✓ $f: no forbidden phrases"
  fi
}

check_required() {
  local f="$1"; shift
  for phrase in "$@"; do
    if ! grep -qF "$phrase" "$DIR/$f" 2>/dev/null; then
      echo "  ✗ $f MISSING required: \"$phrase\""; FAIL=1
    fi
  done
}

echo "=== datone-site predeploy content gate ==="
check_forbidden spec.html
check_forbidden faq.html
check_required spec.html "delegated authorization and recorded handoffs" "owns or monetizes" "github.com/artsolute/datone"
check_required faq.html "delegated authorization and recorded handoffs"
if grep -qF "ClaudeBot" "$DIR/robots.txt" 2>/dev/null && grep -qF "CCBot" "$DIR/robots.txt" 2>/dev/null; then
  echo "  ✓ robots.txt: ClaudeBot + CCBot present"
else
  echo "  ✗ robots.txt missing ClaudeBot/CCBot"; FAIL=1
fi
echo "==========================================="
if [ "$FAIL" -ne 0 ]; then echo "RESULT: ❌ FAIL — do NOT deploy"; exit 1; fi
echo "RESULT: ✅ PASS — safe to deploy"
