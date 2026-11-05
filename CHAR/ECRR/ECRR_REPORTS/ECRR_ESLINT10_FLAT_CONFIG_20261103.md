# ECRR — ESLint 10: flat config, the TypeScript 6 API for the linters, and a CI step that fails when ESLint cannot run

**Date:** 2026-11-03
**Actor:** Claude Code (local seat), started from the session that repaired the TypeScript 7 toolchain (`ECRR_TS7_JEST_TOOLCHAIN_20261102.md` §1c left ESLint open)
**Scope:** PR #906, code lane (`eslint.config.js`, `ALFA/APPS/eslint.config.js`, both `.eslintrc.js` removed, `package.json`, `pnpm-lock.yaml`, `BRAV/SCPT/guardrails.json`, `.vscode/settings.json`). PR #907, CI lane (`.github/workflows/bosscat-gate-verify.yml`, `docs/status/workflows.json`).
**Verdict:** **AMBER**. ESLint runs again on a fresh install: 237 files, 3,387 errors, 1,906 warnings and 0 parse errors, with the original rules reproduced message for message. The `unit` job gains a step that fails when ESLint cannot run, and its first run was red on `main` as intended. This report closes GREEN once both PRs are merged and the step's first green run is recorded as an addendum.
**Trigger:** Dependabot #699 (2026-09-01) moved ESLint to 10.13.0 and TypeScript to 7.0.2; nothing has run ESLint since.

## 1. Examine

All on a fresh `pnpm install --frozen-lockfile` (pnpm 10.18.1, Node 22.23.2):

- `pnpm exec eslint .` and `eslint <file>` exit 2: "ESLint couldn't find an eslint.config.* file". ESLint 10 dropped eslintrc entirely; it ignores `ESLINT_USE_FLAT_CONFIG`, and `loadESLint({ useFlatConfig: false })` returns the flat class. The repo had `.eslintrc.js` and `ALFA/APPS/.eslintrc.js`. The editor path, `loadESLint()` then `lintText`, throws "Could not find config file."
- typescript@7.0.2 exports only `lib/version.cjs` (`version`, `versionMajorMinor`), so typescript-eslint 8.72.1 has no compiler to parse with. 8.72.1 is the latest release; its peer range is `typescript >=4.8.4 <6.1.0`. A parser that throws this way does not crash ESLint: each TypeScript file gets a fatal "Parsing error" and the exit code is 1. typescript-eslint/typescript-eslint#12518 was closed as not planned on 2026-07-08 (no TypeScript 7 support until TypeScript ships an API); the maintainers point to the side-by-side setup in the TypeScript 7.0 release post.
- Next.js 16.4.3 needs the same API. Its TypeScript check looks for `typescript/lib/typescript.js`, which 7.0.2 does not have, so `next build` and `next dev` reach the branch that throws "TypeScript 7.0.2 does not provide the compiler API required by Next.js" (`experimental.useTypeScriptCli` is not set). This was established by calling Next's `getTypeScriptPackageInfo`, not by running a build.
- The app config was broken before ESLint 10. `ALFA/APPS/.eslintrc.js` (`root: true`) extended `next/core-web-vitals`, which eslint-config-next has published only as flat configs since it reached 16 on 2026-07-07 (fdb30184d). The eslintrc loader cannot read them: `FlatCompat` stops on "Converting circular structure to JSON".
- Nothing in CI or lefthook runs ESLint. `.vscode/settings.json` runs `source.fixAll.eslint` on save, with `eslint.useFlatConfig: false`. This host has no ESLint editor extension installed. The operator's checkout still has ESLint 9.38 and TypeScript 6.0.3 from a stale install.

## 2. Clean

PR #906 (code lane):

- `eslint.config.js` is `.eslintrc.js` rule for rule: `@eslint/js` recommended, the nine repo rules, and typescript-eslint's flat `recommended` scoped to `**/*.ts` and `**/*.tsx` (unscoped, it would apply to every file), plus the four TypeScript rules. The override's second `eslint:recommended` is dropped: re-applying it only resets severities and keeps the base options, in both systems. Global ignores:
  - dot-paths: eslintrc's built-in default, which flat config dropped; `.claude/worktrees` holds whole checkouts;
  - `CHAR/DOCS/`: the generated mirror;
  - `**/vendor/`: a minified Mermaid bundle;
  - `third_party/`: the submodule, 166 JS/TS files in the operator's checkout;
  - `artifacts/`.
