# env.nu
#
# Installed by:
# version = "0.108.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

# SSH agent setup
# Start ssh-agent if not running
if (ps | where name == "ssh-agent" | is-empty) {
    let agent_output = (ssh-agent -c | complete)
    if $agent_output.exit_code == 0 {
        let agent_lines = ($agent_output.stdout | lines | where {|line| $line =~ "^setenv"})
        let agent_vars = ($agent_lines | parse "setenv {name} {value};" | reduce -f {} {|it, acc| $acc | insert $it.name $it.value })
        load-env $agent_vars
    }
}

# Ensure SSH_AUTH_SOCK is set
if ($env.SSH_AUTH_SOCK? | is-empty) {
    let agent_output = (ssh-agent -c | complete)
    if $agent_output.exit_code == 0 {
        let agent_lines = ($agent_output.stdout | lines | where {|line| $line =~ "^setenv"})
        let agent_vars = ($agent_lines | parse "setenv {name} {value};" | reduce -f {} {|it, acc| $acc | insert $it.name $it.value })
        load-env $agent_vars
    }
}

# Add ~/.local/bin to PATH
$env.PATH = ($env.PATH | split row (char esep) | prepend ($env.HOME | path join ".local" "bin"))

# Nix profile setup
$env.PATH = ($env.PATH | split row (char esep) | prepend "/nix/var/nix/profiles/default/bin")

# Set XDG_DATA_DIRS for Nix
let nix_data_dir = "/nix/var/nix/profiles/default/share"
$env.XDG_DATA_DIRS = if ($env.XDG_DATA_DIRS? | is-empty) {
    $"/usr/local/share:/usr/share:($nix_data_dir)"
} else {
    $"($env.XDG_DATA_DIRS):($nix_data_dir)"
}

# Set NIX_SSL_CERT_FILE
if ($env.NIX_SSL_CERT_FILE? | is-empty) {
    if ("/etc/ssl/certs/ca-certificates.crt" | path exists) {
        $env.NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt"
    }
}