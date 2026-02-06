# Playwright: Handling File Downloads and Verification

## Overview
Automated testing of file download functionality is a crucial aspect of ensuring a robust user experience and data integrity. Users often rely on web applications to download reports, documents, images, or other files. As SDETs, we must ensure that these download processes work as expected, the correct files are downloaded, and their content is valid. Playwright provides powerful and intuitive APIs to effectively handle file downloads, allowing us to simulate user interactions and verify the outcomes seamlessly.

This section will cover how to listen for download events, trigger download actions, save downloaded files to a specified location, and perform essential verifications on the downloaded content.

## Detailed Explanation

Playwright simplifies the process of testing file downloads by providing an event-driven mechanism. When a user action triggers a download, Playwright emits a `download` event on the `page` object. We can listen for this event, retrieve the `Download` object, and then interact with the downloaded file.

Here's a breakdown of the key steps and concepts:

1.  **Setting up a Download Listener (`page.waitForEvent('download')`)**:
    Before performing the action that triggers the download (e.g., clicking a download link), you must set up an event listener to capture the `download` event. This is typically done using `page.waitForEvent('download')`. This method waits for the event to be emitted and returns a `Download` object when it occurs.

    ```typescript
    const [download] = await Promise.all([
      page.waitForEvent('download'), // Setup download listener
      page.click('a#download-link') // Action that triggers download
    ]);
    ```
    It's crucial to wrap the event listener and the trigger action in `Promise.all` to avoid race conditions. The event listener must be active *before* the download action is initiated.

2.  **Triggering the Download Action**:
    This involves simulating the user interaction that causes a file download. Common actions include:
    *   Clicking an `<a>` tag with a `download` attribute or a direct link to a file.
    *   Clicking a button that initiates a server-side file generation and download.
    *   Submitting a form that leads to a file download.

3.  **Saving the Download to a Specific Path (`download.saveAs(path)`)**:
    By default, Playwright downloads files to a temporary directory. This temporary location is available via `download.path()`. However, for verification, it's often more convenient and reliable to save the file to a known, accessible location on your local file system. The `download.saveAs(path)` method allows you to specify the destination path.

    ```typescript
    import * as fs from 'fs';
    import * as path from 'path';

    // ... inside your test
    const downloadsPath = path.join(__dirname, 'downloads');
    fs.mkdirSync(downloadsPath, { recursive: true }); // Ensure directory exists

    const filePath = path.join(downloadsPath, download.suggestedFilename());
    await download.saveAs(filePath);
    ```
    `download.suggestedFilename()` is useful as it provides the filename suggested by the browser, which often matches the original filename.

4.  **Verifying File Existence and Name**:
    After saving the file, you'll want to verify that it exists at the expected location and has the correct name. Node.js's built-in `fs` module is perfect for this.

    ```typescript
    import * as fs from 'fs';
    // ...
    expect(fs.existsSync(filePath)).toBeTruthy();
    expect(path.basename(filePath)).toBe('my_downloaded_file.pdf');
    ```

5.  **Additional Verifications (Size, Content, Type)**:
    Depending on the criticality of the download, you might need to perform more in-depth checks:
    *   **File Size**: `fs.statSync(filePath).size` can give you the file size in bytes.
    *   **File Content**: For text-based files (e.g., `.txt`, `.csv`, `.json`), you can read their content using `fs.readFileSync(filePath, 'utf-8')` and assert against expected content. For binary files, you might compare hashes or use specific libraries.
    *   **MIME Type**: While Playwright's `download.page()._actualMimeType()` or similar might give an indication, it's often more reliable to infer from the file extension or, for complex scenarios, use third-party libraries that analyze file headers.

## Code Implementation

This example demonstrates how to download a file from a hypothetical web page, save it, and perform basic verifications.

