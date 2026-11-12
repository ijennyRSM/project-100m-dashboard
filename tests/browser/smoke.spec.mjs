import { test, expect } from '@playwright/test';

test.beforeEach(async ({ page }) => {
  // Fresh browser storage; never use an owner's real account or health exports.
  await page.route(/https:\/\/[^/]*supabase\.co\//, route => route.abort());
});

test('local entry-page assets and five navigation destinations load', async ({ page, request }) => {
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await expect(page.locator('[data-page="home"]:visible').first()).toBeVisible();
  const assets = await page.locator('script[src],link[rel="stylesheet"],link[rel="icon"]').evaluateAll(nodes => nodes.map(n => n.src || n.href));
  for (const url of assets) {
    if (new URL(url).origin !== new URL(page.url()).origin) continue;
    const response = await request.get(url);
    expect(response.ok(), url).toBeTruthy();
  }
  for (const dest of ['plans', 'history', 'recovery', 'settings', 'home']) {
    await page.locator(`[data-page="${dest}"]:visible`).first().click();
    await expect(page).toHaveTitle(dest === 'home' ? /หน้าหลัก/ : new RegExp(dest));
    await expect(page.locator('h1').first()).toBeVisible();
  }
  await page.locator('[data-page="settings"]:visible').first().click();
  await expect(page.locator('#healthFileV2')).toBeAttached();
  expect(errors).toEqual([]);
});

test('partial retains next session; completed advances; data survives reload', async ({ page }) => {
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => !!window.P100);
  const result = await page.evaluate(() => {
    const a = window.P100;
    a.startPlan('sprint100');
    const first = a.planOverview(a.activePlan()).next.key;
    a.recordSession(first, { status: 'partial', notes: 'Synthetic test' });
    const partial = a.planOverview(a.activePlan()).next.key;
    a.recordSession(first, { status: 'completed' });
    return { first, partial, next: a.planOverview(a.activePlan()).next.key };
  });
  expect(result.partial).toBe(result.first);
  expect(result.next).not.toBe(result.first);
  await page.reload({ waitUntil: 'domcontentloaded' });
  expect(await page.evaluate(() => window.P100.planOverview(window.P100.activePlan()).next.key)).toBe(result.next);
});

test('external CDN assets are reachable @online', async ({ page, request }) => {
  test.skip(!process.env.CHECK_EXTERNAL_ASSETS, 'Opt-in live network diagnostic; run with CHECK_EXTERNAL_ASSETS=1');
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  const urls = await page.locator('script[src],link[rel="stylesheet"]').evaluateAll(nodes => nodes.map(n => n.src || n.href));
  for (const url of urls.filter(u => new URL(u).origin !== new URL(page.url()).origin)) {
    expect((await request.get(url)).ok(), url).toBeTruthy();
  }
});

test('development server hides git metadata and test artifacts', async ({ request }) => {
  for (const path of ['/.git/config', '/node_modules/@playwright/test/package.json', '/test-results/results.json']) {
    expect((await request.get(path)).status()).toBe(404);
  }
});
