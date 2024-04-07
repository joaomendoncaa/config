import { $ } from 'bun';
import c from 'chalk';
import { getPubkey } from '../utils';

const miners = new Array(12).fill(0).map((_, idx) => idx);

async function logBalance(idx: number): Promise<boolean> {
	return new Promise(async (res) => {
		const pubkey = await getPubkey(`./wallets/miner_${idx}.json`);
		const balance = parseFloat(await $`solana balance ${pubkey}`.text());
		const balanceStr = balance < 0.01 ? c.red(balance + " SOL") : c.green(balance + " SOL");

		console.log(String.raw`${pubkey}${c.gray('...........')}${balanceStr}`);

		res(true);
	})
}

await Promise.all(miners.map(logBalance));
