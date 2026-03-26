perform `jj bookmark set $1` and then `jj git push --bookmark $1`

Default to `master` if argument is omitted.

If the push is rejected because of an empty intermediary commit, just run `jj describe -r $thatcommitstring -m "."`
