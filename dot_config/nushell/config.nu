# config.nu
#
# Installed by:
# version = "0.108.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

# Display random Riddle of Strider line on startup
print (open ~/.config/nushell/lines.txt | lines | shuffle | first)

# Prompt for SSH key passphrase at shell launch
# Only add if key not already loaded
# if (ssh-add -l | complete | get exit_code) != 0 {
#     ssh-add ~/.ssh/id_qd_ed25519
# }

def prompt [] {
    let last_code = $env.LAST_EXIT_CODE
    let indicator = if $last_code != 0 {
        $"(ansi red_bold)✗($last_code)(ansi reset) "
    } else {
        ""
    }

    # You can customize the rest of your prompt here
    $"($indicator)(ansi white)(whoami)@(hostname)(ansi reset):(ansi green)($env.PWD)(ansi reset):(ansi red)∀>>>$(ansi reset) "
}

# Hook it up
$env.PROMPT_COMMAND = { prompt }

export def trinity [
  --sequential(-s)  # run sequentially instead of parallel
  --ci              # if set, return non-zero on failure (for CI) but don't kill shell
] {
  let cmds = [
    'uv run ruff format'
    'uv run ruff check --fix'
    'uv run ty check'
    'uv run pytest'
  ]

  def run-one [cmd] {
    print $"▶ ($cmd)"
    let codefile = $"/tmp/trinity-((random uuid)).code"
    # run the command through bash so your env/uv aliases apply
    do -i { ^bash -lc $'{ ( $cmd ); }; ec=$?; printf "%s" "$ec" > "($codefile)"' }
    let code = (open $codefile | into int)
    rm -f $codefile
    { cmd: $cmd, code: $code }
  }

  let results = if $sequential {
    mut acc = []
    for c in $cmds {
      $acc = ($acc | append (run-one $c))
    }
    $acc
  } else {
    $cmds | par-each {|c| run-one $c }
  }

  $results | sort-by code cmd | table

  let failed = ($results | any {|r| $r.code != 0})
  if $failed {
    print "❌ one or more steps failed."
    if $ci {
      error make --unspanned { msg: "trinity: one or more steps failed" }
    }
  } else {
    print "✅ all steps passed."
  }
}

export def jp [
  bookmark: string = "master"
] {
  jj bookmark set $bookmark
  jj git push --bookmark $bookmark
}

alias l = ls --all --long
alias c = /home/q/.local/bin/claude --dangerously-skip-permissions
alias g = /usr/bin/gemini
alias ur = uv run
alias gsd = npx get-shit-done-cc

$env.config.show_banner = false

source ./zoxide.nu
