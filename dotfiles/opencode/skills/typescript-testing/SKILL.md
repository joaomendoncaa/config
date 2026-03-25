---
name: typescript-testing
description: >
  Use for writing, running, debugging, or organizing tests in TypeScript codebases.
  Covers Bun test runner, Playwright E2E, test file conventions, mocking, fixture
  patterns, selectors, wait strategies, and monorepo test configuration. Applies to
  any TypeScript project using Bun, Jest, Vitest, or Playwright.
---

# TypeScript Testing

Conventions for unit and end-to-end testing in TypeScript projects.

## Test Runner: Bun

Bun ships a built-in test runner that replaces Jest or Vitest. No extra install needed.

```typescript
import { describe, test, expect, mock, spyOn, afterEach } from "bun:test";
```

- `describe` / `test` blocks (not `it`)
- `expect` is built-in — no separate assertion library
- `mock()` creates function mocks, `spyOn()` spies on object methods

**Run tests:**

```bash
bun test                        # all tests in current dir
bun test path/to/dir            # specific directory
bun test path/to/file.test.ts   # specific file
bun test --timeout 30000        # custom timeout
```

## Test File Placement

Three common patterns — pick one per project and be consistent:

| Pattern           | Convention               | Example                                           |
| ----------------- | ------------------------ | ------------------------------------------------- |
| `test/` directory | Mirrors `src/` structure | `test/utils/parse.test.ts` ↔ `src/utils/parse.ts` |
| Co-located        | Next to source files     | `src/components/button.test.ts`                   |
| `e2e/` directory  | Playwright specs only    | `e2e/settings/settings.spec.ts`                   |

Unit tests: `*.test.ts`. E2E specs: `*.spec.ts`.

## Monorepo Rules

In a monorepo, **never run tests from the root**. Tests belong to individual packages.

Guard the root `package.json`:

```json
{
  "scripts": {
    "test": "echo 'do not run tests from root' && exit 1"
  }
}
```

Each package defines its own test script:

```json
{
  "scripts": {
    "test": "bun test --timeout 30000"
  }
}
```

If using Turborepo, ensure tests depend on prior builds:

```json
{
  "tasks": {
    "test": {
      "dependsOn": ["^build"]
    }
  }
}
```

## Unit Test Conventions

### Basic Structure

```typescript
import { describe, test, expect } from "bun:test";

describe("parser", () => {
  test("parses valid JSON", () => {
    const result = parse('{"a": 1}');
    expect(result).toEqual({ a: 1 });
  });

  test("returns null for invalid input", () => {
    expect(parse("not json")).toBeNull();
  });
});
```

### Assertion Patterns

```typescript
expect(value).toBe(exact)
expect(value).toEqual(deep)
expect(value).toMatchObject(partial)
expect(value).toContain(substring)
expect(value).toBeDefined()
expect(value).toBeTruthy()
expect(fn).toThrow()
expect(promise).rejects.toThrow()
expect.arrayContaining([...])
expect.objectContaining({ ... })
```

### Style

- Lowercase, descriptive test names: `"returns null for empty input"`
- Prefer `const` over `let`
- Use early returns, avoid `else`
- Keep test logic simple — if you're writing complex test code, simplify the scenario

## Mocking

Avoid mocks where possible. Test real behavior. Mock only when you need to isolate external dependencies (network, filesystem, time).

### Function Mocks

```typescript
import { mock, spyOn } from "bun:test";

const fn = mock(() => "mocked");
expect(fn).toHaveBeenCalled();
expect(fn).toHaveBeenCalledWith("arg");
```

### Spying on Methods

```typescript
const spy = spyOn(someObject, "methodName").mockImplementation(() => "fake");

try {
  // code that calls someObject.methodName()
  expect(spy).toHaveBeenCalled();
} finally {
  spy.mockRestore();
}
```

### Global Replacement

```typescript
const original = globalThis.fetch;
const mockFetch = mock(() => Promise.resolve(new Response("{}")));
globalThis.fetch = mockFetch;

try {
  // code under test
} finally {
  globalThis.fetch = original;
}
```

## Preload Scripts for Test Environment

Use preload scripts to set up isolated test environments. Configure in `bunfig.toml`:

```toml
[test]
preload = ["./test/preload.ts"]
```

A preload script handles global setup that every test file needs:

```typescript
// test/preload.ts
import { afterAll } from "bun:test";
import os from "os";
import path from "path";
import fs from "fs/promises";

// Isolate environment variables
process.env.NODE_ENV = "test";
process.env.HOME = path.join(os.tmpdir(), "test-home-" + Date.now());

// Global cleanup
afterAll(async () => {
  await fs
    .rm(process.env.HOME!, { recursive: true, force: true })
    .catch(() => {});
});
```

## E2E with Playwright

### Setup

Install and configure:

```bash
bun add -d @playwright/test
npx playwright install chromium
```

`playwright.config.ts`:

```typescript
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 60_000,
  expect: { timeout: 10_000 },
  use: {
    browserName: "chromium",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 5 : 1,
  webServer: {
    command: "bun run dev",
    url: "http://localhost:3000",
    reuseExistingServer: !process.env.CI,
  },
});
```

### Import Convention

Always import from a local fixtures module, never directly from `@playwright/test`:

```typescript
// e2e/fixtures.ts
import { test as base, expect } from "@playwright/test";

export const test = base.extend<{ customFixture: string }>({
  customFixture: async ({}, use) => {
    await use("value");
  },
});

export { expect };
```

```typescript
// e2e/feature.spec.ts
import { test, expect } from "../fixtures"; // GOOD
// import { test, expect } from "@playwright/test"  // BAD
```

This lets you add project-wide fixtures without touching individual test files.

### Custom Fixtures Pattern

Extend Playwright's `test` with your own fixtures for dependency injection:

```typescript
import { test as base, expect, type Page } from "@playwright/test";

type Fixtures = {
  sdk: ReturnType<typeof createClient>;
  gotoPage: (path: string) => Promise<void>;
};

export const test = base.extend<Fixtures>({
  sdk: async ({}, use) => {
    const client = createClient({ baseUrl: "http://localhost:3000" });
    await use(client);
  },
  gotoPage: async ({ page }, use) => {
    await use(async (path) => {
      await page.goto(path);
      await expect(page.locator('[data-loaded="true"]')).toBeVisible();
    });
  },
});

export { expect };
```

### Selectors

Use `data-component`, `data-action`, or semantic roles. **Never** CSS classes or IDs.

```typescript
// GOOD
await page.locator('[data-component="prompt-input"]').click();
await page.locator('[data-action="toggle-sidebar"]').click();
await page.getByRole("button", { name: "Save" }).click();
await page.getByText("Settings").click();

// BAD — brittle, breaks on style changes
await page.locator(".css-class-name").click();
await page.locator("#some-id").click();
```

Use descriptive attributes in your HTML:

```html
<button data-component="sidebar-toggle" data-action="toggle">Toggle</button>
<div data-component="prompt-input">...</div>
```

### Action Helpers

Extract reusable interactions into an `e2e/actions.ts` module:

```typescript
import { type Page, expect } from "@playwright/test";

export async function openPalette(page: Page) {
  await page.keyboard.press("Control+Shift+P");
  await expect(
    page.locator('[data-component="command-palette"]'),
  ).toBeVisible();
}

export async function openSettings(page: Page) {
  await openPalette(page);
  await page.keyboard.type("Settings");
  await page.keyboard.press("Enter");
  await expect(page.getByRole("dialog", { name: /settings/i })).toBeVisible();
}

export async function toggleSidebar(page: Page) {
  const button = page.getByRole("button", { name: /toggle sidebar/i });
  const expanded = await button.getAttribute("aria-expanded");
  await button.click();
  await expect(button).toHaveAttribute(
    "aria-expanded",
    expanded === "true" ? "false" : "true",
  );
}
```

### Selector Helpers

Centralize selectors in `e2e/selectors.ts`:

```typescript
export const promptSelector = '[data-component="prompt-input"]';
export const sidebarSelector = '[data-component="sidebar"]';
export const listItemSelector = '[data-slot="list-item"]';

export const sessionSelector = (id: string) =>
  `${sidebarSelector} [data-session-id="${id}"]`;
```

### Utility Helpers

Cross-platform helpers in `e2e/utils.ts`:

```typescript
export const modKey = process.platform === "darwin" ? "Meta" : "Control";

export function serverUrl(port = 3000) {
  return `http://127.0.0.1:${port}`;
}
```

## Wait Strategies

### Use locator assertions, not timeouts

```typescript
// GOOD — waits for actual state
await expect(page.locator('[data-component="list"]')).toBeVisible();
await expect(page.locator('[data-component="item"]')).toHaveCount(3);
await expect(button).toHaveAttribute("aria-disabled", "false");

// BAD — arbitrary sleep, source of flaky tests
await page.waitForTimeout(3000);
await new Promise((r) => setTimeout(r, 1000));
```

### Use polling for async/observable state

```typescript
await expect
  .poll(
    async () => {
      const res = await fetch("/api/status");
      return res.ok;
    },
    { timeout: 30_000 },
  )
  .toBe(true);
```

### Override timeouts per test when needed

```typescript
test("slow operation", async ({ page }) => {
  test.setTimeout(120_000);
  // ...
});
```

### Terminal / WebSocket tests

Wait for connection readiness, not time:

```typescript
async function waitTerminalReady(page: Page) {
  await expect(page.locator('[data-component="terminal"]')).toBeVisible();
  await expect(page.locator('[data-terminal-connected="true"]')).toBeVisible();
}
```

## Test Cleanup

E2E tests should clean up after themselves. Use fixture-managed cleanup:

```typescript
test("creates and cleans up session", async ({ page, sdk }) => {
  const session = await sdk.session.create({ title: "test" });

  try {
    await page.goto(`/session/${session.id}`);
    await expect(page.locator(promptSelector)).toBeVisible();
    // ... test logic ...
  } finally {
    await sdk.session.delete({ id: session.id }).catch(() => {});
  }
});
```

For more complex scenarios, wrap cleanup in a helper:

```typescript
export async function withSession(
  sdk: Client,
  title: string,
  callback: (session: Session) => Promise<void>,
) {
  const session = await sdk.session.create({ title });
  try {
    await callback(session);
  } finally {
    await sdk.session.delete({ id: session.id }).catch(() => {});
  }
}

// Usage
test("sidebar shows session", async ({ page, sdk }) => {
  await withSession(sdk, "sidebar test", async (session) => {
    await page.goto(`/session/${session.id}`);
    await expect(
      page.locator(`[data-session-id="${session.id}"]`),
    ).toBeVisible();
  });
});
```

For resource tracking across a test (multiple sessions, directories), accumulate IDs and clean up in a `finally` block:

```typescript
test("multi-resource test", async ({ page, sdk }) => {
  const sessions: string[] = [];
  const dirs: string[] = [];

  try {
    const s1 = await sdk.session.create({ title: "one" });
    sessions.push(s1.id);
    const s2 = await sdk.session.create({ title: "two" });
    sessions.push(s2.id);
    // ... test logic ...
  } finally {
    await Promise.allSettled(sessions.map((id) => sdk.session.delete({ id })));
    await Promise.allSettled(
      dirs.map((dir) => fs.rm(dir, { recursive: true, force: true })),
    );
  }
});
```

## E2E File Structure

Organize E2E tests by feature, with shared infrastructure at the top level:

```
e2e/
├── fixtures.ts        # Custom test/expect with project fixtures
├── actions.ts         # Reusable interaction helpers
├── selectors.ts       # Centralized DOM selectors
├── utils.ts           # Cross-platform utilities (modKey, urls)
├── feature-a/
│   └── feature.spec.ts
├── feature-b/
│   └── feature.spec.ts
└── settings/
    └── settings.spec.ts
```

## Anti-Patterns

| Don't                                          | Do Instead                                            |
| ---------------------------------------------- | ----------------------------------------------------- |
| `page.waitForTimeout(3000)`                    | `expect(locator).toBeVisible()` or `expect.poll(...)` |
| `.css-class` / `#id` selectors                 | `data-component`, `data-action`, or `getByRole`       |
| Import `test` from `@playwright/test`          | Import from local `../fixtures`                       |
| Run tests from monorepo root                   | Run from each package directory                       |
| Mock everything                                | Test real behavior; mock only external deps           |
| `npm run test` / `jest` directly               | Use `bun test` if on Bun                              |
| Skip cleanup                                   | Always clean up in `finally` blocks                   |
| Assert on transient DOM (animation, highlight) | Assert on committed app state                         |
| Complex test setup in every file               | Extract to fixtures and helpers                       |