- `ALFA/APPS/eslint.config.js` is eslint-config-next's flat `core-web-vitals` with the same `settings.next.rootDir`. ESLint 10 applies the config file nearest to each linted file, which keeps the root rules out of the app, as `root: true` did.
- TypeScript, following the release post: `typescript` becomes `npm:@typescript/typescript6@^6.0.2`, which re-exports 6.0.3, and `@typescript/native` becomes `npm:typescript@^7.0.2`, so `tsc` stays 7.0.2. Scoping the 6.0 API to the linters fails on pnpm 10.18.1, because pnpm resolves peers from the root importer: a `"@typescript-eslint/parser>typescript"` override is written to the lock but changes nothing, and a `packageExtensions` dependency loses to the peer. The only scoped route left is a `.pnpmfile.cjs` hook that rewrites manifests on every install, CI and Dependabot included. An espree-only setup would drop the 127 TypeScript files. With the alias, every consumer gets the 6.0 API: typescript-eslint, eslint-config-next, Next.js, and Prisma's and valibot's optional peers. No repo source imports `typescript` since #894.
- Declared: `@eslint/js ^10.0.1`, whose recommended set equals ESLint 10.13.0's 64 recommended rules, and `globals ^16.4.0`, already in the lock.
- `BRAV/SCPT/guardrails.json`: `eslint.config.js` replaces `.eslintrc.js` in `allowed_top_level`, because `check_guardrails.py --strict` flagged the new file.
- `.vscode/settings.json`: `eslint.useFlatConfig: false` is removed.

PR #907 (CI lane): the `unit` job runs `eslint . --format json` after `tsc`, whenever the install succeeded. The step passes on findings (exit 1). It fails on exit 2 or higher and on any fatal message, because a broken TypeScript parser reports through fatal messages, not through the exit code. The summary shows the outcome and the counts, the JSON joins the `unit-test-results` artifact, and `docs/status/workflows.json` is regenerated.

Not done: fixing the findings, and a ratchet on the counts (§3, Next).

## 3. Report

| Check | `main` (fresh install) | #906 (fresh install, main 729121a13 + #906) |
| --- | --- | --- |
| `pnpm exec eslint .` | exit 2, no config | **237 files: 3,387 errors (3,042 autofixable), 1,906 warnings, 0 parse errors**; 15 s; exit 1 |
| root config (205 files) vs `FlatCompat` of the original `.eslintrc.js` | — | no rule or option difference on any file; all 5,293 messages identical, and the same 11 files ignored |
| `ALFA/APPS` (32 files, Next config) | — | 0 / 0; a probe file trips react-hooks, @next/next, jsx-a11y and import rules |
| fixAll: `loadESLint()`, then `lintText` with `fix: true` | throws "Could not find config file." | `instrumentation.ts` 2 → 0 errors; `BRAV/SCPT/signoz-export.mjs` 231 → 1 |
| jest / `node --test` / `tsc --noEmit` | 124 / 17 / exit 0 | 124 / 17 / exit 0, `tsc` 7.0.2 |
| `pnpm install --lockfile-only` after merging `main` | — | lock unchanged |
| #906's checks (unit job run 41658222593) | — | all green, including the unit job, Repository Structure Compliance and both OSV scans |
| #907's unit job, first run 41658888186 | — | install, prisma, jest (124), node tests and `tsc` green; **Lint (eslint) red**: "couldn't find an eslint.config.* file", exit 2 |
| #907's step, run locally: #906's tree / #906 plus one unparseable file | — | exit 0, with 237 / 3387 / 1906 in the summary / exit 1, "could not parse 1 file(s)" |

- Baseline by rule:
  - errors: indent 1,515, quotes 810, semi 465, curly 238, no-unused-vars 71, no-undef 68, `@typescript-eslint/no-unused-vars` 66, no-useless-escape 43, no-empty 25, no-case-declarations 25, preserve-caught-error 20, prefer-const 13, `@typescript-eslint/no-require-imports` 12, no-useless-assignment 6, eqeqeq 6, no-dupe-keys 2, no-var 1, `@typescript-eslint/ban-ts-comment` 1;
  - warnings: no-console 1,700, `@typescript-eslint/no-explicit-any` 206.
