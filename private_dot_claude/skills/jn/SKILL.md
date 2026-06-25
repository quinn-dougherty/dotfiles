Write a very detailed message for the current jj change. Include co-author attribution.

Pick the right command based on where the edits live:

- **`jj describe -m "<msg>"`** — when @ already has the working-copy edits
  and you want to title *that* change. This is the common case when /jn
  is invoked after editing files. Re-running `jj describe -m` just
  rewrites the message on @. Note: you should probably run `jj new` after `jj describe -m "<message>"` so that it actually takes the changes out of the current change tree and into the history. 

- **`jj new -m "<msg>"`** — when @ is empty (e.g. right after a push,
  when jj auto-creates a fresh empty @) and you want to start a *new*
  named change before editing. `jj new -m` creates an empty child of @
  with the given description; subsequent edits land in that new @.

If you run `jj new -m` when @ already holds edits, the edits stay in
the old (still-untitled) @ and the new message ends up on an empty
child — usually not what you want. Check `jj status` first: if the
working-copy shows modifications, use `jj describe`.

Never use commands that open an editor (no bare `jj describe` or
`jj new` without `-m`).
