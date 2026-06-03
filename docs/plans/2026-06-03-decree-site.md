# decree-site Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a terminal-forward dark pitch website for the `decree` CLI that demonstrates its capabilities with real (not mocked) terminal output, before/after comparisons, and a per-capability explanation spine.

**Architecture:** Astro 6 + Starlight (splash landing + sectioned content pages, search/nav/dark-mode free) + Tailwind v4 (via `@tailwindcss/vite`) + Expressive Code (built-in `ansi` language renders real captured CLI output). A `capture.sh` script runs decree's real example scenarios with pinned IDs and writes their actual ANSI output into site content — the site never fabricates output. Foundation is built serially; the 6 capability pages (one fixed 9-section spine) are the fan-out.

**Tech Stack:** Astro 6.4.x, @astrojs/starlight, @tailwindcss/vite (Tailwind v4), @astrojs/starlight-tailwind, Expressive Code (bundled), Fontsource (JetBrains Mono + Inter), Playwright (verification).

**Verification model (no unit tests on a static site):** each phase's gate is one or more of: `npm run build` exits 0, `npm run dev` serves the route, `capture.sh` writes non-empty real output, and Playwright screenshots of key pages look correct. Commit after each green gate.

**Reference:** the approved design — `docs/plans/2026-06-03-decree-site-design.md`. It owns the section orders, voice rules, and color discipline; this plan owns the build steps. Decree library + examples live at `../decree` (the sibling repo).

---

## Phase 0 — Scaffold & foundation (serial)

### Task 0.1: Scaffold Astro + Starlight into the existing repo

**Files:** creates `package.json`, `astro.config.mjs`, `src/content/docs/`, `.gitignore`, etc.

The repo already exists with git history (design docs). Scaffold into a temp dir then move, to avoid the creator refusing a non-empty dir.

```bash
cd /Users/doruk/Desktop/SIDE_HUSTLE
npm create astro@latest decree-site-scaffold -- --template starlight --no-install --no-git --yes
# move scaffold files into the real repo (which has docs/ + .git already)
rsync -a --exclude='.git' decree-site-scaffold/ decree-site/
rm -rf decree-site-scaffold
cd decree-site && npm install
```

**Gate:** `npm run build` exits 0 (stock Starlight builds). Commit: `chore: scaffold Astro + Starlight`.

### Task 0.2: Add Tailwind v4

```bash
cd /Users/doruk/Desktop/SIDE_HUSTLE/decree-site
npx astro add tailwind --yes        # installs @tailwindcss/vite, wires vite.plugins
npm install @astrojs/starlight-tailwind
```

Create `src/styles/global.css` (cascade-layer order is what prevents Starlight/Tailwind conflicts):

```css
@layer base, starlight, theme, components, utilities;

@import '@astrojs/starlight-tailwind';
@import 'tailwindcss/theme.css' layer(theme);
@import 'tailwindcss/utilities.css' layer(utilities);

@theme {
  --font-sans: 'Inter Variable', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', 'IBM Plex Mono', ui-monospace, monospace;
}

/* unlayered so it beats Starlight defaults — dark palette + brand accents */
:root {
  --decree-green: #3fb950;   /* VALUE */
  --decree-amber: #d29922;   /* HONESTY */
  --decree-red:   #f85149;   /* the one moment the old way breaks */
  --decree-cyan:  #56d4dd;   /* command prompt / links */
}
:root[data-theme='dark'] {
  --sl-color-bg: #0a0a0b;
  --sl-color-bg-nav: #0d0d10;
  --sl-color-bg-sidebar: #0d0d10;
  --sl-color-text-accent: #56d4dd;
  --sl-color-accent: #2bb6c0;
  --sl-color-accent-high: #7fe7ee;
}
```

**Gate:** `npm run build` exits 0. Commit: `chore: add Tailwind v4 + brand tokens`.

### Task 0.3: Configure `astro.config.mjs`

Set `site`, default dark, custom CSS, and Expressive Code dark frames. Concrete config:

