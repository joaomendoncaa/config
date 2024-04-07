import { readdir } from "node:fs/promises";


function getInstanceConfig(minerPath: string) {
	return {
		"name": `$ORE Miner #${parseInt(minerPath.split("_")[1])}`,
		"namespace": "ore-miner",
		"script": "ore",
		"instances": 1,
		"cron_restart": '*/30 * * * *',
		"log_date_format": "YYYY-MM-DD HH:mm::ss",
		"args": [
			"--rpc",
			process.env.RPC_MAINNET,
			"--keypair",
			`./wallets/${minerPath}`,
			"--priority-fee",
			"100001",
			"mine",
			"--threads",
			"12"
		]
	}

}

async function main(): Promise<void> {
	const wallets = await readdir("./wallets");
	const apps = wallets.map(getInstanceConfig);

	const fileRaw = String.raw`
		module.exports = {
			apps: ${JSON.stringify(apps)}
		}
	`;

	Bun.write('./processes/miners.config.js', fileRaw);
}


main().catch(err => console.error(err))