```typescript
import { test, expect, Page } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

// Define a temporary directory for downloads
const downloadsDir = path.join(__dirname, 'temp_downloads');

test.beforeAll(async () => {
  // Ensure the downloads directory exists before tests run
  fs.mkdirSync(downloadsDir, { recursive: true });
});

test.afterAll(async () => {
  // Clean up the downloads directory after all tests are done
  fs.rmSync(downloadsDir, { recursive: true, force: true });
});

test.describe('File Download Scenarios', () => {

  test('should download a text file and verify its content', async ({ page }) => {
    await page.goto('https://www.example.com/downloads'); // Replace with a real URL that offers downloads

    // Mock a download for demonstration purposes if a real one isn't available
    // In a real scenario, you'd click a link or button
    // For this example, let's assume 'https://www.example.com/downloads' has a link
    // <a id="downloadText" href="/path/to/sample.txt" download>Download Text File</a>

    // Setup an interception for the download URL to provide a mock response for testing
    // This is good for isolated unit tests, but for E2E, you'd let the real download happen.
    // For a real E2E test, ensure your page.goto() leads to a page where a download link exists.
    
    // Simulate a page with a download link (replace with your actual page logic)
    await page.setContent(`
      <a id="downloadLink" href="/files/sample.txt" download="sample_download.txt">Download Sample Text</a>
      <script>
        // Simulate a server providing the file content
        document.querySelector('#downloadLink').addEventListener('click', async (e) => {
          e.preventDefault();
          const content = "This is a sample text file content.";
          const blob = new Blob([content], { type: 'text/plain' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = 'sample_download.txt';
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        });
      </script>
    `);


    // CRITICAL: Set up the download listener *before* triggering the download action
    const [download] = await Promise.all([
      page.waitForEvent('download'), // Wait for the download event
      page.click('#downloadLink')    // Click the element that initiates the download
    ]);

    // Verify download properties before saving
    expect(download.url()).toContain('/files/sample.txt'); // Or specific mock URL
    expect(download.suggestedFilename()).toBe('sample_download.txt');
    
    // Construct the full path where the file will be saved
    const filePath = path.join(downloadsDir, download.suggestedFilename());

    // Save the downloaded file to our designated temporary directory
    await download.saveAs(filePath);

    // Assert that the file exists and its content is as expected
    expect(fs.existsSync(filePath)).toBeTruthy();
    expect(fs.readFileSync(filePath, 'utf-8')).toBe('This is a sample text file content.');

    console.log(`Downloaded file: ${filePath}`);
  });

  test('should handle multiple downloads sequentially', async ({ page }) => {
    await page.goto('https://www.example.com/multi-downloads'); // Replace with a real URL

    await page.setContent(`
      <a id="downloadLink1" href="/files/file1.pdf" download="document_one.pdf">Download Document 1</a>
      <a id="downloadLink2" href="/files/file2.zip" download="archive_two.zip">Download Archive 2</a>
      <script>
        // Simulate server response for file1.pdf
        document.querySelector('#downloadLink1').addEventListener('click', async (e) => {
          e.preventDefault();
          const content = "PDF Content One";
          const blob = new Blob([content], { type: 'application/pdf' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = 'document_one.pdf';
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        });

        // Simulate server response for file2.zip
        document.querySelector('#downloadLink2').addEventListener('click', async (e) => {
          e.preventDefault();
          const content = "ZIP Content Two";
          const blob = new Blob([content], { type: 'application/zip' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = 'archive_two.zip';
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
        });
      </script>
    `);


    // Download 1
    const [download1] = await Promise.all([
      page.waitForEvent('download'),
      page.click('#downloadLink1')
    ]);
    const filePath1 = path.join(downloadsDir, download1.suggestedFilename());
    await download1.saveAs(filePath1);
    expect(fs.existsSync(filePath1)).toBeTruthy();
    expect(path.basename(filePath1)).toBe('document_one.pdf');
    expect(fs.readFileSync(filePath1, 'utf-8')).toBe('PDF Content One');
    console.log(`Downloaded file 1: ${filePath1}`);

    // Download 2
    const [download2] = await Promise.all([
      page.waitForEvent('download'),
      page.click('#downloadLink2')
    ]);
    const filePath2 = path.join(downloadsDir, download2.suggestedFilename());
    await download2.saveAs(filePath2);
    expect(fs.existsSync(filePath2)).toBeTruthy();
    expect(path.basename(filePath2)).toBe('archive_two.zip');
    expect(fs.readFileSync(filePath2, 'utf-8')).toBe('ZIP Content Two');
    console.log(`Downloaded file 2: ${filePath2}`);
  });
});
```

## Best Practices
-   **Use Temporary Directories**: Always save downloaded files to a temporary, isolated directory (e.g., `temp_downloads` within your project or system temp directory) and clean it up after tests. This prevents test interference and keeps your file system tidy.
-   **Atomic Actions**: Combine `page.waitForEvent('download')` with the action triggering the download using `Promise.all` to prevent race conditions and ensure the listener is active before the download starts.
-   **Verify File Properties**: Beyond just existence, verify the filename, size (`download.size()`), and potentially the MIME type (`download.page()._actualMimeType()` or by reading file headers if critical).
-   **Content Verification**: For critical files, read and assert the content (e.g., for CSV, JSON, or text files). For binary files, consider checking file integrity via hash comparison if the expected hash is known.
-   **Handle Timeouts**: Downloads can sometimes be slow. Playwright's `waitForEvent` has a default timeout, but you might need to adjust it for very large files using the `timeout` option.
-   **Error Handling**: Consider scenarios where a download might fail (e.g., server error, file not found). Your tests should ideally cover these negative cases.

## Common Pitfalls
-   **Race Conditions**: Not setting up `page.waitForEvent('download')` *before* the action that triggers the download. This leads to the event being missed by the listener. Always use `Promise.all`.
-   **Permissions Issues**: The user running the test might not have write permissions to the directory specified in `saveAs()`, leading to test failures. Ensure the target directory is writable.
-   **Assuming Immediate Completion**: Downloads, especially large ones, take time. `download.saveAs()` is an async operation that waits for the download to complete before saving. However, always ensure your subsequent assertions properly await this.
-   **Incorrect File Path/Name**: Mismatches between `download.suggestedFilename()` and the actual file saved, or issues with path concatenation, can lead to `file not found` errors during verification.
-   **Cleanup Failure**: Not cleaning up temporary download directories can clutter your system over time and might cause unexpected behavior in subsequent test runs.

## Interview Questions & Answers

1.  **Q: How do you handle file downloads in Playwright, and what are the key steps involved?**
    **A:** In Playwright, file downloads are handled using the `page.waitForEvent('download')` method. The key steps are:
    1.  **Set up a listener**: Use `page.waitForEvent('download')` *before* initiating the download action.
    2.  **Trigger the download**: Perform the action (e.g., `page.click()`) that causes the file to download. It's crucial to wrap the listener and trigger in `Promise.all` to prevent race conditions.
    3.  **Get the Download object**: The listener returns a `Download` object, which provides access to download metadata.
    4.  **Save the file**: Use `download.saveAs(filePath)` to save the file to a specific location. By default, Playwright downloads to a temporary directory.
    5.  **Verify the file**: Use Node.js `fs` module to check for file existence, name, size, and content.
    6.  **Cleanup**: Remove the downloaded file and any temporary directories after the test.

2.  **Q: What are some common challenges or considerations when testing file downloads in an automated framework like Playwright?**
    **A:**
    *   **Race Conditions**: Ensuring the download listener is active *before* the download trigger occurs. `Promise.all` is the solution.
    *   **Download Timeouts**: Large files or slow network conditions can cause downloads to exceed default timeouts. Adjusting `waitForEvent` timeout is necessary.
    *   **Temporary File Handling**: Managing temporary directories and ensuring proper cleanup after tests to maintain a clean environment.
    *   **Content Verification**: For complex or dynamic files, verifying the actual content can be challenging, often requiring parsing libraries or robust comparison logic (e.g., comparing hashes for binary files).
    *   **Browser Prompts**: Some downloads might trigger browser prompts (e.g., "Do you want to save this file?"). Playwright handles most standard download flows automatically, but complex prompts might require specific handling or browser options to bypass.
    *   **Server-Side Generation**: Downloads often involve server-side file generation, which can introduce latency and requires robust waiting mechanisms.

3.  **Q: How would you verify the content of a downloaded CSV file in Playwright?**
    **A:** To verify the content of a downloaded CSV file:
    1.  First, ensure the file is downloaded and saved to a known path using `page.waitForEvent('download')` and `download.saveAs(filePath)`.
    2.  Then, use Node.js's `fs.readFileSync(filePath, 'utf-8')` to read the entire content of the CSV file as a string.
    3.  You can then parse this string using a CSV parsing library (e.g., `csv-parse` for Node.js) to convert it into an array of objects or arrays.
    4.  Finally, assert that the parsed data matches your expected data structure and values. This might involve checking row counts, specific cell values, or comparing the entire parsed object against a predefined expected object.

## Hands-on Exercise

**Scenario**: You need to test a web application that allows users to export a list of products as a CSV file.

**Task**:
1.  Navigate to a mock product listing page (you can create a simple `index.html` locally or use a public test site if available).
2.  Locate and click the "Export to CSV" button/link.
3.  Wait for the CSV file to download.
4.  Save the downloaded file to a `temp_downloads` directory within your project.
5.  Verify the following:
    *   The file `products.csv` exists in the `temp_downloads` directory.
    *   The file's suggested filename is `products.csv`.
    *   The content of the CSV file contains a specific header (e.g., "Product Name,Price,Quantity").
    *   The content contains at least two product entries.
6.  Clean up the `temp_downloads` directory after the test.

**Hint**: For the mock page, you can use `page.setContent()` to create a simple HTML structure with an export link that simulates a download by creating a Blob and triggering a click.

## Additional Resources
-   **Playwright Downloads Documentation**: [https://playwright.dev/docs/downloads](https://playwright.dev/docs/downloads)
-   **Node.js File System Module (fs)**: [https://nodejs.org/docs/latest/api/fs.html](https://nodejs.org/docs/latest/api/fs.html)
-   **Playwright Test Runner Documentation**: [https://playwright.dev/docs/test-intro](https://playwright.dev/docs/test-intro)