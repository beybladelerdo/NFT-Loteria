#!/usr/bin/env bash
set -euo pipefail

read -rs -p "dfx dev identity password: " DFX_PASS
echo

run() {
  local cmd="$*"
  expect -f /dev/stdin -- "$cmd" "$DFX_PASS" <<'EXP'
    # argv0.. = args after --
    set cmd [lindex $argv 0]
    set pw  [lindex $argv 1]

    log_user 1
    set timeout -1

    spawn -noecho bash -lc $cmd
    expect {
      -re {Please enter the passphrase for your identity:} { send -- "$pw\r"; exp_continue }
      -re {(?i)enter passphrase.*:}                       { send -- "$pw\r"; exp_continue }
      -re {(?i)passphrase.*:}                             { send -- "$pw\r"; exp_continue }
      -re {(?i)password.*:}                               { send -- "$pw\r"; exp_continue }
      eof
    }
    catch wait result
    exit [lindex $result 3]
EXP
}

run dfx deps init
run dfx deps pull
run dfx deps deploy

run bash ./deploy_ledgers.sh
run dfx deploy

run "dfx canister call backend bootstrapAdmin '()'"
