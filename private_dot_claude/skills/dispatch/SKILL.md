---
name: dispatch
description: Execute a high-level task by reading the relevant GitHub issues with `gh`, building their dependency DAG, and running the work as parallel-as-possible worktree-isolated subagents — each at a model+effort tier matched to its difficulty — that implement, test, and file a PR. Delegates mechanical work to the antigravity (agy) executor. Invoke as `/dispatch <task>`.
---

# /dispatch

`/dispatch $TASK` turns a high-level objective into review-ready PRs by:

1. reading the relevant **GitHub issues** with the `gh` CLI,
2. building the **dependency DAG** across them,
3. scheduling each issue as a **worktree-isolated subagent the moment its deps finish** (maximum parallelism),
4. at a **model + effort tier matched to the issue's difficulty** (cheap/fast for trivial work, Opus + high effort reserved for the genuinely hard),
5. each subagent implementing → testing → committing → opening a **draft PR** that `Closes #N`.

**You are the orchestrator.** You scope, plan, triage, dispatch, and integrate. Subagents do the implementation — never burn your own context on grunt work. Promote the **antigravity (`agy`, Gemini 3) executor** for mechanical/well-specified tasks; it's the cheapest tier and exactly what `agy` is for.

---

## Phase 1 — Scope & read the issues

Resolve `$TASK` to a concrete set of in-scope issues:

- **explicit numbers** ("do #12 #14 #20") → view each directly.
- **a milestone / label / epic** → `gh issue list --milestone "…"` / `--label "…"`.
- **a tracking/epic issue** with a checklist → its body's `- [ ] #N` lines are the children.
- **free-form** with no obvious issues → search (`gh issue list --search "…"`). If still nothing maps, **ask** whether to (a) proceed with synthetic sub-tasks (no issue links) or (b) `gh issue create` them first (creating issues is outward-facing — confirm before doing it).

```bash
gh issue list --state open --limit 100 --json number,title,labels,milestone
gh issue view  <N> --json number,title,body,labels,milestone,comments
gh issue view  <N> --comments
gh api repos/{owner}/{repo}/issues/<N>/sub_issues   # native GitHub sub-issues, if used
```

Read the full body **and comments** of every in-scope issue — acceptance criteria and dependency hints often live in comments.

## Phase 2 — Build the dependency DAG

Add an edge **B → A** ("A depends on B") from every signal you can find:

- **Explicit text** in body/comments: `depends on #`, `blocked by #`, `blocks #`, `after #`, `requires #`.
- **Tracking checklists / native sub-issues** (parent must often land first, or children are siblings).
- **Implicit file/area overlap** — two issues that will edit the **same files** conflict at merge. Add an edge so they **stack** instead of both branching off trunk. If overlap is unclear, fan out a quick `Explore` subagent to map which files each issue touches.

Then:

- **Detect cycles.** A true cycle can't be parallelized — break it by sequencing, merging the issues into one task, or asking the user.
- **Independent tasks** (no path between them, disjoint files) → run **concurrently**.
- Don't gate on artificial "waves": the engine starts each task the instant *its own* deps resolve, so keep edges minimal and real.

## Phase 3 — Triage model + effort per task

Match cost to difficulty. Default low; escalate only on evidence.

| Difficulty | Signals | executor | model | effort |
|---|---|---|---|---|
| **Trivial / mechanical** | typo, config/dep bump, rename, codemod, pure boilerplate, doc edit, single obvious file, crisp acceptance criteria | `antigravity` (agy) | `haiku` | `low` |
| **Moderate** | localized feature or bugfix, a few files, needs tests, light design judgement | `claude` | `sonnet` | `medium` |
| **Hard / architectural** | cross-cutting, ambiguous, new subsystem, tricky concurrency/perf/security, non-obvious tradeoffs | `claude` | `opus` | `high` (`max` for the gnarliest) |

