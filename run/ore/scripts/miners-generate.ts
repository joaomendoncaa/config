import { readdir } from "node:fs/promises";
import { $ } from 'bun';
import { hashWithEllipsis } from "../utils";

export async function getPubkey(path: string): Promise<string> {
	return new Promise(async (resolve) => {
		const pk = (await $`solana-keygen pubkey ${path}`.text()).trim();
		resolve(pk)
	})
}

const wallets = await readdir("./wallets");

if (wallets.length === 0) {
	throw new Error("No wallets found in ./wallets directory");
}

let apps: any[] = [];

for (let i = 0; i < wallets.length; i++) {
	const wallet = wallets[i];
	const minerPath = `./wallets/${wallet}`;
	const pubkey = await getPubkey(minerPath);

	apps.push({
		"name": `$ORE Miner ${hashWithEllipsis(pubkey)}`,
		"namespace": "ore-miners",
		"script": "/home/joao/lab/ore-cli/target/release/ore",
		"instances": 1,
		"cron": '*/60 * * * *',
		"log_date_format": "YYYY-MM-DD HH:mm:ss",
		"args": [
			"--rpc",
			process.env.RPC_MAINNET,
			"--keypair",
			minerPath,
			"--priority-fee",
			"1",
			"mine",
			"--threads",
			"12"
		]
	});

	apps.push({
		"name": `$ORE Miner ${hashWithEllipsis(pubkey)}`,
		"namespace": "ore-claimers",
		"script": "/home/joao/lab/ore-cli/target/release/ore",
		"instances": 1,
		"exec_mode": "fork",
		"log_date_format": "YYYY-MM-DD HH:mm:ss",
		"args": [
			"--rpc",
			process.env.RPC_MAINNET,
			"--keypair",
			minerPath,
			"--priority-fee",
			"1",
			"claim",
		]
	});
}


console.log({
	wallets,
	apps,
})

const minersFileRaw = `
		module.exports = {
			apps: ${JSON.stringify(apps)}
		}
`;

Bun.write('./processes/miners.config.cjs', minersFileRaw);