```js
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  site: 'https://decree.dev', // placeholder; not deployed yet
  integrations: [
    starlight({
      title: 'decree',
      tagline: 'Decision governance for your codebase — and the agents editing it.',
      customCss: ['./src/styles/global.css'],
      social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/doruksahin/decree' }],
      expressiveCode: {
        themes: ['github-dark'],
        useStarlightUiThemeColors: true,
        styleOverrides: {
          borderRadius: '0.5rem',
          borderColor: '#1f2430',
          codeFontFamily: "'JetBrains Mono', ui-monospace, monospace",
          frames: {
            terminalBackground: '#0c0c10',
            terminalTitlebarBackground: '#13131a',
            terminalTitlebarForeground: '#c9d1d9',
            frameBoxShadowCssValue: '0 0 0 1px #1f2430, 0 16px 40px -16px rgba(0,0,0,0.6)',
          },
        },
      },
      sidebar: [
        { label: 'Start', link: '/start/' },
        { label: 'Capabilities', autogenerate: { directory: 'capabilities' } },
        { label: 'By example', link: '/examples/' },
      ],
    }),
  ],
  vite: { plugins: [tailwindcss()] },
});
```

**Gate:** `npm run build` exits 0; `npm run dev` serves `/`. Commit: `chore: configure Starlight + Expressive Code dark theme`.

### Task 0.4: Fonts (self-hosted)

```bash
npm install @fontsource-variable/inter @fontsource/jetbrains-mono
```

Import in `src/styles/global.css` (top): `@import '@fontsource-variable/inter';` + `@import '@fontsource/jetbrains-mono';`. Set Starlight chrome mono via `:root { --sl-font: 'Inter Variable',sans-serif; --sl-font-mono: 'JetBrains Mono',monospace; }`.

**Gate:** build green; fonts load (check network in dev). Commit: `chore: self-host Inter + JetBrains Mono`.

---

## Phase 1 — Real-output capture (no slop)

### Task 1.1: `scripts/capture.sh`

Runs decree's real example scenarios and writes their **actual ANSI output** into `src/content/captures/<id>.ansi`. Uses the sibling repo's pinned-ID scenarios so output is deterministic. Skeleton:

```bash
#!/usr/bin/env bash
# Regenerate real decree output for the site. Never hand-edit the .ansi files.
set -uo pipefail
DECREE="${DECREE:-decree}"
SITE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EX_DIR="${EX_DIR:-$SITE_DIR/../decree/examples}"
OUT="$SITE_DIR/src/content/captures"
mkdir -p "$OUT"
for s in "$EX_DIR"/0*.sh; do
  name="$(basename "$s" .sh)"
  DECREE="$DECREE" bash "$s" > "$OUT/$name.ansi" 2>&1
  echo "captured $name ($(wc -l < "$OUT/$name.ansi") lines)"
done
```

Plus targeted single-command captures for the landing hero / capability "Run it" blocks (small, focused — one command each), written to `captures/snippets/*.ansi`. These reuse the same throwaway-repo setup as the examples (extract `make_demo_repo` usage). Keep snippets tiny (one command + output).

### Task 1.2: Run + commit captures

```bash
bash scripts/capture.sh
```

**Gate:** every `.ansi` file is non-empty and contains a real `→ exit N` line. Commit: `feat: capture real decree output for the site`.

---

## Phase 2 — Shared components (serial; pages depend on these)

Create under `src/components/`. Each is a small Astro component. Build the contract first; pages consume them.

- **`TerminalWindow.astro`** — props: `title?`, slot = body. Renders window chrome (3 traffic-light dots), title bar, monospace body. For real captured output, prefer the Expressive Code `ansi` fence inside MDX; `TerminalWindow` is for hand-composed hero/teaser frames where EC framing isn't enough.
- **`BeforeAfter.astro`** — the signature device. Props: `scenario` (one line, shown above both columns), slots `before` + `after`, plus `value` and `honesty` strings. Two-column grid with a hard divider; left muted, right calm; green VALUE + amber HONESTY below, spanning full width; collapses to a toggle on mobile (`<details>`/CSS, no framework).
- **`ExitBadge.astro`** — props: `code` (0|1|2). 0→green "clean/advisory", 1→amber "finding · gate CI", 2→red "config error".
- **`Value.astro` / `Honesty.astro`** — inline callout lines (green ▸ / amber ▸) reused on every capability page.
- **`CapabilityCard.astro`** — props: `title`, `cmd`, `href`, slot = one-line outcome. Used in the landing capability triad + `/capabilities` index.
- **`LifecycleChain.astro`** — PRD → ADR → SPEC → Implementation, styled chips with arrows (CSS only).

**Gate:** create a throwaway `src/pages/_components-smoke.astro` (or a hidden docs page) importing all six with dummy props; `npm run build` exits 0; visually check in dev. Remove the smoke page. Commit: `feat: shared site components (TerminalWindow, BeforeAfter, ExitBadge, ...)`.

---

## Phase 3 — Landing page `/`

### Task 3.1: `src/content/docs/index.mdx`

