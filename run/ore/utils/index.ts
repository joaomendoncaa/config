import { $ } from 'bun';

/**
 * Format hash string to only include the first and last 4 characters joint by ellipsis.
 * @param hash string containing the hash.
 * @returns string with formated hash.
 */
export function hashWithEllipsis(hash: string): string {
	if (hash.length <= 8) return hash;

	const [left, right] = [hash.slice(0, 4), hash.slice(-4)];

	return `${left}...${right}`;
}

export async function getPubkey(path: string): Promise<string> {
	return (await $`solana-keygen pubkey ${path}`.text()).trim();
}
