#!/usr/bin/env bash
# Regenerate the site's terminal content from REAL decree output.
#
# Two outputs, both real (never hand-edited):
#   src/captures/0N-*.ansi      full example scenarios (for /examples)
#   src/captures/snippets/*.ansi focused single commands (hero + capability pages)
#
# Source of truth for corpora + commands is the sibling decree repo's examples/.
# Run from anywhere:  bash scripts/capture.sh
# Override the binary: DECREE=/path/to/decree bash scripts/capture.sh
set -uo pipefail

SITE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EX_DIR="${EX_DIR:-$SITE_DIR/../decree/examples}"
export DECREE="${DECREE:-decree}"
OUT="$SITE_DIR/src/captures"
SNIP="$OUT/snippets"
mkdir -p "$OUT" "$SNIP"

if ! command -v "$DECREE" >/dev/null 2>&1 && [ ! -x "$DECREE" ]; then
  echo "error: decree binary not found (set DECREE=...)" >&2; exit 1
fi
if [ ! -d "$EX_DIR" ]; then
  echo "error: decree examples not found at $EX_DIR (set EX_DIR=...)" >&2; exit 1
fi

echo "decree: $($DECREE --version 2>/dev/null)"
echo "examples: $EX_DIR"
echo

# ── 1. Full example scenarios → captures/0N-*.ansi ───────────────────────────
for s in "$EX_DIR"/0*.sh; do
  name="$(basename "$s" .sh)"
  DECREE="$DECREE" bash "$s" > "$OUT/$name.ansi" 2>&1
  echo "captured  $name.ansi ($(wc -l < "$OUT/$name.ansi" | tr -d ' ') lines)"
done

# ── 2. Focused single-command snippets → captures/snippets/*.ansi ────────────
# Reuse the examples' tiny helpers (make_demo_repo + the `dc` pretty-runner).
# shellcheck disable=SC1090
source "$EX_DIR/_lib.sh"

# quiet corpus setup: everything except `dc` output is noise for a focused snippet
q() { "$@" >/dev/null 2>&1; }

# write a focused snippet, capturing BOTH streams so it matches what a user sees
# (decree prints the "exit 1: findings present" notice to stderr).
snip() { local out="$1"; shift; dc "$@" > "$SNIP/$out" 2>&1; }

spec() { # spec <file> <heredoc-on-stdin>
  mkdir -p decree/spec src/auth
  cat > "decree/spec/$1"
}

# Corpus A — one decision governs tokens.py; charge.py is ungoverned  (why)
gen_why() {
  q make_demo_repo
  spec spec-00000000000000000000000001-jwt-token-storage.md <<'EOF'
---
id: SPEC-00000000000000000000000001
status: implemented
date: 2026-05-10
governs:
  - src/auth/tokens.py
---

# SPEC-00000000000000000000000001 JWT token storage

## Overview

Access tokens are stored hashed at rest; the raw token never lands in the DB.
EOF
  echo "def store(token): ..." > src/auth/tokens.py
  echo "def charge(): ..."     > src/auth/charge.py
  q git add -A; q git commit -qm "init: auth"
  q "$DECREE" index rebuild
  snip why-hit.ansi    why src/auth/tokens.py
  snip why-json.ansi   why src/auth/tokens.py --json
  snip why-abstain.ansi why src/auth/charge.py
}

# Corpus B — two decisions claim tokens.py (one shipped, one in-flight w/ ACs)
#            (intent-check conflict + intent-review diff gate)
gen_conflict() {
  q make_demo_repo
  spec spec-00000000000000000000000001-jwt-token-storage.md <<'EOF'
---
id: SPEC-00000000000000000000000001
status: implemented
date: 2026-05-10
governs:
  - src/auth/tokens.py
---

# SPEC-00000000000000000000000001 JWT token storage

## Overview

Tokens are stored hashed at rest.
EOF
  spec spec-00000000000000000000000002-token-rotation.md <<'EOF'
---
id: SPEC-00000000000000000000000002
status: draft
date: 2026-05-10
governs:
  - src/auth/tokens.py
---

# SPEC-00000000000000000000000002 Token rotation policy

## Overview

Tokens rotate on a schedule and old tokens are revoked.

## Acceptance Criteria

- [ ] Rotation job runs on schedule
- [ ] Old tokens revoked on rotation
EOF
  echo "def store(token): ..." > src/auth/tokens.py
  q git add -A; q git commit -qm "init: auth"
  q "$DECREE" index rebuild
  snip intent-check-conflict.ansi \
    intent-check --plan "Change token refresh storage" --files src/auth/tokens.py
  echo "def store(token): rotate()  # the change" > src/auth/tokens.py
  git diff > change.diff 2>/dev/null
  snip intent-review-conflict.ansi intent-review --diff change.diff
}

