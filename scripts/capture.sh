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
  # Same collision, framed around the active decision: --under SPEC-…001 marks
  # tokens.py as owned and SPEC-…002 as a contextual overlap, not a blocker.
  snip intent-check-under.ansi \
    intent-check --plan "Change token refresh storage" --files src/auth/tokens.py \
    --under SPEC-00000000000000000000000001
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

# Corpus F — a small but valid PRD -> ADR -> SPEC corpus with cross-refs and
#            checkboxes  (lifecycle: lint, progress, status)
gen_lifecycle() {
  q make_demo_repo
  cat > decree.toml <<'TOML'
[types.prd]
dir = "decree/prd"
prefix = "PRD"
digits = 3
initial_status = "draft"
statuses = ["draft", "approved", "implemented", "archived"]
required_sections = ["Overview"]
[types.prd.transitions]
draft = ["approved"]
approved = ["implemented", "archived"]
implemented = ["archived"]
archived = []
[types.prd.actions]
approve = "approved"
implement = "implemented"

[types.adr]
dir = "decree/adr"
prefix = "ADR"
digits = 3
initial_status = "proposed"
statuses = ["proposed", "accepted", "superseded"]
required_sections = ["Overview"]
[types.adr.transitions]
proposed = ["accepted"]
accepted = ["superseded"]
superseded = []
[types.adr.actions]
accept = "accepted"

[types.spec]
dir = "decree/spec"
prefix = "SPEC"
digits = 3
initial_status = "draft"
statuses = ["draft", "approved", "implemented"]
required_sections = ["Overview"]
[types.spec.transitions]
draft = ["approved"]
approved = ["implemented"]
implemented = []
[types.spec.actions]
approve = "approved"
implement = "implemented"
TOML
  mkdir -p decree/prd decree/adr decree/spec src/auth
  cat > decree/prd/prd-00000000000000000000000001-user-auth.md <<'EOF'
---
id: PRD-00000000000000000000000001
status: draft
date: 2026-05-10
---

# PRD-00000000000000000000000001 User Authentication

## Overview

Users sign in with email and password; sessions expire.

## Requirements

- [x] Email + password sign-in
- [x] Session expiry
- [ ] Passwordless option
EOF
  cat > decree/adr/adr-00000000000000000000000001-jwt.md <<'EOF'
---
id: ADR-00000000000000000000000001
status: accepted
date: 2026-05-10
references:
  - PRD-00000000000000000000000001
---

# ADR-00000000000000000000000001 Auth via JWT

## Overview

Use signed JWTs for session tokens.
EOF
  cat > decree/spec/spec-00000000000000000000000001-token-storage.md <<'EOF'
---
id: SPEC-00000000000000000000000001
status: draft
date: 2026-05-10
references:
  - PRD-00000000000000000000000001
  - ADR-00000000000000000000000001
governs:
  - src/auth/tokens.py
---

# SPEC-00000000000000000000000001 Token Storage API

## Overview

Tokens are stored hashed at rest.

## Acceptance Criteria

- [x] Hash tokens before persistence
- [ ] Rotate signing keys
- [ ] Revoke on logout
EOF
  echo "def store(token): ..." > src/auth/tokens.py
  q git add -A; q git commit -qm "init: corpus"
  q "$DECREE" index rebuild
  snip lint.ansi lint
  snip progress.ansi progress
  # NB: `status` regenerates indexes and prints absolute (temp) paths — that's
  # non-deterministic, so it's described in prose on the site rather than captured.
}

