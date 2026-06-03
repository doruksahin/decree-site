# decree-site — Design

**Date:** 2026-06-03
**Status:** Approved (brainstorming → ready for implementation plan)
**Goal:** A pitch website for [`decree`](../../../decree) — a CLI for the software-decision
lifecycle (PRD → ADR → SPEC) whose differentiator is **honesty**: it answers only
from declared facts and abstains rather than guessing.

This document is the validated design. The implementation plan lives alongside it
(see `writing-plans` output). It folds in findings from four research sweeps of
best-in-class developer-tool sites (sources cited inline) so the build reuses
proven demonstration/pitch patterns instead of inventing them.

---

## 1. Decisions locked with the user

| Decision | Choice |
|----------|--------|
| Location | **New standalone repo** `decree-site` (sibling to `decree`) |
| Visual direction | **Terminal-forward dark** — monospace display, terminal windows, green `VALUE` / amber `HONESTY` accents that mirror the CLI's own output |
| Scope | **Pitch site** — landing + ~6 capability pages + a "by example" walkthrough. **Not** a full port of `decree/docs/` (link out for deep reference) |
| Deploy | **Local build/preview only** for now; a deploy workflow left in place but commented/disabled |

## 2. Stack (verified current, June 2026)

- **Astro 6.4.x** (Node 22+; we have Node 26) + **Starlight** — `splash` landing
  template + sectioned content pages, search, dark mode, nav for free.
- **Tailwind CSS v4** via the **`@tailwindcss/vite`** plugin (the legacy
  `@astrojs/tailwind` integration is v3-only/deprecated). `@astrojs/starlight-tailwind`
  for coexistence; cascade-layer order `@layer base, starlight, theme, components, utilities;`.
- **Expressive Code** (bundled with Starlight) for all code/terminal blocks:
  - ` ```bash ` blocks → terminal frame + copy button automatically.
  - **`ansi` language is built in** → paste **real** ANSI-colored CLI output and it
    renders in color. This is how the site shows decree's actual output, never a mockup.
  - `styleOverrides.frames.*` to match our dark palette.
- Fonts (Tailwind v4 `@theme`): **JetBrains Mono** (display + terminal) + **Inter** (body), self-hosted via Fontsource.
- **No** heavy JS/animation framework. Astro islands only; subtle CSS, no GIF theater.

## 3. Visual system

Near-black surface (`#0a0a0b`–`#13131a`), one cool accent (cyan, links/active),
plus the two semantic accents that ARE the brand: **green `VALUE`** (~`#3fb950`)
and **amber `HONESTY`** (~`#d29922`); cyan command prompts; dim `→ exit N` lines.
Hairline 1px borders + soft long shadows so framed terminals "float" and become the
brightest objects on the page (Cloudflare Docs / Biome cue). One saturated accent
carries CTAs + highlights; everything else monochrome dark (Biome). Mono used
liberally, not only in code (Astro Terminal theme cue).

**Terminal demo = static framed window, never a GIF.** decree's output is static
lines + an exit code; animation only obscures legibility (Deno/Bun/Astral all use
static framed code blocks; GIFs are reserved for inherently interactive tools like
fzf). Window chrome with traffic-light dots; dimmed `$` prompt; command and output
as one block; copy buttons on **install lines only**, never on sample output.

## 4. Content discipline — no slop, real output only

Mirrors `decree/examples/` ethos. A build-time script `scripts/capture.sh` runs the
real example scenarios with **pinned IDs** and writes their **actual** output into
site content (`src/content/` data). The site never fabricates a result; regenerate →
output refreshes; it doubles as a smoke test for decree's output shapes. Seed output
already captured. Real paths (`src/auth/tokens.py`) and real verdict glyphs — reads
as the tool, not marketing (ripgrep/Deno cue).

## 5. Information architecture

### 5.1 Landing `/` (section order — Turborepo skeleton + a problem beat + an agent section)

