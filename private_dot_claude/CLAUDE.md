# Version Control

Incrementally adopting jj (jujutsu) v0.34.0 - check for `.jj/` vs `.git/` directory

## jj Command Rules
- NEVER use jj commands that open an editor interactively
- Always use non-interactive flags when available:
  - Use `jj describe -m "message"` instead of `jj describe` (which opens editor)
  - Use `jj new -m "message"` instead of `jj new`
  - Use `jj squash -m "message"` instead of `jj squash`
  - Use `jj split --interactive` with stdin redirection or avoid split if it requires editor
  - For any command that would open an editor, use the `-m` flag to provide the message inline

# Delegating low-level work to Antigravity (`agy`)

Operating model: **you orchestrate, Antigravity executes.** `agy` is a headless
coding agent (Gemini 3) on PATH. For concrete, self-contained implementation
work, delegate to the `antigravity` subagent rather than doing it inline — it
runs `agy -p` and returns a summary, keeping this context clean.

- **Delegate**: scaffolding, boilerplate, mechanical/repetitive edits across
  files, writing tests, running builds/test suites and iterating to green,
  format/lint fixups — work that is well-specified enough to hand off.
- **Keep for yourself**: planning and decomposition, deciding *what* to build,
  reviewing and integrating `agy`'s output, and trivial one-line edits where a
  full `agy` round-trip costs more than just doing it.
- When you delegate, hand the subagent a fully self-contained task (paths,
  acceptance criteria, constraints) — `agy` starts with zero context.
- **Parallelize aggressively.** When you have several independent low-level
  tasks, dispatch all the `antigravity` subagents in a *single* message so
  their `agy` procs run concurrently instead of one-at-a-time. Only batch
  tasks that touch **disjoint** files; serialize anything that would edit the
  same files (or hand each conflicting task its own `git worktree`), since
  parallel `agy` procs share the working directory and will race otherwise.