# Corpus G — sprint execution tracking with the v2 directory store:
#            status -> complete one item -> status again.
gen_sprint_v2() {
  q make_demo_repo
  mkdir -p decree/spec decree/sprints/live decree/sprints/closed src/auth
  spec spec-00000000000000000000000001-token-storage.md <<'EOF'
---
id: SPEC-00000000000000000000000001
status: approved
date: 2026-07-03
governs:
  - src/auth/tokens.py
---

# SPEC-00000000000000000000000001 Token Storage API

## Overview

Tokens are stored hashed at rest.

## Acceptance Criteria

- [x] Hash tokens before persistence
- [x] Revoke on logout
EOF
  echo "def store(token): ..." > src/auth/tokens.py
  cat > decree/sprints/state.yaml <<'EOF'
schema: decree.sprints.v2
mode: enabled
state: active
active:
  id: SPRINT-00000000000000000000000001
  name: Sprint 1
  started: '2026-07-03'
EOF
  cat > decree/sprints/live/SPEC-00000000000000000000000001.yaml <<'EOF'
document: SPEC-00000000000000000000000001
scope: active
kind: execution
source: manual
added: '2026-07-03'
EOF
  q git add -A; q git commit -qm "init: v2 sprint corpus"
  q "$DECREE" index rebuild
  snip sprint-status-open.ansi sprint status
  snip sprint-complete.ansi sprint complete SPEC-00000000000000000000000001 --commit abc1234
  snip sprint-status-done.ansi sprint status
}

# Corpus H — a v1 sprint ledger that needs the one-shot v2 migration.
gen_sprint_migration() {
  q make_demo_repo
  mkdir -p decree/spec decree/sprints src/auth
  spec spec-00000000000000000000000001-token-storage.md <<'EOF'
---
id: SPEC-00000000000000000000000001
status: approved
date: 2026-07-03
governs:
  - src/auth/tokens.py
---

# SPEC-00000000000000000000000001 Token Storage API

## Overview

Tokens are stored hashed at rest.

## Acceptance Criteria

- [x] Hash tokens before persistence
- [x] Revoke on logout
EOF
  echo "def store(token): ..." > src/auth/tokens.py
  cat > decree/sprints/ledger.yaml <<'EOF'
schema: decree.sprints.v1
mode: enabled
state: active
active: SPRINT-00000000000000000000000001
sprints:
- id: SPRINT-00000000000000000000000001
  name: Sprint 1
  status: active
  started: '2026-07-03'
  items:
  - document: SPEC-00000000000000000000000001
    kind: execution
    source: manual
    added: '2026-07-03'
backlog: []
draft_pool: []
EOF
  q git add -A; q git commit -qm "init: v1 sprint corpus"
  snip sprint-migrate-dry-run.ansi migrate sprint-ledger --dry-run
}

# Corpus I — the REAL decree repo (dogfood): decree governs its own code.
# Runs against the sibling ../decree working tree, not a throwaway corpus.
# Output is a live proof, so it tracks the real repo as it evolves. Clean
# (no temp paths) for `why` and `progress`. Skipped if the repo isn't present.
gen_dogfood() {
  local repo
  repo="$(cd "$EX_DIR/.." 2>/dev/null && pwd)" || return 0
  [ -f "$repo/decree.toml" ] || { echo "  (dogfood skipped — no decree repo at $repo)"; return 0; }
  (
    cd "$repo" || exit 0
    q "$DECREE" index rebuild   # refresh the derived cache (.decree/, gitignored)
    dc why src/decree/parser.py > "$SNIP/dogfood-why.ansi" 2>&1
    dc progress --corpus        > "$SNIP/dogfood-progress.ansi" 2>&1
    dc refs SPEC-01KT22NMS0D19VMD8VPK4D2MNX > "$SNIP/dogfood-refs.ansi" 2>&1
  )
}

