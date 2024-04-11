import { $ } from 'bun';
import c from 'chalk';
import { getPubkey, hashWithEllipsis } from '../utils';

const miners = new Array(14).fill(0).map((_, idx) => idx);

let totalOre = 0;

async function logBalance(idx: number): Promise<boolean> {
	return new Promise(async (res) => {
		const pubkey = await getPubkey(`./wallets/miner_${idx}.json`);
		const balance = parseFloat(await $`solana balance ${pubkey}`.text());
		const ore = parseFloat(await $`ore --keypair ./wallets/miner_${idx}.json rewards`.text());
		const balanceStr = balance < 0.01 ? c.red(balance + " SOL") : c.green(balance + " SOL");

		totalOre += ore;

		console.log(c.gray(`${c.whiteBright(hashWithEllipsis(pubkey))} funded with ${balanceStr} with claimable ${c.bgYellowBright.blackBright.bold(ore + " ORE")}`));


		res(true);
	})
}

await Promise.all(miners.map(logBalance));

console.log(`\nTotal claimable ${totalOre} ORE`);