1. **Hero** — thesis + sub-headline + two CTAs + a real static terminal showing
   `decree why src/auth/tokens.py` returning the governing SPEC **and** a second
   invocation returning *"no governing decisions"* (the abstention shown proudly —
   it's the proof of honesty, not an edge case).
2. **The problem (one short beat, 2–3 sentences)** — the category has no household
   name, so we name it once: *code outlives the reasons for it; humans forget, agents
   never knew; by the time a change ships nobody can say which decision it honors.*
3. **What it does** — 3 capability stories (chess layout), each a one-line outcome +
   a tiny real terminal: *"Which decision explains this code?"* (`why`) ·
   *"Is my change still aligned?"* (`intent-check`/`intent-review`, exit codes gate CI) ·
   *"It abstains instead of guessing."*
4. **The exit-code contract** — two static panels side by side: a clean run ending
   `→ exit 0` (green) vs a finding ending `→ exit 1` (amber). Makes "1 = gate CI,
   0 = clean/advisory" legible at a glance.
5. **Built for agents, not just people** — its own section (a differentiator, not a
   footnote): agents call decree before/after edits; deterministic output; non-zero
   exit on drift.
6. **Deterministic, not "AI"** — short trust beat: no model, no temperature, same
   input → same answer. Counter-positions against AI-slop.
7. **The honesty pitch** — why each answer is trustworthy *because* decree refuses to
   overclaim (declared `governs:` only; structural not semantic; convention-bounded
   git signals; dead governance is a finding, suggested is advisory).
8. **Proof / by-example teaser** → link to `/examples`. Curated, exact numbers only.
9. **Final full-width CTA** — restate value in one line + install command.

### 5.2 Capability pages `/capabilities/*` — one repeatable 9-section spine (Diátaxis-justified)

A pitch page is dominantly **Explanation** with an embedded **How-to** fragment and a
**Reference** tail (Diátaxis warns to keep the modes in separate sections). Spine:

1. One-line capability claim (Explanation headline).
2. **Before/After split** — the signature device (see §6).
3. **VALUE** line (green) — the BAB "bridge", one concrete sentence.
4. **HONESTY** line (amber) — the boundary of the claim; the hardest, most valuable
   sentence on each page; quieter than VALUE.
5. The concept in 2–3 sentences (pure Explanation — what decree does under the hood).
6. **Run it** — the canonical command + **real annotated** output (copy-paste),
   `Tabs` for variants of the *same* command (e.g. `why` / `why --json` / `why --under`).
7. When you'd reach for this — 2–3 concrete trigger moments.
8. Flags & output reference — flat table in a collapsible `<details>` (pure Reference,
   kept visually separate so it never muddies the explanation).
9. Next capability cross-link.

Pages: `why`, `intent-check`, `intent-review`, `health`, `governs-gap`,
`lifecycle` (lint/status/progress/index/graph as the validation core). Only the
scenario, command, output, and honesty line change between them.

### 5.3 `/examples` — "decree by example"

The 6 `examples/` scenarios as the narrative arc **before → while → after → over
time**, each rendered with the **real** captured ANSI output + `VALUE`/`HONESTY`
lines + exit-code badges. The centerpiece; maps 1:1 to `decree/examples/`. Multi-step
flows (`intent-check` → code → `intent-review`) rendered with numbered `Steps`.

### 5.4 `/start` — getting started

Install, `decree.toml`, the agent command loop; links out to `decree/docs/` for deep
reference. Copy buttons on the install/usage commands.

## 6. The signature Before/After device

Two-column split, **hard vertical divider, SAME concrete scenario on both sides**
(holding the scenario constant is what makes the contrast honest, not a strawman).
Left "Without decree" = muted/desaturated, slightly busier (grep/blame/Slack
archaeology flailing); right "With decree" = calm, one clean command + real output.
**Color discipline, three roles only:** muted gray for Before (not aggressive red —
red-everywhere reads cheesy; reserve a single red accent for the one moment the old
way breaks); green VALUE line below; amber HONESTY beneath it, quieter. Labels are
literally "Without decree" / "With decree" (decree is additive, not a replacement —
so not "old/new", not "them/us"). On mobile the split becomes a toggle of one shared
scenario. Implemented as a reusable `<BeforeAfter>` Astro component.

## 7. Voice & microcopy rules (anti-cliché)

1. Verb- or "you"-first, **never "we"** ("you'll know which decision governs any line").
2. Name the enemy in plain words: **guessing**. The line *"says 'no governing decisions'
   instead of guessing"* appears in the hero and the closing CTA.
3. Show terminal output — including the **empty/abstention result** — as a hero, proudly.
4. Exact, technical, lowercase-honest: "deterministic", "exit code 1 on drift",
   "answers from declared `governs:`". Concrete verbs: tracks, checks, maps, abstains, gates.
5. One idea per sentence; let periods do the work.
6. **Banned** (AI-slop tells): supercharge, unlock, effortlessly, seamless, 10x,
   "for the modern developer", "powered by AI", em-dash triplets.

Working hero copy (refine at build):
- Thesis: **"Decision governance for your codebase — and the agents editing it."**
- Sub: **"decree tracks the decisions behind your code (PRD → ADR → SPEC) and checks
  every change against them. It answers only from what's declared — and says
  'no governing decisions' instead of guessing."**
- CTAs: primary **"Install decree"** / secondary ghost button **`$ uv tool install decree`**.

## 8. Reusable components

`TerminalWindow` (chrome + dots + ANSI body), `BeforeAfter`, `CapabilityCard`,
`ExitBadge` (exit 0 green / 1 amber / 2 config), `Value` / `Honesty` callouts,
`LifecycleChain` (PRD→ADR→SPEC). Prefer Starlight built-ins where they fit:
`Card`/`CardGrid`, `Tabs`/`TabItem`, `Steps`, `Aside`, `Badge`, `LinkButton`, `Code`.

## 9. YAGNI — explicitly out of scope

No CMS/backend/auth/analytics/i18n. No full `decree/docs/` port (link out). No deploy
wiring now (build + preview only; a GitHub Pages workflow committed but disabled). No
JS framework beyond Astro islands. No comparison table against named competitors (the
category has none — a table would read defensive). No auto-embedded social tweets.

### Optional, low-cost, deferred (note, don't build unless trivial)
- `llms.txt` / a machine-first variant for agent clients (Resend/Sentry now serve bots
  a stripped "here's the CLI/MCP/API" page; on-brand since decree targets agents).
- Mermaid lifecycle diagram (decree already emits Mermaid) if a plugin drops in cleanly.

## 10. Deliverable & verification

New git repo at `/Users/doruk/Desktop/SIDE_HUSTLE/decree-site`. `npm install` +
`npm run dev/build/preview` all green. README on structure + how to regenerate captured
output. **Verified with a real `npm run build`** and **Playwright screenshots** of the
landing + one capability page + the examples page before it's called done.

## 11. Build approach (orchestration)

Fresh repo → no file conflicts. Foundation is coherence-critical and built serially
(scaffold → design tokens/CSS → shared components → capture script → content data).
The 6 capability pages share one fixed 9-section template, so they are the natural
fan-out: authored in parallel by subagents **after** the template + components exist,
then integrated, built, and visually verified.

---

### Research sources folded into this design
- CLI demonstration: Bun, Astral uv/Ruff, Charm/VHS, Starship, Deno, Warp, ripgrep, fzf.
- Pitch/structure: Evil Martians "100 devtool landing pages" study, Stripe landing-copy
  guide, Linear, Resend, Turborepo, Prisma, Vercel, Sentry.
- Before/after + capability page: Prisma "Why Prisma", Diátaxis, Astro/Stripe docs
  code-sample conventions, PAS/BAB copy frameworks.
- Technical + visual: Starlight + Tailwind v4 + Expressive Code docs; showcase sites
  opencode, Bombshell, Biome, Astro Terminal, Cloudflare Docs.
