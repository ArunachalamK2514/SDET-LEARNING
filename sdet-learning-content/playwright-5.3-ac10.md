# Playwright: Taking Screenshots and Recording Videos

## Overview
In modern test automation, visual validation and debugging are crucial. Playwright provides robust capabilities to capture screenshots of web pages or specific elements, and to record videos of test executions. These features are invaluable for identifying UI regressions, understanding test failures, and providing clear evidence of application behavior.

## Detailed Explanation

### Capturing Full Page Screenshot
Playwright's `page.screenshot()` method allows capturing a screenshot of the entire viewport or the full scrollable page. This is particularly useful for visual regression testing or for documenting the state of a page at a specific point in a test.

Key options:
- `path`: (Required) The file path to save the screenshot to (e.g., `'./screenshots/full-page.png'`).
- `fullPage`: (Optional) When set to `true`, takes a screenshot of the full scrollable page, not just the viewport. Defaults to `false`.
- `omitBackground`: (Optional) Hides the default white background and allows capturing screenshots with transparency. Defaults to `false`.
- `animations`: (Optional) Whether to disable CSS animations. Defaults to `false`.
- `caret`: (Optional) Whether to hide text caret. Defaults to `true`.
- `mask`: (Optional) Specify a list of selectors that should be masked when the screenshot is taken.
- `scale`: (Optional) Scale the screenshot to a specific device pixel ratio. Defaults to the device's pixel ratio.
- `timeout`: (Optional) Maximum time in milliseconds for the operation. Defaults to `30000` (30 seconds).

### Capturing Element Screenshot
Sometimes, only a specific component or element's visual state needs to be verified. Playwright allows taking screenshots of individual elements using `elementHandle.screenshot()` or by calling `locator.screenshot()`.

### Recording Videos
Video recording is an excellent debugging aid. When a test fails, watching a video of the execution can quickly reveal the root cause, especially for flaky tests or complex user interactions. Playwright integrates video recording directly into the browser context.

To enable video recording, you need to configure it when launching the browser or creating a new browser context. The video files are typically saved in a temporary directory and can be accessed via `artifactPath` once the test run is complete or the browser context is closed.

## Code Implementation

```typescript
import { test, expect, Browser, BrowserContext, Page } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';

// Define paths for screenshots and videos
const screenshotsDir = 'test-results/screenshots';
const videosDir = 'test-results/videos';

// Ensure directories exist before tests run
test.beforeAll(async () => {
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir, { recursive: true });
  }
  if (!fs.existsSync(videosDir)) {
    fs.mkdirSync(videosDir, { recursive: true });
  }
});

test.describe('Screenshot and Video Recording', () => {
  let browser: Browser;
  let context: BrowserContext;
  let page: Page;

  test.beforeEach(async ({ playwright }) => {
    browser = await playwright.chromium.launch();
    // Configure video recording for the context
    context = await browser.newContext({
      recordVideo: {
        dir: videosDir, // Directory to save videos
        size: { width: 1280, height: 720 }, // Video resolution
      },
    });
    page = await context.newPage();
  });

  test.afterEach(async () => {
    // Save video after test (Playwright automatically saves on context close)
    // You can access the video path via context.video()
    const videoPath = await page.video()?.path();
    if (videoPath) {
      console.log(`Video saved at: ${videoPath}`);
      // If you need to move/rename the video, do it here.
      // Example: fs.renameSync(videoPath, path.join(videosDir, `test-video-${Date.now()}.webm`));
    }
    await context.close();
    await browser.close();
  });

  test('should capture full page screenshot and element screenshot', async () => {
    await page.goto('https://playwright.dev/docs/screenshots');

    // 1. Capture full page screenshot
    const fullPageScreenshotPath = path.join(screenshotsDir, 'playwright-docs-full.png');
    await page.screenshot({ path: fullPageScreenshotPath, fullPage: true });
    console.log(`Full page screenshot saved: ${fullPageScreenshotPath}`);
    expect(fs.existsSync(fullPageScreenshotPath)).toBeTruthy();

    // 2. Capture element screenshot
    // Using locator for element screenshot
    const element = page.locator('nav.navbar'); // Example: screenshot the navigation bar
    const elementScreenshotPath = path.join(screenshotsDir, 'playwright-navbar.png');
    await element.screenshot({ path: elementScreenshotPath });
    console.log(`Element screenshot saved: ${elementScreenshotPath}`);
    expect(fs.existsSync(elementScreenshotPath)).toBeTruthy();

    // Demonstrate masking an element in a screenshot
    const maskedScreenshotPath = path.join(screenshotsDir, 'playwright-masked.png');
    await page.screenshot({
      path: maskedScreenshotPath,
      mask: [page.locator('.navbar__title')], // Mask the title of the navbar
      fullPage: false, // For viewport screenshot, easier to see effect
    });
    console.log(`Masked screenshot saved: ${maskedScreenshotPath}`);
    expect(fs.existsSync(maskedScreenshotPath)).toBeTruthy();

    // Additional assertion to demonstrate test flow
    await expect(page).toHaveTitle(/Screenshots/);
  });

  // To locate and play recorded video, you would typically do this outside the test framework
  // after the test run, using a video player like VLC, or integrate into a CI report.
  // The video path is logged in afterEach, which you can then use.
});
```