# Corpus C — one decision governs the contested file (parallel live overlap)
gen_isolate() {
  q make_demo_repo
  spec spec-00000000000000000000000001-jwt-token-storage.md <<'EOF'
---
id: SPEC-00000000000000000000000001
status: implemented
date: 2026-05-10
governs:
  - src/auth/tokens.py
---

# SPEC-00000000000000000000000001 JWT token storage

## Overview

Tokens are stored hashed at rest.
EOF
  echo "def store(token): ..." > src/auth/tokens.py
  q git add -A; q git commit -qm "init: auth"
  q "$DECREE" index rebuild
  snip intent-check-isolate.ansi \
    intent-check --plan "Edit token storage" --files src/auth/tokens.py \
    --other-active-files '{"session-b": ["src/auth/tokens.py"]}'
}

# Corpus D — SPEC governs login.py + legacy_sso.py; commits touch login + helper
#            (health: dead governance + suggested governance)
gen_health() {
  q make_demo_repo
  spec spec-00000000000000000000000001-auth-login.md <<'EOF'
---
id: SPEC-00000000000000000000000001
status: implemented
date: 2026-05-10
governs:
  - src/auth/login.py
  - src/auth/legacy_sso.py
---

# SPEC-00000000000000000000000001 Auth login flow

## Overview

The login flow and its legacy SSO bridge.
EOF
  printf 'v0\n' > src/auth/login.py
  printf 'v0\n' > src/auth/legacy_sso.py
  printf 'v0\n' > src/auth/helper.py
  q git add -A; q git commit -qm "init: auth"
  printf 'v1\n' > src/auth/login.py; printf 'h1\n' > src/auth/helper.py
  q git commit -aqm "feat: harden login

Implements: SPEC-00000000000000000000000001"
  printf 'v2\n' > src/auth/login.py; printf 'h2\n' > src/auth/helper.py
  q git commit -aqm "feat: login error handling

Implements: SPEC-00000000000000000000000001"
  q "$DECREE" index rebuild
  snip health.ansi health
}

# Corpus E — SPEC governs only login.py; its commits repeat-touch undeclared helper
#            (governs-gap: --under advisory)
gen_governs_gap() {
  q make_demo_repo
  spec spec-00000000000000000000000001-auth-login.md <<'EOF'
---
id: SPEC-00000000000000000000000001
status: implemented
date: 2026-05-10
governs:
  - src/auth/login.py
---

# SPEC-00000000000000000000000001 Auth login flow

## Overview

The login flow. Declares only login.py — note it does NOT declare helper.py.
EOF
  printf 'v0\n' > src/auth/login.py
  printf 'v0\n' > src/auth/helper.py
  q git add -A; q git commit -qm "init: auth"
  printf 'v1\n' > src/auth/login.py; printf 'h1\n' > src/auth/helper.py
  q git commit -aqm "feat: harden login

Implements: SPEC-00000000000000000000000001"
  printf 'v2\n' > src/auth/login.py; printf 'h2\n' > src/auth/helper.py
  q git commit -aqm "feat: login error handling

Implements: SPEC-00000000000000000000000001"
  q "$DECREE" index rebuild
  snip governs-gap.ansi \
    intent-check --plan "edit auth helper" --files src/auth/helper.py \
    --under SPEC-00000000000000000000000001
}

# Each in a subshell so make_demo_repo's cd + cleanup trap stay isolated.
( gen_why )
( gen_conflict )
( gen_isolate )
( gen_health )
( gen_governs_gap )

echo
echo "snippets:"
for f in "$SNIP"/*.ansi; do
  echo "  $(basename "$f") ($(wc -l < "$f" | tr -d ' ') lines)"
done
echo
echo "done."
