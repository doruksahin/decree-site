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

It runs the six `examples/` scenarios into `src/captures/0N-*.ansi` (used by
`/examples/`) and focused single commands into `src/captures/snippets/*.ansi` (used by
the landing and capability pages). Captures use pinned IDs so the structural output is
stable across runs. Override the binary or examples location:

```bash
DECREE=../decree/.venv/bin/decree EX_DIR=../decree/examples bash scripts/capture.sh
```

## Structure

```
src/
  captures/            real captured decree output (.ansi) — generated, do not edit
  components/          Ansi, BeforeAfter, Callout, ExitBadge, CapabilityCard, LifecycleChain
  content/docs/
    index.mdx          landing / pitch
    start.mdx          install + the agent loop
    examples.mdx       the six scenarios, in the before -> while -> after -> over-time arc
    capabilities/      one page per capability (the 9-section spine)
  styles/              global.css (tokens, dark default) + components.css
scripts/capture.sh     regenerates src/captures from real decree runs
docs/plans/            the design + implementation plan this site was built from
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
