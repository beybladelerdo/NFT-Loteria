#!/usr/bin/env bash
set -euo pipefail

# ---------- Config ----------
# Premint amounts (atomic units: 8 decimals). 1 token = 100_000_000.
ICP_PREMINT=$((1000 * 100000000))      # 1,000 ICP
GLDT_PREMINT=$((1000 * 100000000))     # 1,000 GLDT
CKBTC_PREMINT=$((1 * 100000000))        # 1 ckBTC

# Transfer fees (atomic units)
ICP_FEE=10000       # 0.0001
GLDT_FEE=10000
CKBTC_FEE=10

FEATURE_FLAGS='opt record { icrc2 = true }'

ARCHIVE_OPTS='record {
  num_blocks_to_archive = 0;
  trigger_threshold = 0;
  controller_id = principal "aaaaa-aa";
  cycles_for_archive_creation = opt 0;
}'

ICP_CAN="icp_ledger"
GLDT_CAN="gldt_ledger"
CKBTC_CAN="ck-btc_ledger"

build_init_arg () {
  local SYMBOL="$1"
  local NAME="$2"
  local FEE="$3"
  local MINTER_PRINCIPAL="$4"
  cat <<EOF
(variant { Init = record {
  token_symbol = "${SYMBOL}";
  token_name   = "${NAME}";
  minting_account = record { owner = principal "${MINTER_PRINCIPAL}"; subaccount = null };
  transfer_fee = ${FEE};
  metadata = vec {};
  feature_flags = ${FEATURE_FLAGS};
  /* No initial_balances: we'll mint explicitly from the minter to dev after deploy. */
  initial_balances = vec {};
  archive_options = ${ARCHIVE_OPTS};
} })
EOF
}

CURRENT_ID=$(dfx identity whoami)
CURRENT_PRINCIPAL=$(dfx identity get-principal)
echo "Current (dev) identity: ${CURRENT_ID} (${CURRENT_PRINCIPAL})"

if ! dfx identity list | grep -q '^minter$' ; then
  echo "Creating 'minter' identity…"
  dfx identity new minter --disable-encryption >/dev/null
fi

MINTER_PRINCIPAL=$(dfx identity --identity minter get-principal)
echo "Minter identity principal: ${MINTER_PRINCIPAL}"

ICP_ID="ryjl3-tyaaa-aaaaa-aaaba-cai"
GLDT_ID="6c7su-kiaaa-aaaar-qaira-cai"
CKBTC_ID="mxzaz-hqaaa-aaaar-qaada-cai"

ensure_canister_with_id () {
  local NAME="$1"
  local ID="$2"
  local EXISTING_ID
  if ! EXISTING_ID=$(dfx canister id "$NAME" 2>/dev/null); then
    EXISTING_ID=""
  fi
  if [ -z "$EXISTING_ID" ]; then
    echo "Creating $NAME with specified id $ID..."
    dfx canister create "$NAME" --specified-id "$ID"
  elif [ "$EXISTING_ID" != "$ID" ]; then
    echo "Found $NAME with id $EXISTING_ID but need $ID. Replacing locally…"
    # stop & delete the local canister mapping, then recreate with the specified id
    dfx canister stop "$NAME" || true
    dfx canister delete "$NAME" || true
    dfx canister create "$NAME" --specified-id "$ID"
  else
    echo "$NAME already has desired id $ID"
  fi
}

ensure_canister_with_id "icp_ledger"   "$ICP_ID"
ensure_canister_with_id "gldt_ledger"  "$GLDT_ID"
ensure_canister_with_id "ck-btc_ledger" "$CKBTC_ID"

echo "Deploying ${ICP_CAN} (LICP) with minting_account=${MINTER_PRINCIPAL}…"
dfx deploy "${ICP_CAN}" --argument "$(build_init_arg "LICP" "Local ICP" "$ICP_FEE" "$MINTER_PRINCIPAL")"

echo "Deploying ${GLDT_CAN} (LGLDT)…"
dfx deploy "${GLDT_CAN}" --argument "$(build_init_arg "LGLDT" "Local GLDT" "$GLDT_FEE" "$MINTER_PRINCIPAL")"

echo "Deploying ${CKBTC_CAN} (LCKBTC)…"
dfx deploy "${CKBTC_CAN}" --argument "$(build_init_arg "LCKBTC" "Local ckBTC" "$CKBTC_FEE" "$MINTER_PRINCIPAL")"

# ---------- Mint to DEV by switching to minter identity ----------
echo
echo "Switching to minter to mint to dev (${CURRENT_PRINCIPAL})…"
dfx identity use minter

mint_to_dev () {
  local CAN="$1"
  local AMOUNT="$2"
  echo "Minting $(printf '%s' "$AMOUNT") atomic units on ${CAN} to ${CURRENT_PRINCIPAL}…"
  dfx canister call "${CAN}" icrc1_transfer \
"(record {
  to = record { owner = principal \"${CURRENT_PRINCIPAL}\"; subaccount = null };
  amount = ${AMOUNT};
  fee = null;
  memo = null;
  from_subaccount = null;
  created_at_time = null
})"
}

mint_to_dev "${ICP_CAN}"   "${ICP_PREMINT}"
mint_to_dev "${GLDT_CAN}"  "${GLDT_PREMINT}"
mint_to_dev "${CKBTC_CAN}" "${CKBTC_PREMINT}"

# ---------- Switch back to DEV ----------
echo
echo "Switching back to dev identity (${CURRENT_ID})…"
dfx identity use "${CURRENT_ID}"

# ---------- Sanity checks ----------
echo
echo "=== Symbols ==="
printf "ICP:   "   && dfx canister call "${ICP_CAN}"   icrc1_symbol '()'
printf "GLDT:  "   && dfx canister call "${GLDT_CAN}"  icrc1_symbol '()'
printf "ckBTC: "   && dfx canister call "${CKBTC_CAN}" icrc1_symbol '()'

echo
echo "=== Dev Balances (${CURRENT_PRINCIPAL}) ==="
printf "ICP:   " && dfx canister call "${ICP_CAN}"  icrc1_balance_of \
"(record { owner = principal \"${CURRENT_PRINCIPAL}\"; subaccount = null })"
printf "GLDT:  " && dfx canister call "${GLDT_CAN}" icrc1_balance_of \
"(record { owner = principal \"${CURRENT_PRINCIPAL}\"; subaccount = null })"
printf "ckBTC: " && dfx canister call "${CKBTC_CAN}" icrc1_balance_of \
"(record { owner = principal \"${CURRENT_PRINCIPAL}\"; subaccount = null })"

echo
echo "Done ✅"