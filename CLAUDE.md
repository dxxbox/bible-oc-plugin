# CLAUDE.md

## Project

`bible-oc-plugin` is an OpenClaw plugin that integrates BiBLE Atlas as a remote HTTP context engine. It replaces OpenClaw's default memory system with BiBLE Atlas for memory recall, skill/knowledge search, session capture, and lifecycle hooks.

## Pre-Action Checklist

Before any edit/write, ask:

1. Was this explicitly asked for? (If not, stop.)
2. Am I assuming or do I know? (If assuming, ask.)
3. Is this the simplest approach? (If over 3 steps, reconsider.)
4. Will this change pass verification? (If not sure, flag it.)
5. Never, ever change standard to get `Pass`

## Build & Test

```bash
npm ci                  # install devDependencies (zero prod deps)
npm run build           # tsc -p tsconfig.json
npm run typecheck       # tsc --noEmit
npm test                # vitest run
npm run test:coverage   # vitest run --coverage
npm run lint            # eslint src tests
npm run format          # prettier --write
```

## Architecture

```
src/
  index.ts              # Plugin entry — registers contextEngine, hooks, tools, CLI
  config/               # Config parsing, validation, defaults
  http/                 # BibleAtlasClient — HTTP calls to BiBLE Atlas service
  runtime/              # BibleRuntime facade over HTTP client
  context/              # ContextEngine: assemble, afterTurn, compact
    engine.ts           # Main engine factory
    recall.ts           # Auto-recall pipeline (query → search → rank → inject)
    ranking.ts          # Dedupe, threshold filter, re-rank
    injection.ts        # <relevant-memories> rendering, token budget
    capture.ts          # Session capture buffer, async commit
  hooks/                # session_start/end, before_reset lifecycle hooks
  tools/                # Tool registration: memory, knowledge, skill
  cli/                  # openclaw bible setup/status
  types/                # Duck types for OpenClawPluginApi (no SDK imports)
tests/
  unit/                 # Config, capture, contracts, hooks, recall, tools
  integration/          # CLI, HTTP client (mock server)
  smoke/                # Full plugin registration
```

## Key Rules

- **No OpenClaw SDK imports** — use local duck types in `src/types/openclaw.ts` only
- **Module resolution**: `NodeNext` — all relative imports must use `.js` extension
- **Log prefix**: `[bible-oc-plugin]` on all log output
- **Config path**: `plugins.entries.bible-oc-plugin` in OpenClaw config
- **Zero prod dependencies** — runtime only needs Node.js + HTTP to BiBLE Atlas service
