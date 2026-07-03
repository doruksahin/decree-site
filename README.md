# decree-site

The pitch + capability website for [`decree`](https://github.com/doruksahin/decree) —
a CLI for the software-decision lifecycle. Terminal-forward, dark, and built on
[Astro Starlight](https://starlight.astro.build/).

Its defining discipline: **every terminal block on the site is real `decree` output**,
captured from an actual run by `scripts/capture.sh`. Nothing is mocked.

## Develop

```bash
npm install
npm run dev        # local dev server (http://localhost:4321)
npm run build      # static build into dist/
npm run preview    # serve the built site
```

Requires Node 22+ (Astro 6).

## Regenerate the terminal output

The `.ansi` files under `src/captures/` are generated, never hand-edited. To refresh
them from the real CLI (e.g. after a decree output change):

```bash
# needs `decree` on PATH (or DECREE=/path/to/decree) and the decree repo as a sibling
bash scripts/capture.sh
```

It runs the six canonical governance scenarios into `src/captures/0N-*.ansi` (used by
`/examples/`) and focused single commands into `src/captures/snippets/*.ansi` (used by
the landing, sprint workflow, and capability pages). Captures use pinned IDs so the
structural output is stable across runs. Override the binary or examples location:

```bash
DECREE=../decree/.venv/bin/decree EX_DIR=../decree/examples bash scripts/capture.sh
```

## Cross-repo drift catcher

The site makes claims about decree, paraphrases its docs, and runs its example scripts.
Those are dependencies on specific files in the sibling `decree` repo. To stop the site
from silently going stale when decree changes, `docs/decree-references.md` declares every
such dependency as a strict relative link into `../decree`, and [lychee](https://lychee.cli.rs)
checks them:

```bash
npm run check:refs    # offline, deterministic — just the cross-repo references
npm run check:links   # full markdown link health (online), mirrors decree
```

If a referenced decree file is renamed, moved, or removed, the link breaks and the check
fails — surfacing the drift before a stale claim ships. The same checks run in CI
(`.github/workflows/links.yml`), which checks out decree as a sibling so the references
resolve. Requires the `decree` repo at `../decree`, the same assumption as `capture.sh`.

## Structure

```
src/
  captures/            real captured decree output (.ansi) — generated, do not edit
  components/          Ansi, BeforeAfter, Callout, ExitBadge, CapabilityCard, LifecycleChain
  content/docs/
    index.mdx          landing / pitch
    start.mdx          install + the agent loop + human board handoff
    examples.mdx       six governance scenarios plus the v3 sprint execution/orchestrator workflow
    capabilities/      one page per capability (the 9-section spine)
  styles/              global.css (tokens, dark default) + components.css
scripts/capture.sh     regenerates src/captures from real decree runs
docs/
  decree-references.md the strict cross-repo reference manifest (drift catcher)
  plans/               the design + implementation plan this site was built from
.lychee.toml           link-checker config (mirrors decree)
```

How the real ANSI renders: `Ansi.astro` loads a `.ansi` file and hands it to Expressive
Code's built-in `ansi` language inside a terminal frame. Terminal frames are always
dark; the site defaults to dark via a small theme seed in `astro.config.mjs`.

## Deploy

Not wired by default (the site builds locally for now). A GitHub Pages workflow is
included but **disabled** — see `.github/workflows/deploy.yml`. It runs only on manual
dispatch until you enable the `push` trigger and set the repository's Pages source to
"GitHub Actions". `npm run build` produces a fully static `dist/` deployable anywhere.

## License

MIT, matching decree.
