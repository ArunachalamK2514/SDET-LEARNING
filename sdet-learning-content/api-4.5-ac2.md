# Validate and Download Files from API Responses

## Overview
In modern test automation, validating API responses goes beyond just checking JSON or XML payloads. Many APIs, especially in enterprise or financial systems, return files such as PDFs, CSVs, images, or even zipped archives. As SDETs, we need robust methods to call these endpoints, download the files, and then perform validations on their content, size, or metadata. This capability is crucial for ensuring data integrity, proper reporting, and correct file generation within a system. This section will guide you through handling file downloads using REST Assured, validating their properties, and integrating this into your automation framework.

## Detailed Explanation
When an API endpoint serves a file, the response typically contains specific headers like `Content-Disposition` (indicating it's an attachment and suggesting a filename) and `Content-Type` (specifying the MIME type of the file, e.g., `application/pdf`, `text/csv`). The actual file content is present in the response body as raw bytes.

REST Assured provides convenient ways to extract this raw byte stream, which can then be written to a local file. The general flow is:
1.  Make an API call to the file download endpoint.
2.  Extract the response body as a `byte[]` array or an `InputStream`.
3.  Use Java's I/O utilities (e.g., `FileOutputStream`) to write these bytes to a file on the local file system.
4.  Perform validations:
    *   **File Existence and Size:** Check if the file was created and its size.
    *   **Content Type:** Verify the `Content-Type` header.
    *   **Checksum/Hash:** For critical files, calculate a hash (MD5, SHA-256) of the downloaded file and compare it against a known expected hash (if available from the API or specification).
    *   **File Content (e.g., PDF, CSV):** For structured files like CSVs or PDFs, parse their content to validate specific data points. Libraries like Apache POI (for Excel), OpenCSV (for CSV), or PDFBox (for PDF) can be used.

## Code Implementation
Here's a complete example using REST Assured and Java I/O to download a CSV file and perform basic validation.

```java
import io.restassured.response.Response;
import org.testng.Assert;
import org.testng.annotations.Test;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID; // For generating unique filenames

import static io.restassured.RestAssured.given;

public class FileDownloadValidationTest {

    // Assuming a base URI for your API
    private final String BASE_URI = "http://localhost:8080"; // Replace with your actual API base URI

    /**
     * Helper method to download a file from an API response.
     * @param response The REST Assured Response object.
     * @param fileName The desired name for the downloaded file.
     * @return The File object representing the downloaded file.
     * @throws IOException if an I/O error occurs during file writing.
     */
    private File downloadFile(Response response, String fileName) throws IOException {
        // Ensure the downloads directory exists
        Path downloadDirPath = Paths.get("target/downloads");
        if (!Files.exists(downloadDirPath)) {
            Files.createDirectories(downloadDirPath);
        }

        File downloadedFile = new File(downloadDirPath.toFile(), fileName);

        try (InputStream is = response.asInputStream();
             FileOutputStream fos = new FileOutputStream(downloadedFile)) {
            byte[] buffer = new byte[4096]; // Buffer size
            int bytesRead;
            while ((bytesRead = is.read(buffer)) != -1) {
                fos.write(buffer, 0, bytesRead);
            }
        }
        System.out.println("File downloaded to: " + downloadedFile.getAbsolutePath());
        return downloadedFile;
    }

    @Test(description = "Verify successful download and basic properties of a CSV file")
    public void testDownloadCsvFileAndValidate() throws IOException {
        String uniqueFileName = "report_" + UUID.randomUUID().toString() + ".csv";

        // 1. Call endpoint returning a file (CSV)
        Response response = given()
                .baseUri(BASE_URI)
                .when()
                .get("/api/v1/reports/csv") // Replace with your actual CSV download endpoint
                .then()
                .statusCode(200)
                .extract()
                .response();

        // Validate Content-Type header
        String contentType = response.getHeader("Content-Type");
        System.out.println("Response Content-Type: " + contentType);
        Assert.assertEquals(contentType, "text/csv;charset=UTF-8", "Expected Content-Type for CSV file");

        // Validate Content-Disposition header (optional, but good for suggested filename)
        String contentDisposition = response.getHeader("Content-Disposition");
        System.out.println("Response Content-Disposition: " + contentDisposition);
        Assert.assertTrue(contentDisposition.contains("attachment; filename="), "Content-Disposition header missing or incorrect");
        Assert.assertTrue(contentDisposition.contains(".csv"), "Content-Disposition header should suggest a CSV filename");


        // 2. Extract response as InputStream and 3. Write content to a local file
        File downloadedCsv = downloadFile(response, uniqueFileName);

        // 4. Verify size/content
        Assert.assertTrue(downloadedCsv.exists(), "Downloaded CSV file should exist");
        Assert.assertTrue(downloadedCsv.length() > 0, "Downloaded CSV file should not be empty");

        // Example of more detailed CSV content validation (requires a CSV parsing library like OpenCSV)
        // For demonstration, we'll just read the first few lines
        String fileContent = Files.readString(downloadedCsv.toPath());
        System.out.println("First 100 characters of CSV content:
" + fileContent.substring(0, Math.min(fileContent.length(), 100)));
        Assert.assertTrue(fileContent.contains("header1,header2,header3"), "CSV content should contain expected headers");
        Assert.assertTrue(fileContent.contains("data1,data2,data3"), "CSV content should contain expected data");

        // Clean up: delete the downloaded file after verification
        Files.deleteIfExists(downloadedCsv.toPath());
    }

    @Test(description = "Verify successful download and basic properties of a PDF file")
    public void testDownloadPdfFileAndValidate() throws IOException {
        String uniqueFileName = "document_" + UUID.randomUUID().toString() + ".pdf";

        Response response = given()
                .baseUri(BASE_URI)
                .when()
                .get("/api/v1/documents/pdf") // Replace with your actual PDF download endpoint
                .then()
                .statusCode(200)
                .extract()
                .response();

        // Validate Content-Type header
        String contentType = response.getHeader("Content-Type");
        System.out.println("Response Content-Type: " + contentType);
        Assert.assertEquals(contentType, "application/pdf", "Expected Content-Type for PDF file");

        File downloadedPdf = downloadFile(response, uniqueFileName);

        Assert.assertTrue(downloadedPdf.exists(), "Downloaded PDF file should exist");
        Assert.assertTrue(downloadedPdf.length() > 100, "Downloaded PDF file should not be too small (assuming it's a real PDF)");

        // For actual PDF content validation, you'd use a library like Apache PDFBox.
        // Example: verify text presence in PDF
        // PDDocument document = PDDocument.load(downloadedPdf);
        // PDFTextStripper pdfStripper = new PDFTextStripper = new PDFTextStripper();
        // String pdfText = pdfStripper.getText(document);
        // Assert.assertTrue(pdfText.contains("Expected text in PDF"), "PDF should contain specific text");
        // document.close();

        Files.deleteIfExists(downloadedPdf.toPath());
    }
}
```

**To make the above code runnable, you would need:**
*   **Maven/Gradle dependencies:**
    *   `io.rest-assured:rest-assured:5.x.x`
    *   `org.testng:testng:7.x.x`
    *   (Optional, for detailed file content parsing) `com.opencsv:opencsv:5.x.x` for CSV
    *   (Optional, for detailed file content parsing) `org.apache.pdfbox:pdfbox:2.x.x` for PDF

*   **A mock API or actual API endpoints** that serve files. For local testing, you can quickly set up a simple Spring Boot or Node.js Express server to serve static files.

    **Example (Node.js Express - `server.js`):**
    ```javascript
    const express = require('express');
    const path = require('path');
    const app = express();
    const port = 8080;

    app.get('/api/v1/reports/csv', (req, res) => {
        res.setHeader('Content-Type', 'text/csv;charset=UTF-8');
        res.setHeader('Content-Disposition', 'attachment; filename="sample_report.csv"');
        res.send("header1,header2,header3
data1,data2,data3
value1,value2,value3");
    });

    app.get('/api/v1/documents/pdf', (req, res) => {
        // In a real scenario, you'd serve an actual PDF file.
        // For demonstration, we'll send a very basic, valid (but empty-looking) PDF structure.
        // A proper PDF would be loaded from a file or generated.
        const pdfPath = path.join(__dirname, 'sample.pdf'); // You would need a sample.pdf here
        // For a quick test, let's create a dummy small PDF binary content
        const dummyPdfContent = Buffer.from(
            "%PDF-1.4
" +
            "1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
" +
            "2 0 obj<</Type/Pages/Count 0>>endobj
" +
            "xref
" +
            "0 3
" +
            "0000000000 65535 f
" +
            "0000000009 00000 n
" +
            "0000000052 00000 n
" +
            "trailer<</Size 3/Root 1 0 R>>startxref
" +
            "106
" +
            "%%EOF",
            'latin1' // Important for binary data
        );
        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', 'attachment; filename="sample_document.pdf"');
        res.send(dummyPdfContent);
    });

    app.listen(port, () => {
        console.log(`Mock file server listening at http://localhost:${port}`);
    });
    ```
    To run the Node.js mock server:
    1.  Install Node.js.
    2.  Create `package.json` in the same directory as `server.js`:
        ```json
        {
          "name": "mock-api-server",
          "version": "1.0.0",
          "description": "A simple mock API server for file downloads",
          "main": "server.js",
          "scripts": {
            "start": "node server.js"
          },
          "dependencies": {
            "express": "^4.17.1"
          }
        }
        ```
    3.  Run `npm install`
    4.  Run `npm start`

## Best Practices
-   **Isolate Downloads:** Always download files to a dedicated, temporary directory within your project (e.g., `target/downloads` or a uniquely named folder per test run) to avoid cluttering your system and to make cleanup easy.
-   **Unique Filenames:** Use `UUID.randomUUID()` or similar methods to generate unique filenames for each download to prevent naming conflicts, especially in parallel test execution.
-   **Thorough Header Validation:** Always validate `Content-Type` and `Content-Disposition` headers. These provide critical metadata about the file being served.
-   **Post-Download Cleanup:** Ensure downloaded files are deleted after the test completes (e.g., in `@AfterMethod` or a dedicated cleanup step) to maintain a clean test environment.
-   **Checksum Validation:** For sensitive data or binary files, compare MD5/SHA-256 hashes of the downloaded file with expected values. This is the most reliable way to ensure file integrity.
-   **Content-Specific Parsing:** Don't just check file size. Use appropriate libraries (PDFBox, Apache POI, OpenCSV, ImageIO) to parse and validate the *actual content* of the downloaded files.
-   **Error Handling:** Handle cases where the API returns an error instead of a file (e.g., 404, 500) or if the downloaded file is corrupted/incomplete.

## Common Pitfalls
-   **Assuming Content is Always a File:** Not all endpoints return files. Some might return JSON with a file *link*. Differentiate between direct file downloads and API responses that provide URLs to files.
-   **Memory Issues with Large Files:** Reading entire large files into a `byte[]` in memory (using `response.asByteArray()`) can lead to `OutOfMemoryError`. Using `response.asInputStream()` and writing directly to a `FileOutputStream` is more memory-efficient.
-   **Charset Issues:** When dealing with text-based files (CSV, XML), be mindful of the character encoding (`charset`). If not handled correctly, text might appear garbled. REST Assured often handles this, but verify the `Content-Type` header for `charset` information.
-   **Permissions:** Ensure your test runner has write permissions to the directory where files are being downloaded.
-   **No Cleanup:** Forgetting to delete downloaded files can consume disk space and lead to "dirty" test runs, potentially affecting subsequent tests.

## Interview Questions & Answers
1.  **Q: How do you handle file downloads from an API in your automation framework?**
    **A:** I typically use REST Assured. After making the API call, I extract the response body as an `InputStream` or `byte[]`. Then, I use Java's `FileOutputStream` to write these bytes to a local file in a designated temporary download directory. Post-download, I perform validations on the file's existence, size, and crucially, its content by parsing it with relevant libraries like OpenCSV for CSVs or Apache PDFBox for PDFs. I also validate `Content-Type` and `Content-Disposition` headers.

2.  **Q: What specific validations would you perform on a downloaded file?**
    **A:** Beyond verifying the HTTP status code (200 OK), I'd validate:
    *   **Headers:** `Content-Type` (e.g., `application/pdf`, `text/csv`) and `Content-Disposition` (to confirm it's an attachment and get the suggested filename).
    *   **File System:** Check if the file exists on disk and its size (`file.length()`).
    *   **Content Integrity:** For critical files, calculate and compare a hash (MD5/SHA-256) of the downloaded file.
    *   **Data Content:** Parse the file (e.g., using OpenCSV for CSV, PDFBox for PDF) to assert specific data points, record counts, or structural correctness within the file itself.

3.  **Q: What are the challenges when dealing with large file downloads, and how do you mitigate them?**
    **A:** The primary challenge is memory consumption. If you try to load an extremely large file entirely into memory using `response.asByteArray()`, it can lead to `OutOfMemoryError`. To mitigate this, I prefer using `response.asInputStream()` and streaming the content directly to a `FileOutputStream`. This writes the file bytes to disk chunk by chunk, minimizing the memory footprint. Another consideration is network timeout for very large files, which might require adjusting client timeout settings.

4.  **Q: How do you ensure the downloaded files don't interfere with subsequent test runs or clutter the test environment?**
    **A:** I implement a robust cleanup strategy. Files are downloaded to a unique, temporary subdirectory (e.g., `target/downloads/{test_run_id}`). After the test method or test class completes (using TestNG's `@AfterMethod` or `@AfterClass`), I ensure all downloaded files and their containing directory are deleted. Generating unique filenames using `UUID` for each download also prevents conflicts during parallel execution.

## Hands-on Exercise
**Scenario:** Imagine an e-commerce API that provides an invoice for a completed order as a PDF and an order summary as a CSV.

1.  **Set up a Mock Server:** If you don't have a real API, use the provided Node.js Express example (or a similar tool/framework) to create two endpoints:
    *   `/api/v1/orders/{orderId}/invoice` (returns a PDF)
    *   `/api/v1/orders/{orderId}/summary` (returns a CSV)
    Ensure these endpoints return appropriate `Content-Type` and `Content-Disposition` headers. For the PDF, you can return a very basic PDF content as shown in the Node.js example. For the CSV, return a few lines of sample order data.

2.  **Implement Test Methods:**
    *   Write a TestNG test method (`testDownloadOrderInvoicePdf`) that calls the PDF endpoint for a given `orderId`.
    *   Inside the test, download the PDF to a `target/downloads` directory.
    *   Validate the `Content-Type` header is `application/pdf`.
    *   Assert that the downloaded file exists and has a reasonable size (e.g., `> 100` bytes).
    *   (Bonus) If you integrate PDFBox, try to extract some text and assert its presence (e.g., "Invoice for Order {orderId}").
    *   Write another TestNG test method (`testDownloadOrderSummaryCsv`) for the CSV endpoint.
    *   Download the CSV file.
    *   Validate the `Content-Type` header is `text/csv`.
    *   Assert file existence and size.
    *   (Bonus) Read the CSV content and assert that it contains expected headers and at least one data row for the given `orderId`.

3.  **Clean Up:** Ensure both test methods clean up their respective downloaded files.

## Additional Resources
-   **REST Assured Official Documentation:** [https://rest-assured.io/](https://rest-assured.io/) - Refer to the "Response" section for extracting different body types.
-   **Apache PDFBox:** [https://pdfbox.apache.org/](https://pdfbox.apache.org/) - A powerful Java library for PDF manipulation and text extraction.
-   **OpenCSV:** [http://opencsv.sourceforge.net/](http://opencsv.sourceforge.net/) - A simple CSV parser library for Java.
-   **Java NIO.2 (Files & Paths):** [https://docs.oracle.com/javase/tutorial/essential/io/fileio.html](https://docs.oracle.com/javase/tutorial/essential/io/fileio.html) - For modern file system operations in Java.