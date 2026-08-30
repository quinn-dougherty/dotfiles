;;; cli.el -*- lexical-binding: t; -*-
;;
;; Loaded by ~/.emacs.d/bin/doom for every CLI session ($DOOMDIR is walked for a
;; cli.el alongside each enabled module's).  Interactive Emacs never loads this.

;;; Keep agent-session envvars out of Doom's envvars file.
;;
;; `doom env' -- which `doom sync' re-runs whenever ~/.emacs.d/.local/env
;; already exists -- scrapes `$SHELL -ic env' into that file, and Doom replays
;; it into `process-environment' at startup.  So running `doom sync' from a
;; ghostel buffer that is itself inside a `claude' session bakes that session's
;; markers (CLAUDECODE, CLAUDE_CODE_SESSION_ID, CLAUDE_CODE_MESSAGING_TOKEN,
;; CLAUDE_CODE_CHILD_SESSION, ...) into Emacs permanently, and every terminal
;; Emacs spawns afterwards inherits them.  `qd/claude-isl' then launches a
;; claude that believes it is a child of that *other* session, pointed at its
;; bridge and messaging token, and fails to authenticate.
;;
;; `doom-load-envvars-file' prepends to `process-environment' rather than
;; replacing it, so once these land in a running Emacs no amount of `doom sync'
;; + `SPC h r r' clears them -- only a full restart does.  Much better to keep
;; them out in the first place.
;;
;; The two bedrock.env values are denied for the mirror-image reason: that file
;; is age-encrypted at rest precisely so the credential stays out of plaintext,
;; and ~/.emacs.d/.local/env is plaintext.  A `doom sync' run from a `c-isl'
;; shell must not be able to copy it there.  ANTHROPIC_API_KEY is deliberately
;; left allowed, since gptel reads it.
(with-eval-after-load 'doom-cli-env
  (dolist (re '("^CLAUDE" "^AWS_BEARER_TOKEN" "^ANTHROPIC_CUSTOM_HEADERS$"))
    (add-to-list 'doom-env-deny re)))

;;; Don't tangle (and re-exec the CLI) when config.el is already up to date.
;;
;; :config literate hangs `+literate-tangle-h' on `doom-before-sync-hook' with
;; no up-to-date check of its own: it tangles config.org unconditionally, then
;; calls `exit!' to re-exec the CLI with __NOTANGLE=1 so the rest of the sync
;; sees the fresh config.el.  `doom sync' has already put
;; `doom-sync--abort-warning-h' on `kill-emacs-hook' by that point, so its own
;; deliberate re-exec trips it and every single sync prints
;;
;;   ! Script was abruptly aborted, leaving Doom in an incomplete state!
;;
;; before going on to finish cleanly.  (`exit!' throws to a catch in `run!', so
;; the warning cannot be suppressed by let-binding `kill-emacs-hook' around the
;; tangle -- the throw escapes that extent before kill-emacs runs.)
;;
;; Setting __NOTANGLE ourselves when config.el is already newer skips the
;; tangle, the re-exec and the bogus warning, and saves a second CLI startup on
;; every sync.  When config.org has genuinely changed the tangle still runs, and
;; the warning still appears that once.
(unless (getenv "__NOTANGLE")
  (let ((org (file-name-concat doom-user-dir "config.org"))
        (el  (file-name-concat doom-user-dir "config.el")))
    (when (and (file-exists-p el)
               (file-newer-than-file-p el org))
      (setenv "__NOTANGLE" "1"))))