## Best Practices
- **Organize Screenshots and Videos**: Create dedicated directories (e.g., `test-results/screenshots`, `test-results/videos`) for storing output to keep your project clean and easily navigable.
- **Meaningful Filenames**: Use descriptive filenames for screenshots and videos, often including test name, timestamp, or an identifier.
- **Conditional Capturing**: Only capture screenshots or record videos on test failures to save disk space and speed up test execution, especially in CI environments. Playwright allows `recordVideo` only on first retry or on failure.
- **`fullPage` judiciously**: Use `fullPage: true` only when necessary, as full-page screenshots can be large and may not always be relevant for a specific failure.
- **Mask Sensitive Data**: Always mask sensitive information (e.g., personal data, credit card numbers) in screenshots and videos to comply with privacy regulations.
- **Review Video Resolution**: Choose an appropriate video resolution (`size` in `recordVideo` options) that balances clarity with file size.

## Common Pitfalls
- **Forgetting to close context/browser**: If `context.close()` or `browser.close()` are not called, video files might not be finalized or saved properly. Playwright's `test.afterEach` handles this automatically if you set up your context/page within the `test` fixture.
- **Large Video Files**: Recording videos for every test, especially long ones, can quickly consume disk space and slow down CI pipelines. Implement strategies to clean up old artifacts.
- **Incorrect Screenshot Paths**: Ensure the `path` option for `screenshot()` is correctly specified and the directory exists, otherwise the command will fail silently or throw an error.
- **Flaky Visuals due to Animations**: If animations are not disabled (`animations: 'disabled'`), screenshots might capture transitional states, leading to flaky visual comparisons.
- **Misunderstanding `fullPage`**: Confusing `fullPage: true` (entire scrollable page) with the default behavior (viewport only) can lead to missing crucial parts of the page in your screenshots.

## Interview Questions & Answers
1.  **Q: How do you use screenshots and video recordings in Playwright for debugging or regression testing?**
    A: Screenshots are used for visual regression testing by comparing current UI against a baseline, or to capture specific states of the application. Video recordings are invaluable for debugging flaky tests or complex interaction flows, as they provide a step-by-step visual replay of the test execution, helping identify unexpected behavior that logs alone might miss.

2.  **Q: What are the key considerations when implementing video recording in Playwright tests for a CI/CD pipeline?**
    A: In CI/CD, key considerations include managing disk space (videos can be large), configuring conditional recording (e.g., only on failure or first retry), ensuring video file cleanup, and integrating video artifacts with reporting tools for easy access and viewing. Also, ensuring the CI environment has necessary codecs and resources for video processing.

3.  **Q: How do you handle sensitive data when taking screenshots in automated tests?**
    A: Playwright offers a `mask` option in its `screenshot()` method. By providing selectors to elements containing sensitive data, Playwright will render these areas as solid pink blocks, preventing the actual content from being captured in the screenshot. This is crucial for privacy and security compliance.

## Hands-on Exercise
1.  **Objective**: Navigate to a complex e-commerce product page (e.g., `https://www.amazon.com/dp/B0B5P2C889`).
2.  **Task 1**: Capture a full-page screenshot of the product page.
3.  **Task 2**: Capture a screenshot of the product title element and the "Add to Cart" button element.
4.  **Task 3**: Modify the `test.beforeEach` to record a video of the entire test execution.
5.  **Task 4**: Introduce a `mask` to hide the price of the product in a screenshot.
6.  **Verification**: After running the test, confirm that the screenshots and video files are generated in the specified directories and that the masked elements are obscured.

## Additional Resources
-   **Playwright Screenshots Documentation**: [https://playwright.dev/docs/screenshots](https://playwright.dev/docs/screenshots)
-   **Playwright Videos Documentation**: [https://playwright.dev/docs/videos](https://playwright.dev/docs/videos)
-   **Playwright Test Configuration (Video Options)**: [https://playwright.dev/docs/test-configuration#videos](https://playwright.dev/docs/test-configuration#videos)