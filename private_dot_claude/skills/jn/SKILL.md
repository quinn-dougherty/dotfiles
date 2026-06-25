Write a very detailed message for the current jj change. Include co-author attribution.

Default to **`jj commit -m "<msg>"`** (jj 0.41+). It titles the working-copy
change at @ *and* opens a fresh empty @ on top — i.e. `jj describe` followed by
`jj new` in one step. This is the right call almost every time /jn runs after
editing files: it seals the current edits into history under your message and
leaves you a clean @ for the next batch.

Brief sidenotes (reach for these only when `jj commit` isn't what you want):

- **`jj describe -m "<msg>"`** — retitle @ *without* sealing it. Use when you
  want to keep editing the same change, or to rewrite an existing message.
- **`jj new -m "<msg>"`** — start a new empty, pre-titled change *before*
  editing (e.g. @ is already empty after a push). Subsequent edits land in it.

Never use commands that open an editor (always pass `-m`; no bare `jj commit`,
`jj describe`, or `jj new`).
