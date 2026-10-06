# numeric-calculation-handson

A Japanese-language, test-driven hands-on course on quality assurance for numerical computation, in Julia 1.12.
Learners grow the library `StableNumerics` over Iterations 0–7 (summation, quadratic roots, variance, LU, QR least squares, exp, fixed-step ODE solvers with order-of-convergence checks, adaptive and symplectic ODE solvers).
`COURSE.md` is the course plan (audience, layout, conventions, pitfalls); `docs/ROADMAP.md` specifies every Iteration.
Build or change Iterations with the `system-development-skills:build-handson` skill.

# RTK (Rust Token Killer)

Prefix every shell command with `rtk`, including each command in an `&&` chain — it is always safe (a dedicated filter cuts noisy output for tests, builds, git, and more; anything without one passes through unchanged). The full command reference is in the global `~/.claude/RTK.md` (already loaded, if set up). Meta commands: `rtk gain` (savings so far), `rtk discover` (missed opportunities in past sessions), `rtk proxy <cmd>` (run unfiltered, for debugging).

## Working conventions

- Material is written in Japanese, plain style (である調), with `，` and `．` as punctuation; textlint and markdownlint enforce this.
- Every output shown in the material (REPL results, test failures) is copied from a real run.
- Test tolerances are derived from the error bounds written in `design/error-spec.md`, never chosen ad hoc.
- `git commit` runs the lefthook hooks. If they fail, fix the reported issues. Do not use `--no-verify`.

- Run `mise run check` after making changes.

## Code map

- `iterations/iteration-N/{exercise,solution}/`: independent Julia packages named `StableNumerics` (exercise N = solution N-1 apart from README, TESTLIST, docs).
- `docs/`: roadmap, guides (`qa.md`, `tdd.md`, `design.md`), and per-Iteration notes (`theory/`, `julia/`).
- `scripts/check_design.jl`: checks Mermaid syntax, dependency diagram vs `using`, and error spec vs exports.
- `scripts/test_all.jl`: runs `Pkg.test()` for every package.

# Artifact Cleanup

## Golden Rule

**Whenever you produce an artifact, always run the `system-development-skills:finalize-artifacts` skill to clean it up before reporting the work as done.**

An artifact is any deliverable you create or substantially rewrite: documents, READMEs, code and code comments, config files, scripts, commit messages, PR descriptions, and so on.

- Invoke the skill via the Skill tool (`system-development-skills:finalize-artifacts`) after the artifact is written and before the final reply.
- The skill edits the artifact files in place. Do not append a changelog of the cleanup to the artifact; in the final reply, mention what changed in a sentence or two at most unless the user asks for a full report.
- Skip it only for replies that produce no artifact (answering questions, explaining code, running read-only commands).
- Provided by the `enunun/system-development-skills` plugin (see `extraKnownMarketplaces`/`enabledPlugins` in `.claude/settings.json`).