- Baseline by directory (files, errors, warnings): BRAV 90, 2,065, 1,446; scripts 39, 714, 234; ALFA 87, 456, 196; docs 6, 119, 14; root 11, 13, 10; DELT 2, 10, 4; assets 1, 8, 2; CHAR 1, 2, 0.
- The 68 no-undef are k6 globals (`__ENV`, `__ITER`) and Jest globals in `.js` tests. preserve-caught-error and no-useless-assignment count because ESLint 10 added them to recommended, not because of the migration.
- Deltas from the eslintrc run:
  - `globals` 16.4.0 replaces the bundled 14.0.0: 19 obsolete browser APIs are no longer predefined (AppCache, `openDatabase`, `defaultStatus`, …) and 421 newer ones are. No repo file is affected; the FlatCompat run on 14.0.0 reports the same 68 no-undef.
  - `indent`, `quotes` and `semi` have been deprecated since ESLint 8.53 and are removed in ESLint 11.
- Found on the way, not changed: `BRAV/SCPT/verify-automation.ps1` lists `.eslintrc.js` among its 12 required files, but it has no callers and 6 of the 12 were already missing. eslint-config-next's plugins (import 2.32.0, jsx-a11y 6.10.2, react 7.37.5) declare ESLint ≤ 9 as their peer range, yet they load and report under 10.13.0.
- Proposed `BOSSCAT_LOG.md` line (docs lane, its own PR after both merge): `- <ts>Z — **[ESLINT 10: FLAT CONFIG + CI STEP]** #699 left ESLint 10.13.0 without a flat config and typescript-eslint without a TypeScript API (7.0.2 ships none); nothing ran it. #906: \`eslint.config.js\` reproduces \`.eslintrc.js\` message for message, the app keeps its Next config, \`typescript\` is aliased to \`@typescript/typescript6\` with \`tsc\` still 7.0.2: 237 files, 3,387 errors, 1,906 warnings, 0 parse errors. #907: the unit job fails when ESLint cannot run (red on main, green after #906). (\`ECRR_ESLINT10_FLAT_CONFIG_20261103.md\`)`
- Next:
  1. #906 on the operator's go. Dependabot #890 bumps eslint to 10.14.0 in the same lock lines, so whichever lands second regenerates its lock. If #906 lands first, Dependabot rebases #890; do not update-branch #890.
  2. Update #907's branch, wait for its green run, then merge it.
  3. `pnpm install --frozen-lockfile` in the operator's checkout.
  4. This report's addendum, then the log line and the mirror.
  5. Rollback: revert #907 with or before #906, or the step turns red on every push.
- Open decisions, for the operator: whether to autofix the 3,042 fixable errors (one mechanical PR, mostly indent, quotes and semi); whether to replace `indent`, `quotes` and `semi` before ESLint 11 (`@stylistic/eslint-plugin`, or leave formatting to Prettier); whether to add a ratchet on the counts. Return to a plain `typescript` once TypeScript 7.1 ships its API and typescript-eslint supports it.

## 4. Role

Claude Code (local seat): the reproduction, PRs #906 and #907, and this report. Nothing was merged and no workflow was dispatched; #907's red run came from its own `pull_request` event. The comparison tooling (`@eslint/eslintrc` for `FlatCompat`) ran from a scratch directory outside the repo. Operator `@fubumaki`: the merge gos, the reinstall, and the open decisions above.

**Status:** OPEN until #906 and #907 are merged and the green run is recorded here as an addendum.

## 5. Addendum (2026-11-04): merged, the step green on `main`, and four corrections from the review seat