`template: splash`, `hero` with thesis + sub-headline + two CTAs (design §7). Then the section order from design §5.1, composed from Phase-2 components + Starlight `CardGrid`/`Tabs`. Hero terminal shows BOTH `decree why` (a hit) AND the abstention (`no governing decisions`) — pull from `captures/snippets/`. Honor voice rules (design §7): no "we", name the enemy "guessing", banned-words list.

**Gate:** `npm run build` exits 0; `npm run dev` → `/` renders all 9 sections; Playwright screenshot of `/` looks correct (dark, framed terminals, green/amber accents). Commit: `feat: landing page`.

---

## Phase 4 — Capability pages (the fan-out)

One fixed 9-section spine (design §5.2) per page. Pages: `why`, `intent-check`, `intent-review`, `health`, `governs-gap`, `lifecycle`. Files: `src/content/docs/capabilities/<name>.md(x)`.

### Task 4.0: Author the canonical template + the `why` page first (reference implementation)

Build `capabilities/why.mdx` fully against the 9-section spine using `BeforeAfter`, `Value`, `Honesty`, real `captures/snippets/why*.ansi`, a `Tabs` block for `why` / `why --json` / `why --under`, and a collapsible flags/exit-code `<details>`. This becomes the pattern the other five copy.

**Gate:** build green; Playwright screenshot of `/capabilities/why/`. Commit: `feat: capability page — why (reference template)`.

### Task 4.1–4.5: The remaining five pages (parallelizable across subagents)

Each follows `why.mdx` exactly; only scenario/command/output/honesty-line change. Per-page honesty lines and scenarios are specified in the design doc + sourced from `../decree/examples/0*.sh` and `../decree/docs/health-signals.md`. Each: build green + screenshot + commit (`feat: capability page — <name>`).

---

## Phase 5 — `/examples` (the centerpiece)

### Task 5.1: `src/content/docs/examples.mdx`

The 6 scenarios as the arc **before → while → after → over time**. Each scenario: a short framing sentence, the **real** captured ANSI (`captures/0N-*.ansi`) in an `ansi` fence, an `ExitBadge`, and its `Value`/`Honesty` lines. Multi-step flow rendered with `Steps`. Intro explains the arc + the exit-code contract.

**Gate:** build green; `/examples/` renders 6 real colored terminals; Playwright screenshot. Commit: `feat: by-example walkthrough`.

---

## Phase 6 — `/start`

### Task 6.1: `src/content/docs/start.mdx`

Install (`uv tool install decree` / `pip install decree`, copy buttons), minimal `decree.toml`, the agent command loop, links out to `../decree/docs/`. Keep it short; it's an on-ramp, not a docs port.

**Gate:** build green; links resolve. Commit: `feat: getting-started page`.

---

## Phase 7 — Polish & repo hygiene

- `src/content/docs/capabilities/index.mdx` — capability grid (`CardGrid` of `CapabilityCard`).
- 404 page (Starlight default is fine; optionally branded).
- `README.md` — what this is, `npm run dev/build/preview`, **how to regenerate output** (`bash scripts/capture.sh`), structure.
- `.github/workflows/deploy.yml` — GitHub Pages workflow, **committed but disabled** (`on: workflow_dispatch` only / commented `push`), per design (deploy = local for now).
- Favicon / og-image: simple, optional.
- Final voice pass against design §7 banned-words list across all pages.

**Gate:** `npm run build` exits 0. Commit: `chore: polish, README, disabled deploy workflow`.

---

## Phase 8 — Verification

### Task 8.1: Full build + link sanity

`npm run build` exits 0; check `dist/` has all routes; Starlight's build reports no broken internal links.

### Task 8.2: Playwright visual verification

Use the Playwright MCP: `npm run preview`, then navigate + screenshot `/`, `/capabilities/why/`, `/examples/`. Confirm: dark terminal aesthetic, real colored ANSI output, green VALUE / amber HONESTY accents, before/after split renders, no light-mode flash, no overflow. Capture screenshots into `docs/screenshots/` for the record.

### Task 8.3: Honesty/no-slop final review

Grep all `.md(x)` for banned words (design §7). Confirm every terminal block is real captured output (cross-check against `src/content/captures/`), not hand-typed. Confirm the abstention case appears on the landing hero.

**Gate:** all three pass. Commit: `chore: verification — build, screenshots, honesty pass`.

---

## Out of scope (YAGNI — do not build)
Per design §9: no CMS/backend/auth/analytics/i18n, no full docs port, no live deploy, no competitor comparison table, no auto-embedded social. `llms.txt` and a Mermaid lifecycle diagram are deferred (build only if trivial).
