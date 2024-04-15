import { $ } from 'bun';
import pm2 from 'pm2';
import type { StartOptions, Proc } from 'pm2';
import { readdir } from "node:fs/promises";
import { hashWithEllipsis } from "./utils";

async function getPubkey(path: string): Promise<string> {
	return new Promise(async (resolve) => {
		const pk = (await $`solana-keygen pubkey ${path}`.text()).trim();
		resolve(pk)
	})
}

const wallets = await readdir("./wallets");

if (wallets.length === 0) {
	throw new Error("No wallets found in ./wallets directory");
}

let appsMiners: StartOptions;
let appsClaimers: StartOptions;

for (let i = 0; i < wallets.length; i++) {
	const wallet = wallets[i];
	const minerPath = `./wallets/${wallet}`;
	const pubkey = await getPubkey(minerPath);

	appsMiners = {
		"name": `$ORE Miner ${hashWithEllipsis(pubkey)}`,
		"namespace": "ore-miners",
		"script": "/home/joao/lab/ore-cli/target/release/ore",
		"instances": 1,
		"cron": '*/60 * * * *',
		"log_date_format": "YYYY-MM-DD HH:mm:ss",
		"args": [
			"--rpc",
			process.env.RPC_MAINNET!,
			"--keypair",
			minerPath,
			"--priority-fee",
			"1",
			"mine",
			"--threads",
			"12"
		]
	};

	appsClaimers = {
		"name": `$ORE Miner ${hashWithEllipsis(pubkey)}`,
		"namespace": "ore-claimers",
		"script": "/home/joao/lab/ore-cli/target/release/ore",
		"instances": 0,
		"log_date_format": "YYYY-MM-DD HH:mm:ss",
		"args": [
			"--rpc",
			process.env.RPC_MAINNET!,
			"--keypair",
			minerPath,
			"--priority-fee",
			"1",
			"claim",
		]
	};
}

function onStart(err: Error, _: Proc): void {
	if (err) {
		console.error('Error while launching', err.stack || err);
		return pm2.disconnect();
	}

	console.log('Applications started successfully');

	pm2.launchBus((_, bus) => {
		console.log('[PM2] Log streaming started');

		bus.on('log:out', function(packet: any) {
			console.log('[App:%s] %s', packet.process.name, packet.data);
		});
	});
}

pm2.connect((err) => {
	if (err) {
		console.error(err);
		process.exit(2);
	}

	pm2.start(appsMiners, onStart);
	pm2.start(appsClaimers, onStart);
});
