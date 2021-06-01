#!/bin/bash

# Run this command frequently to check that Geth has peers and is synced.
#
# eth-monitoring-bot.sh
#
# Run this command with optional parameter "status" to confirm Geth has peers and is synced.
#
# eth-monitoring-bot.sh status
#
# The script will send TG alerts if Geth drops below an indicated number of peers and/or is not synced. Using the "status" flag will send TG messages confirming the # number of active peers and sync status.

TOKEN=$YOUR_TELEGRAM_TOKEN
CHAT_ID=$YOUR_TELEGRAM_CHAT_ID
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

INFO=""
STATUS=0
WARNING=""
MESSAGE=""
ETH_SYNCING=$($PATH_TO_GETH_BINARY/geth attach --datadir $GETH_DATADIR_PATH/.ethereum/goerli --exec eth.syncing | sed -r "s/\x1B\[[0-9;]*[JKmsu]//g")
ADMIN_PEERS_LENGTH=$($PATH_TO_GETH_BINARY/geth attach --datadir $GETH_DATADIR_PATH/.ethereum/ --exec admin.peers.length | sed -r "s/\x1B\[[0-9;]*[JKmsu]//g")

if [[ "$1" == "status" || "$1" == "--status" ]]; then
  STATUS=1
fi

echo -e "admin.peers.length is: $ADMIN_PEERS_LENGTH"
echo -e "eth.syncing is: $ETH_SYNCING"

# If admin.peers.length < 1, then send an alert that the "Althe Geth Node has 0 Peers!"
if [ "$ADMIN_PEERS_LENGTH" -lt 1 ]; then
  WARNING+="Geth Node has 0 Peers!\n"
else
  INFO+="Geth Node has $ADMIN_PEERS_LENGTH Peers\n"
fi

# If eth.syncing ± 0, then send an alert that the "Althe Geth Node is not syncing!"
if [ "$ETH_SYNCING" == "false" ]; then
  INFO+="Geth Node is synced.\n"
else
  WARNING+="Geth Node is not synced!\n"
fi

# Send to Telegram
MESSAGE="$WARNING$INFO"
echo -e $MESSAGE

# if status option is true or if there is any warning messages.
if [[ "$STATUS" -eq 1 || $WARNING != "" ]]; then
  curl -s -X POST $URL -d chat_id=$CHAT_ID -d text="$(echo -e $MESSAGE)"
fi
