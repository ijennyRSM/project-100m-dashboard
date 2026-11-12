import { defineConfig, devices } from '@playwright/test';
export default defineConfig({
  testDir: './tests/browser',
  fullyParallel: true,
  reporter: [['list'], ['json', { outputFile: 'test-results/results.json' }]],
  use: { baseURL: process.env.BASE_URL || 'http://127.0.0.1:5500', trace: 'retain-on-failure',
    launchOptions: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH ? { executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH } : {} },
  projects: [
    { name: 'chromium-desktop', use: { ...devices['Desktop Chrome'] } },
    { name: 'chromium-mobile', use: { ...devices['iPhone 13'], defaultBrowserType: 'chromium' } }
  ],
  webServer: { command: 'node scripts/dev-server.mjs', url: process.env.BASE_URL || 'http://127.0.0.1:5500', reuseExistingServer: !process.env.CI }
});
