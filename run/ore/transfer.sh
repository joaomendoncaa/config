# @Author: Cissoko420
# @Date:   2024-04-10 05:06:10
# @Last Modified by:   Cissoko420
# @Last Modified time: 2024-04-10 05:06:10
#!/bin/bash

receiver_wallet="wallet_address"

nr_wallets=11

min_balance_to_send=0.01

clear

while true; do
	for ((i = 1; i <= nr_wallets; i++)); do

		balance=$(ore --keypair ~/.config/solana/ids/id$i.json balance | grep -oP '^\d+(.\d+)?(?= ORE)')
		send_balance=$(echo "$balance - 0.000000001" | bc)

		if [ ! -z "$balance" ] && [ "$(echo "$balance > $min_balance_to_send" | bc)" -eq 1 ]; then
			echo "ID$i balance: $balance ORE - To Transfer"
			spl-token transfer oreoN2tQbHXVaZsr3pf66A48miqcBXCDJozganhEJgz $send_balance $receiver_wallet --owner ~/.config/solana/ids/id$i.json --fund-recipient --fee-payer ~/.config/solana/ids/id$i.json
			echo ""
			sleep 2
		else
			echo "ID$i balance: $balance ORE - No balance to send"
			echo ""
		fi
	done
	echo "Waiting to do next run"
	echo ""
	sleep 300
	clear
done