- Merged on the operator's go, squash, after an update-branch and fresh checks, with the `Driving:` assignment posted on #900 before the cascade's first merge: #906 `8542c978f` (21:05Z), #907 `e4d60b5d0` (21:07Z), this report #908 `c81c351bc` (21:09Z). Dependabot closed #890 at 21:11Z and opened #915 on the new `main` (eslint 10.13.0 → 10.14.0 and three other bumps), so the lock conflict §3 expected resolved without an update-branch.
- The step's first green run: #907's `unit` job after #906 merged (PR run 41912850767, head `2fbbe590b`), `Lint (eslint)` green. On `main` (push run 41913165686, head `e4d60b5d0`) every step is green: jest 5 suites and 126 tests, `node --test` 17 of 17, `tsc --noEmit` clean, and ESLint over 238 files with 3,389 errors (3,042 autofixable), 1,906 warnings and 0 fatal messages, read from the run's `eslint-results.json`. That is one file and two errors more than §3's baseline: #903's new `signoz-endpoint.test.ts`, with two `@typescript-eslint/no-require-imports`.
- Corrections from the review seat, each re-measured by the local seat:
  1. **#699 took ESLint to 10.9.1, not 10.13.0** (the header's Trigger and §3's proposed log line). It moved ESLint from 9.39.5 to 10.9.1 (`^9.38.0` → `^10.9.1`) and TypeScript from 6.0.3 to 7.0.2. ESLint 10.13.0 was published on 2026-10-16; `main` reached it through #776 (2026-09-08, 10.10.0) and #876 (2026-11-01, 10.13.0). The trigger is still #699's move from 9 to 10. #906's and #907's descriptions repeat the slip, and so does `ECRR_TS7_JEST_TOOLCHAIN_20261102.md` §1c (addendum there).
  2. **Under TypeScript 7, ESLint exits 2 while loading its config, with no per-file parse errors** (§1, second bullet, and the reason §2 gives for #907's fatal-message check). `@typescript-eslint/parser/dist/index.js:37-50` reads `ts.versionMajorMinor` when it is required and throws "typescript-eslint does not support TS 7.0." for any major version from 7 up, before it loads its parser. With a plain `typescript@7.0.2` on #906's tree (`797a25067`), a `.ts` file, a `.mjs` file and `eslint .` each exit 2 from `eslint.config.js`, lint nothing and write no JSON; the app config stops the same way through eslint-config-next. A per-file "Parsing error" with exit 1 comes only from a parser that throws while parsing. #907's step therefore catches TypeScript 7 through its exit-code check (`rc -gt 1`), not its fatal-message check; §2's #907 paragraph, the comment above the step and #907's description name the wrong mechanism (not changed here).
  3. **The flat config lints 19 `.mjs`/`.cjs` files the old config skipped** (18 `.mjs`, 1 `.cjs`), adding 462 errors and 206 warnings (all no-console) to the baseline. Flat config matches `**/*.mjs` and `**/*.cjs` by default; eslintrc's `eslint .` selected only `*.js` and the `overrides[].files` patterns (`*.ts`, `*.tsx`). §3's FlatCompat comparison ran under flat-config file selection, so its 205 files include the 19 and could not show the difference. An eslintrc-mode run of the old root config with the same ignores (ESLint 9.38.0) lints 218 files; on the 186 root-scope files both select, the messages match except preserve-caught-error (20) and no-useless-assignment (5), two of the three rules ESLint 10 added to recommended.
  4. **The TypeScript 6 alias takes `typescript` out of Dependabot version updates.** dependabot-core's npm parser drops any `package.json` requirement that starts with `npm:`, and its pnpm path skips the lock records an importer aliases (only dependency-graph jobs de-alias them); no `dependabot.yml` key restores them. npm-all will not propose TypeScript 7.x or `@typescript/typescript6` 6.0.x, and gives no notice. The dependency graph still lists `typescript` 7.0.2 and 6.0.3 and `@typescript/typescript6` 6.0.2, so security alerts can open, but a security update for them would end in a `dependency_not_found` job error, not a PR. #915, the first npm-all PR after the merge, has no TypeScript entry, which fits but proves nothing, since npm has nothing newer to offer. Neither #906 nor this report recorded the loss. It needs a recorded decision (operator), next to §3's return to a plain `typescript` once TypeScript 7.1 ships its API.
- Verdict: **GREEN**. The header's condition is met. Open for the operator: item 4's decision, §3's three decisions, and `pnpm install --frozen-lockfile` in `C:\otel`.

**Status:** CLOSED (2026-11-04).

## 6. Addendum (2026-11-05): the step's comment corrected

- #919 (`17acdd000`, 13:05Z) rewrote the comment above the `Lint (eslint)` step, which §5's correction 2 found naming the wrong mechanism. It now says that a parser that refuses to load (typescript-eslint under TypeScript 7) makes ESLint exit 2, which the exit-code check catches, and that a parser that throws while parsing gives a fatal "Parsing error" per file. Comment only; `docs/status/workflows.json` was regenerated for Registry Guard. #907's description and §2's sentence stay as filed, corrected by §5.

**Status:** CLOSED (unchanged).
