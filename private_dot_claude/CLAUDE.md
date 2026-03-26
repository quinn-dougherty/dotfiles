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