# Corpus J — an in-flight SPEC governs tokens.py; a change is committed with and
#            without the Implements: trailer  (commit-check, CI mode --diff-base)
gen_commit_check() {
  q make_demo_repo
  spec spec-00000000000000000000000001-jwt-token-storage.md <<'EOF'
---
id: SPEC-00000000000000000000000001
status: approved
date: 2026-05-10
governs:
  - src/auth/tokens.py
---

# SPEC-00000000000000000000000001 JWT token storage

## Overview

Refresh tokens are rotated and stored hashed.
EOF
  echo "def store(token): ..." > src/auth/tokens.py
  q git add -A; q git commit -qm "init: auth"
  q "$DECREE" index rebuild
  # the change is committed WITHOUT a trailer -> the gate fails
  echo "def store(token): rotate(token)" > src/auth/tokens.py
  q git commit -aqm "feat: rotate refresh tokens"
  q "$DECREE" index rebuild
  snip commit-check-fail.ansi commit-check --diff-base HEAD~1 --strict
  # redo the change WITH the trailer -> the gate passes
  q git reset --hard HEAD~1
  echo "def store(token): rotate(token)" > src/auth/tokens.py
  q git commit -aqm "feat: rotate refresh tokens" \
    --trailer "Implements: SPEC-00000000000000000000000001"
  q "$DECREE" index rebuild
  snip commit-check-pass.ansi commit-check --diff-base HEAD~1 --strict
}

# Corpus K — one SPEC governs tokens.py; the plan edits the SPEC's own markdown
#            (a decree-document self-edit) and a new ungoverned helper. Neither
#            is a blocker: the self-edit is corpus maintenance, the new file an
#            advisory add_governance. Shows the typed "Block now / Clean later"
#            output and the source/corpus classification. Exit 0.
gen_typed() {
  q make_demo_repo
  spec spec-00000000000000000000000001-token-storage.md <<'EOF'
---
id: SPEC-00000000000000000000000001
status: implemented
date: 2026-05-10
governs:
  - src/auth/tokens.py
---

# SPEC-00000000000000000000000001 Token storage

## Overview

Tokens are stored hashed at rest.
EOF
  echo "def store(token): ..." > src/auth/tokens.py
  q git add -A; q git commit -qm "init: auth"
  q "$DECREE" index rebuild
  snip intent-check-typed.ansi \
    intent-check --plan "Refine the SPEC and add a helper" \
    --files decree/spec/spec-00000000000000000000000001-token-storage.md src/auth/helper.py
}

# Corpus L — a SPEC at 100% primary ACs but still draft, with a trailer-linked
#            commit (lifecycle drift), governing a broad module surface (broad
#            governance). Both signals are advisory — health still exits 0.
gen_quality() {
  q make_demo_repo
  mkdir -p decree/spec src
  {
    echo "---"
    echo "id: SPEC-00000000000000000000000001"
    echo "status: draft"
    echo "date: 2026-05-10"
    echo "governs:"
    for i in $(seq 1 26); do
      printf 'v0\n' > "src/mod$i.py"
      echo "  - src/mod$i.py"
    done
    echo "---"
    echo ""
    echo "# SPEC-00000000000000000000000001 Broad module surface"
    echo ""
    echo "## Overview"
    echo ""
    echo "One SPEC that grew to own many modules."
    echo ""
    echo "## Acceptance Criteria"
    echo ""
    echo "- [x] Ships"
    echo "- [x] Tested"
  } > decree/spec/spec-00000000000000000000000001-broad.md
  q git add -A
  q git commit -qm "init: broad module surface

Implements: SPEC-00000000000000000000000001"
  q "$DECREE" index rebuild
  snip health-quality.ansi health
}

# Each in a subshell so make_demo_repo's cd + cleanup trap stay isolated.
( gen_why )
( gen_conflict )
( gen_isolate )
( gen_typed )
( gen_health )
( gen_quality )
( gen_governs_gap )
( gen_commit_check )
( gen_lifecycle )
( gen_sprint_v2 )
( gen_sprint_migration )
gen_dogfood

echo
echo "snippets:"
for f in "$SNIP"/*.ansi; do
  echo "  $(basename "$f") ($(wc -l < "$f" | tr -d ' ') lines)"
done
echo
echo "done."