- **Prefer the antigravity executor whenever the task is well-specified enough to hand off** — scaffolding, repetitive edits across files, test writing, build/lint fixups. That honors the "orchestrate, agy executes" operating model and keeps the expensive tiers free for real difficulty.
- A `claude` task can still delegate its *typing* to `agy -p "…"` mid-flight for bulk mechanical chunks, then review/test/PR itself. The engine's brief already nudges antigravity-executor tasks to do this.
- Reserve `opus`/`max` for issues that genuinely need it — don't spray it across the DAG.

## Phase 4 — Confirm, then dispatch

Present the plan as a compact table: **issue → title → deps → executor/model/effort → branch**. Then:

- If scope, acceptance criteria, or dependencies are genuinely ambiguous, use **AskUserQuestion** before spending tokens.
- If the run is large (many agents) or anything is risky, get a quick go-ahead. PRs default to **draft**, which keeps the blast radius small.

## Phase 5 — Execute (worktree-isolated, max-parallel)

This skill ships a reusable DAG-scheduler workflow engine next to it. Call it with the DAG you built as `args`:

```
Workflow({
  scriptPath: "<$HOME>/.claude/skills/dispatch/engine.workflow.js",   // expand $HOME to an absolute path
  args: {
    baseBranch: "master",
    draft: true,
    tasks: [
      { id:"A", issue:14, title:"add config loader", brief:"…acceptance criteria, files, constraints…",
        executor:"claude", model:"sonnet", effort:"medium", branch:"dispatch/14-config-loader", deps:[] },
      { id:"B", issue:15, title:"bump deps + codemod", brief:"…",
        executor:"antigravity", model:"haiku", effort:"low", branch:"dispatch/15-dep-bump", deps:[] },
      { id:"C", issue:20, title:"wire loader into server", brief:"…",
        executor:"claude", model:"opus", effort:"high", branch:"dispatch/20-wire-server", deps:["A"] }
    ]
  }
})
```

The engine starts every task as soon as its `deps` resolve (A and B run immediately; C waits only for A), runs each in its **own git worktree** at the chosen `model`/`effort`, stacks a single-dependency task on its predecessor's branch, and has each subagent **commit → push → open the PR** (`Closes #N`, with a "Depends on" section for stacked PRs). It returns `{ results: [{ id, issue, status, branch, prUrl, summary, notes }] }`.

Write `brief` so the subagent needs **zero** prior context: what to build, which files/areas, acceptance criteria, how to test. Use the issue body + comments verbatim where helpful.

**Lightweight fallback** — for a tiny job (≤ ~3 independent tasks, no real DAG), skip the workflow: issue parallel `Agent` calls in a **single message**, each `isolation:"worktree"` with the triaged `model` and a self-contained brief that ends in "commit, push, open a draft PR with `Closes #N`, return the URL." (The Agent tool has no per-call effort knob — pick the model accordingly, or use the workflow engine when you need effort control.)

## Phase 6 — Report

Summarize back to the user:

- the DAG (what ran in parallel vs. what was sequenced and why),
- per task: status, **PR URL**, and the executor/model/effort used,
- anything `blocked`/`failed` with the reason and a suggested next step,
- stacking/merge-order notes for dependent PRs.

---

## Guardrails

- **File PRs, never merge.** Default to **draft** PRs (matches `/gp`). Each PR `Closes #N` and links its dependencies.
- **Disjoint files → parallel; shared files → stack** (single base) or sequence. Worktrees isolate the working dir, but two PRs editing the same lines still conflict at merge — model that as a dependency edge, not raw parallelism.
- **Acyclic only.** Break real cycles before dispatching.
- **VCS:** detect `.git` vs `.jj`. Worktree isolation uses git worktrees (fine for git and git-colocated jj repos). In a pure-jj repo, follow the global jj rules (no interactive editor; `-m` everywhere) and use `jj git push`. `gh` works either way.
- **Stay the orchestrator.** Plan, triage, integrate — delegate the implementation. Lean on the antigravity executor for everything mechanical.
- Branch naming: `dispatch/<issue#>-<slug>`.
