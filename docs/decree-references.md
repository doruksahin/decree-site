# Cross-repo references — a drift catcher for decree → decree-site

This site makes claims about [`decree`](https://github.com/doruksahin/decree), paraphrases
its docs, and runs its example scripts to produce the terminal output it ships. Those are
**dependencies on specific files in the decree repo**. If one is renamed, moved, or
removed, a page here can silently go stale.

This file makes those dependencies **explicit and strict**. Every decree file the site
relies on is linked below as a relative reference into the sibling `decree` checkout.
[`lychee`](https://lychee.cli.rs) (config: [`.lychee.toml`](../.lychee.toml)) checks every
link; with `include_fragments = true` it also checks `#anchors`. If decree drifts, the
link breaks and `npm run check:refs` fails — surfacing the drift before the site ships a
stale claim. It is the same idea decree applies to code: declare what you depend on, then
verify the declaration still holds.

> **Requires** the `decree` repo checked out as a sibling at `../decree`, exactly like
> [`scripts/capture.sh`](../scripts/capture.sh). Run `npm run check:refs` (offline,
> deterministic) to validate just these references, or `npm run check:links` for full
> markdown link health.

## Example scenarios

`scripts/capture.sh` runs these to generate `src/captures/*.ansi`, the real terminal
output rendered on [/examples](../src/content/docs/examples.mdx) and the capability pages.
A rename here breaks both the capture script and this check.

- [examples/_lib.sh](../../decree/examples/_lib.sh) — shared `make_demo_repo` + `dc` helpers the capture corpora reuse
- [examples/01-why.sh](../../decree/examples/01-why.sh) — scenario 1 (`why`), and the `why-*` snippets
- [examples/02-intent-check-conflict.sh](../../decree/examples/02-intent-check-conflict.sh) — scenario 2 (`intent-check` conflict)
- [examples/03-parallel-sessions.sh](../../decree/examples/03-parallel-sessions.sh) — scenario 3 (live-session overlap)
- [examples/04-intent-review.sh](../../decree/examples/04-intent-review.sh) — scenario 4 (`intent-review` diff gate)
- [examples/05-health-dead-governance.sh](../../decree/examples/05-health-dead-governance.sh) — scenario 5 (`health`)
- [examples/06-governs-gap.sh](../../decree/examples/06-governs-gap.sh) — scenario 6 (`--under` governs-gap)
- [examples/run-all.sh](../../decree/examples/run-all.sh) — the full arc, referenced from /examples
- [examples/README.md](../../decree/examples/README.md) — the source pitch this site's arc and honesty framing build on
- [docs/usage.md#decree-generate-html](../../decree/docs/usage.md#decree-generate-html) — the human-orchestrator board flow on [/agents](../src/content/docs/agents.mdx) and [/capabilities/sprints](../src/content/docs/capabilities/sprints.mdx) derives from the read-only HTML board behavior
- [docs/usage.md#decree-sprint](../../decree/docs/usage.md#decree-sprint) — [/capabilities/sprints](../src/content/docs/capabilities/sprints.mdx) paraphrases the v3 sprint directory store and complete/drop flow
- [docs/usage.md#decree-migrate-sprint-ledger](../../decree/docs/usage.md#decree-migrate-sprint-ledger) — the sprint migration example and v1 ledger warning derive from this section
- [decree/prd/reporting/html-board/prd-01kw22jy2rqjd7b759et0bm2np-html-board-export-and-required-buckets.md](../../decree/decree/prd/reporting/html-board/prd-01kw22jy2rqjd7b759et0bm2np-html-board-export-and-required-buckets.md) — the read-only sprint-oriented board positioning the site summarizes
- [decree/spec/reporting/html-board/spec-01kw22ke3k4j7m2rjyac110mph-required-buckets-and-generate-html-poc.md](../../decree/decree/spec/reporting/html-board/spec-01kw22ke3k4j7m2rjyac110mph-required-buckets-and-generate-html-poc.md) — the board payload, kanban columns, filters, and read-only markdown overlay behavior the site references
- [decree/spec/sprints/spec-01kwkxherb56w94scrzevmbqmj-sprint-ledger-v2-storage-and-item-level-completion.md](../../decree/decree/spec/sprints/spec-01kwkxherb56w94scrzevmbqmj-sprint-ledger-v2-storage-and-item-level-completion.md) — the v3 sprint store behavior and invariants this site summarizes

## Concept & capability docs the site paraphrases or links

- [README.md](../../decree/README.md) — linked as "the decree repository" from the landing, [/start](../src/content/docs/start.mdx), and capability pages
- [docs/health-signals.md](../../decree/docs/health-signals.md) — [/capabilities/health](../src/content/docs/capabilities/health.mdx) links here and paraphrases the four signals (stale, ungoverned hotspots, dead, suggested)
- [docs/provenance-model.md](../../decree/docs/provenance-model.md) — the "convention-bounded / deterministic-not-certain" honesty claims on the landing and health pages derive from this
- [docs/configuration.md](../../decree/docs/configuration.md) — [/start](../src/content/docs/start.mdx) points here for the full `decree.toml` schema
- [docs/llm-agent-integration.md](../../decree/docs/llm-agent-integration.md) — the landing "built for agents" section and the [/start](../src/content/docs/start.mdx) agent loop
- [AGENTS.md](../../decree/AGENTS.md) — the agent contract the "built for agents" framing assumes
