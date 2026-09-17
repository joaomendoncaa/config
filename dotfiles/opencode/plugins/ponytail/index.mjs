// Ponytail OpenCode V2 plugin ({ id, setup } shape required by opencode 2.x).
//
// Registers ponytail slash commands, skills, and per-message ruleset injection
// from the shared ponytail checkout. Skill entries must use `path` (opencode
// v2.0.5 validates skill records against { id, name, description, path,
// content }; `location` is only valid on newer cores).

import { createRequire } from 'module';
import fs from 'fs';
import path from 'path';

const require = createRequire(import.meta.url);
const { getDefaultMode } = require('/home/joao/.config/ponytail-pr/hooks/ponytail-config');
const { getPonytailInstructions } = require('/home/joao/.config/ponytail-pr/hooks/ponytail-instructions');
const { parseCommandFile } = require('/home/joao/.config/ponytail-pr/.opencode/plugins/ponytail-frontmatter.cjs');

const commandDir = '/home/joao/.config/ponytail-pr/.opencode/command';
const skillsDir = '/home/joao/.config/ponytail-pr/skills';

function skillDefinitions() {
    return fs.readdirSync(skillsDir, { withFileTypes: true }).flatMap((entry) => {
        if (!entry.isDirectory()) return [];
        const skillPath = path.join(skillsDir, entry.name, 'SKILL.md');
        let source;
        try {
            source = fs.readFileSync(skillPath, 'utf8');
        } catch (_) {
            return [];
        }
        const match = source.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)$/);
        if (!match) return [];
        const name = match[1].match(/^name:\s*(.+)$/m)?.[1]?.trim();
        if (!name) return [];
        const description = match[1].match(/^description:\s*>?\s*\r?\n((?:[ \t]+.*(?:\r?\n|$))*)/m)?.[1]
            ?.split(/\r?\n/).map((line) => line.trim()).filter(Boolean).join(' ') ?? '';
        return [{ id: name, name, description, path: skillPath, content: match[2].trim() }];
    });
}

function expandCommandTemplate(template, input) {
    const expanded = template.replaceAll('$ARGUMENTS', input);
    return !template.includes('$ARGUMENTS') && input.trim() ? `${expanded}\n\n${input}`.trim() : expanded.trim();
}

export default {
    id: 'ponytail',
    setup: async (ctx) => {
        await ctx.command.transform((commands) => {
            for (const file of fs.readdirSync(commandDir).filter((name) => name.endsWith('.md'))) {
                const name = path.basename(file, '.md');
                const parsed = parseCommandFile(path.join(commandDir, file));
                if (!parsed) continue;
                commands.add({
                    name,
                    description: parsed.description,
                    execute: async ({ sessionID, prompt, delivery }) => {
                        // opencode validates `skills`/`agents`/`files` as arrays
                        const text = expandCommandTemplate(parsed.template, prompt.text || '');
                        const clean = { sessionID, text, delivery };
                        if (prompt.files) clean.files = Array.isArray(prompt.files) ? prompt.files : [prompt.files];
                        if (Array.isArray(prompt.skills)) clean.skills = prompt.skills;
                        if (Array.isArray(prompt.agents)) clean.agents = prompt.agents;
                        await ctx.session.prompt(clean);
                    },
                });
            }
        });

        await ctx.skill.transform((skills) => {
            for (const skill of skillDefinitions()) skills.add(skill);
        });

        await ctx.session.hook('context', (event) => {
            const mode = getDefaultMode();
            if (mode === 'off') return;
            const instructions = getPonytailInstructions(mode);
            if (event.system.length > 0) {
                event.system[event.system.length - 1].text += '\n\n' + instructions;
            } else {
                event.system.push({ type: 'text', text: instructions });
            }
        });
    },
};
