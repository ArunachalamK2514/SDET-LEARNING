# api-4.5-ac1.md

# multipart/form-data File Upload using multiPart() in REST Assured

## Overview
File uploads are a common requirement in many API interactions, especially when dealing with content like images, documents, or other binary data. `multipart/form-data` is the standard encoding type for these scenarios. REST Assured provides a straightforward way to handle such uploads using its `multiPart()` method, simplifying what can often be a complex task in API testing. This section will guide you through implementing file uploads, ensuring your tests accurately simulate real-world user interactions.

## Detailed Explanation
When you submit a form that contains a file input field in a web application, the browser typically sends the data with the `Content-Type` header set to `multipart/form-data`. Each part of the form (e.g., text fields, file fields) is sent as a separate "part" within the request body, delimited by a boundary string.

REST Assured's `multiPart()` method abstracts away the complexities of constructing such a request. You can provide a file directly, and REST Assured will handle the conversion into the appropriate `multipart/form-data` format, including setting the correct headers and body structure.

The primary overload for `multiPart()` used for file uploads is `multiPart(String controlName, File file)`, where:
- `controlName`: This is the name of the file input field in the HTML form. It's crucial to match this name with what the server expects.
- `file`: A `java.io.File` object representing the file you want to upload.

REST Assured also allows for specifying the `mimeType` and `fileName` if they differ from the default inferred values. For example:
- `multiPart(String controlName, File file, String mimeType)`
- `multiPart(String controlName, String fileName, InputStream inputStream, String mimeType)` (for uploading from an InputStream)

### How multipart/form-data works:
A `multipart/form-data` request body is structured as follows:

```
Content-Type: multipart/form-data; boundary=--------------------------949169871587524956108151

----------------------------949169871587524956108151
Content-Disposition: form-data; name="text_field"

Some text value
----------------------------949169871587524956108151
Content-Disposition: form-data; name="file"; filename="my_document.txt"
Content-Type: text/plain

[Content of my_document.txt]
----------------------------949169871587524956108151--
```
REST Assured handles the generation of these boundaries and headers automatically.

## Code Implementation

Let's assume we have a sample file named `test_upload.txt` with the content "This is a test file for upload." and an API endpoint that accepts file uploads.

**1. Create a sample file to upload:**

```java
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

public class FileCreator {

    public static File createSampleFile(String fileName, String content) throws IOException {
        File file = new File(fileName);
        try (FileWriter writer = new FileWriter(file)) {
            writer.write(content);
        }
        System.out.println("Created sample file: " + file.getAbsolutePath());
        return file;
    }

    public static void main(String[] args) throws IOException {
        createSampleFile("test_upload.txt", "This is a test file for upload via REST Assured.");
    }
}
```

**2. REST Assured test for file upload:**

We will use a mock server for this example. You would replace this with your actual API endpoint.

```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class FileUploadTest {

    private static final String BASE_URI = "http://localhost:8080"; // Replace with your API base URI
    private static File sampleFile;

    @BeforeAll
    static void setup() throws IOException {
        // Create a temporary sample file for upload
        sampleFile = createSampleFile("temp_upload.txt", "This content is for testing file upload.");
        RestAssured.baseURI = BASE_URI;

        // Note: For a real application, you'd start your mock server or ensure your application is running
        // For demonstration purposes, we assume a mock server is running at BASE_URI/upload
        System.out.println("Setup completed. Sample file created: " + sampleFile.getAbsolutePath());
    }

    @Test
    void testFileUploadWithMultiPart() {
        System.out.println("Starting file upload test for: " + sampleFile.getName());

        // This assumes your server expects a file part named "file"
        Response response = given()
                .multiPart("file", sampleFile) // Key part: Use multiPart() to attach the file
            .when()
                .post("/upload") // Replace with your actual upload endpoint
            .then()
                .log().all() // Log all request and response details for debugging
                .statusCode(200)
                .body("message", equalTo("File uploaded successfully!"))
                .body("fileName", equalTo(sampleFile.getName()))
                .extract().response();

        System.out.println("File upload test finished. Response: " + response.asString());
    }

    @Test
    void testFileUploadWithCustomMimeType() throws IOException {
        File jsonFile = createSampleFile("data.json", "{ "name": "test", "value": 123 }");
        System.out.println("Starting file upload test for: " + jsonFile.getName() + " with custom MIME type.");

        Response response = given()
                .multiPart("data", jsonFile, "application/json") // Specify MIME type
            .when()
                .post("/upload-json") // Assuming a different endpoint for JSON file upload
            .then()
                .log().all()
                .statusCode(200)
                .body("message", equalTo("JSON file uploaded successfully!"))
                .body("fileName", equalTo(jsonFile.getName()))
                .extract().response();

        System.out.println("JSON file upload test finished. Response: " + response.asString());
        // Clean up the created JSON file
        Files.deleteIfExists(jsonFile.toPath());
        assertTrue(!jsonFile.exists(), "Custom MIME type file should be deleted.");
    }


    private static File createSampleFile(String fileName, String content) throws IOException {
        File file = new File(fileName);
        try (FileWriter writer = new FileWriter(file)) {
            writer.write(content);
        }
        return file;
    }

    @AfterAll
    static void tearDown() throws IOException {
        // Clean up the created sample file after all tests
        if (sampleFile != null && sampleFile.exists()) {
            Files.deleteIfExists(sampleFile.toPath());
            System.out.println("Cleaned up sample file: " + sampleFile.getAbsolutePath());
        }
    }
}
```

**To run the `FileUploadTest` example, you would need to set up a simple mock server.** Here's a basic example using `Spark` (a micro-framework for Java) that you can run separately:

**`MockFileUploadServer.java`**
```java
import static spark.Spark.*;

public class MockFileUploadServer {
    public static void main(String[] args) {
        port(8080); // Set the port for the server

        post("/upload", (req, res) -> {
            req.attribute("org.eclipse.jetty.multipartConfig", new org.eclipse.jetty.server.MultiPartConfigElement("/tmp"));
            try {
                // Get the uploaded file
                String fileName = req.raw().getPart("file").getSubmittedFileName();
                long fileSize = req.raw().getPart("file").getSize();
                // In a real scenario, you would save the file content.
                // For this mock, we just confirm receipt.
                System.out.println("Received file upload: " + fileName + " (" + fileSize + " bytes)");

                res.status(200);
                res.type("application/json");
                return "{"message":"File uploaded successfully!", "fileName":"" + fileName + "", "size":" + fileSize + "}";
            } catch (Exception e) {
                e.printStackTrace();
                res.status(500);
                return "{"error":"File upload failed: " + e.getMessage() + ""}";
            }
        });

        post("/upload-json", (req, res) -> {
            req.attribute("org.eclipse.jetty.multipartConfig", new org.eclipse.jetty.server.MultiPartConfigElement("/tmp"));
            try {
                // Get the uploaded JSON file
                String fileName = req.raw().getPart("data").getSubmittedFileName();
                String contentType = req.raw().getPart("data").getContentType();
                long fileSize = req.raw().getPart("data").getSize();

                // Validate content type for JSON
                if (!"application/json".equals(contentType)) {
                    res.status(400);
                    return "{"error":"Invalid content type for JSON file. Expected application/json."}";
                }

                System.out.println("Received JSON file upload: " + fileName + " (" + fileSize + " bytes) with type: " + contentType);

                res.status(200);
                res.type("application/json");
                return "{"message":"JSON file uploaded successfully!", "fileName":"" + fileName + "", "size":" + fileSize + ""}";
            } catch (Exception e) {
                e.printStackTrace();
                res.status(500);
                return "{"error":"JSON file upload failed: " + e.getMessage() + ""}";
            }
        });

        System.out.println("Mock File Upload Server started on port 8080. Endpoints: /upload, /upload-json");
    }
}
```
**Dependencies for Spark Mock Server (in `pom.xml` if using Maven):**
```xml
<dependency>
    <groupId>com.sparkjava</groupId>
    <artifactId>spark-core</artifactId>
    <version>2.9.3</version>
</dependency>
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-simple</artifactId>
    <version>1.7.32</version>
</dependency>
```

## Best Practices
- **Use meaningful control names:** Ensure the `controlName` passed to `multiPart()` exactly matches the name attribute of the file input field on the server-side. Mismatches are a common cause of failure.
- **Clean up temporary files:** If you create temporary files for testing, ensure they are deleted after the tests complete (e.g., in `@AfterAll` or `@AfterEach` methods).
- **Verify server-side processing:** Your assertions should not only check the HTTP status code but also verify that the server processed the file correctly (e.g., check a message in the response body, or if possible, verify the file's presence or content on a storage system).
- **Test various file types and sizes:** Don't limit your tests to just one type or size of file. Test with small, large, different extensions (e.g., `.txt`, `.jpg`, `.pdf`), and even corrupted files if applicable to your application's error handling.
- **Handle authentication:** If your upload endpoint is secured, ensure you include necessary authentication headers (e.g., `given().auth().oauth2("token").multiPart(...)`).

## Common Pitfalls
- **Incorrect `controlName`:** The most frequent issue. Double-check the server-side expectation for the name of the file parameter.
- **Missing server-side configuration for multipart:** If the server-side framework isn't configured to handle `multipart/form-data` requests, file uploads will fail silently or with generic errors.
- **File not found:** Ensure the path to `new File("path")` is correct and the file exists at the time of test execution. Use absolute paths or paths relative to the test execution directory if needed.
- **Memory issues with large files:** Uploading very large files in tests can consume significant memory. For integration tests, consider using smaller representative files. For performance testing of large files, dedicated tools might be more suitable.
- **Incorrect MIME type:** While REST Assured often infers the MIME type, explicitly providing it with `multiPart(controlName, file, mimeType)` can prevent issues if the inference is wrong or if the server is strict.

## Interview Questions & Answers
1.  **Q: How do you handle file uploads in REST Assured?**
    **A:** In REST Assured, file uploads are handled using the `multiPart()` method. You typically provide the name of the form field (control name) and a `java.io.File` object representing the file. REST Assured then constructs the `multipart/form-data` request automatically.
    ```java
    given()
        .multiPart("file", new File("path/to/your/file.txt"))
    .when()
        .post("/upload")
    .then()
        .statusCode(200);
    ```
2.  **Q: What is `multipart/form-data` and why is it used for file uploads?**
    **A:** `multipart/form-data` is an HTTP `Content-Type` value used to send both text data and binary data (like files) in a single request. It's used for file uploads because it allows the request body to be divided into multiple "parts," each representing a separate form field or an uploaded file, with its own headers (like `Content-Disposition` and `Content-Type`) and content, separated by a unique boundary string.
3.  **Q: Can you upload multiple files in a single request using REST Assured? How?**
    **A:** Yes, you can upload multiple files by calling `multiPart()` multiple times, each with a different file and potentially different control names if the server expects them as separate fields.
    ```java
    given()
        .multiPart("file1", new File("path/to/file1.txt"))
        .multiPart("file2", new File("path/to/file2.jpg"))
    .when()
        .post("/multiple-uploads")
    .then()
        .statusCode(200);
    ```
4.  **Q: How do you specify a custom MIME type for a file upload in REST Assured?**
    **A:** You can specify a custom MIME type by using the overloaded `multiPart()` method that accepts a `mimeType` parameter: `multiPart(String controlName, File file, String mimeType)`. This is useful if REST Assured's default MIME type inference is incorrect or if the server expects a very specific type.
    ```java
    given()
        .multiPart("document", new File("path/to/report.pdf"), "application/pdf")
    .when()
        .post("/upload-document")
    .then()
        .statusCode(200);
    ```

## Hands-on Exercise
1.  **Objective:** Write a REST Assured test to upload an image file (e.g., `test_image.png`) to a mock API endpoint.
2.  **Steps:**
    a.  Create a dummy image file (you can use any small `.png` or `.jpg` file you have, or create a zero-byte file with the correct extension).
    b.  Set up a mock server (like the Spark example above, modifying it to handle image uploads) or use a known public API that supports image uploads (e.g., some image hosting services offer APIs for testing, but be mindful of their terms of service).
    c.  Write a REST Assured test case that uses `multiPart()` to send the image file.
    d.  Verify the response, asserting on the status code and any confirmation message from the server indicating a successful upload.
    e.  Ensure proper cleanup of the dummy image file after the test.

## Additional Resources
- **REST Assured GitHub Wiki - Multi-part form data:** [https://github.com/rest-assured/rest-assured/wiki/Usage#multi-part-form-data](https://github.com/rest-assured/rest-assured/wiki/Usage#multi-part-form-data)
- **MDN Web Docs - Sending files using a FormData object:** [https://developer.mozilla.org/en-US/docs/Web/API/FormData/Using_FormData_Objects](https://developer.mozilla.org/en-US/docs/Web/API/FormData/Using_FormData_Objects) (While JavaScript-focused, explains `multipart/form-data` concept well)
---
# api-4.5-ac2.md

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
---
# api-4.5-ac3.md

# API 4.5 AC3: Request/Response Logging with REST Assured

## Overview
In the world of API testing, understanding the exact request being sent and the response being received is crucial for debugging, validating, and ensuring the correct behavior of your services. REST Assured, a popular Java library for testing RESTful APIs, provides robust logging capabilities that allow testers to inspect every detail of the HTTP communication. This acceptance criterion focuses on leveraging `log().all()` for requests and `then().log().all()` for responses, with an emphasis on conditional logging—only printing logs when validation fails—to keep test output clean and focused.

## Detailed Explanation

### Why Logging is Essential in API Testing
Logging API requests and responses helps in:
- **Debugging**: Quickly pinpointing issues when an API call doesn't behave as expected. You can verify if the request payload, headers, or parameters are correctly formed, and if the response matches the expected structure and data.
- **Validation**: Confirming that the API behaves as documented under various conditions.
- **Troubleshooting**: Providing detailed information to developers when reporting bugs.

### `log().all()` for Request Details
When building an API request with REST Assured, you can use `.log().all()` directly after `given()` to print all details of the request *before* it is sent. This includes:
- HTTP Method and URI
- Request Headers
- Request Cookies
- Request Body (if any)

This is invaluable for verifying that your test is constructing the request as intended.

### `then().log().all()` for Response Details
Similarly, after making the API call and receiving a response, you can use `.then().log().all()` to print all details of the response *after* it is received. This includes:
- HTTP Status Line
- Response Headers
- Response Cookies
- Response Body

This allows for immediate inspection of the API's reply, aiding in both positive and negative testing scenarios.

### Conditional Logging: `log().ifValidationFails()`
While `log().all()` is useful, printing every request and response can quickly clutter the console, especially in large test suites. REST Assured offers a more intelligent logging mechanism: `log().ifValidationFails()`. This method allows you to configure logging such that request and/or response details are *only* printed to the console if any assertion or validation within the `then()` block fails. This keeps your test output clean when tests pass and provides critical debugging information exactly when you need it.

You can combine this with `.log().all()` by chaining `ifValidationFails()`:
- `given().log().ifValidationFails().all()`: Logs request details only if validation fails.
- `then().log().ifValidationFails().all()`: Logs response details only if validation fails.

This is the recommended approach for maintaining readable and efficient test logs.

## Code Implementation

Let's assume we have a simple REST API for managing users, accessible at `http://localhost:8080/api/users`.

```java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

public class ApiLoggingTests {

    // Base URI for the API
    private static final String BASE_URI = "http://localhost:8080";

    @BeforeAll
    static void setup() {
        RestAssured.baseURI = BASE_URI;
        // In a real scenario, you might start a mock server here or ensure the target API is running.
        // For demonstration, assume http://localhost:8080 is accessible.
        System.out.println("------------------------------------------------------------------");
        System.out.println("NOTE: For this test to run, a service must be running at " + BASE_URI);
        System.out.println("If no service is running, the tests will fail with connection errors.");
        System.out.println("------------------------------------------------------------------");
    }

    @Test
    void testGetUserByIdWithFullLogging() {
        // Example: Get a user by ID with full request and response logging
        given()
            .pathParam("id", 1) // Assuming user with ID 1 exists
            .log().all() // Log all request details before sending
        .when()
            .get("/api/users/{id}")
        .then()
            .log().all() // Log all response details after receiving
            .statusCode(200)
            .contentType(ContentType.JSON)
            .body("id", equalTo(1))
            .body("name", notNullValue());
    }

    @Test
    void testCreateUserWithConditionalLogging() {
        String requestBody = "{ "name": "John Doe", "email": "john.doe@example.com" }";

        // Example: Create a new user with conditional logging (only if validation fails)
        // This test is designed to pass, so no logs will be printed.
        given()
            .contentType(ContentType.JSON)
            .body(requestBody)
            .log().ifValidationFails().all() // Log request only if validation fails
        .when()
            .post("/api/users")
        .then()
            .log().ifValidationFails().all() // Log response only if validation fails
            .statusCode(201) // Assuming 201 Created on success
            .contentType(ContentType.JSON)
            .body("name", equalTo("John Doe"))
            .body("email", equalTo("john.doe@example.com"))
            .body("id", notNullValue());
    }

    @Test
    void testCreateUserWithConditionalLogging_FailingScenario() {
        // Simulating a failing scenario where email format is invalid, assuming API returns 400
        String invalidRequestBody = "{ "name": "Jane Doe", "email": "invalid-email" }";

        // This test is designed to fail due to incorrect status code expectation (200 instead of 400),
        // so logs will be printed.
        given()
            .contentType(ContentType.JSON)
            .body(invalidRequestBody)
            .log().ifValidationFails().all() // Request logs will be printed due to subsequent failure
        .when()
            .post("/api/users")
        .then()
            .log().ifValidationFails().all() // Response logs will be printed due to failure
            .statusCode(400) // Expecting 400 Bad Request if email is invalid
            .body("error", containsString("Invalid email format")); // Assuming API provides an error message
    }
}
```

## Best Practices
- **Use Conditional Logging**: Always prefer `log().ifValidationFails().all()` or specific log options like `log().ifError().body()` to keep your console output clean and focused on failures. Full logging (`log().all()`) should be used sparingly, primarily during initial test development or when deeply debugging a specific issue.
- **Avoid Logging Sensitive Data**: Be cautious about logging sensitive information such as passwords, API keys, or personal identifiable information (PII) to the console or log files. If necessary, ensure logs are secured and purged regularly. REST Assured allows logging specific parts of a request/response, e.g., `.log().headers()` or `.log().body()`, which can be more granular.
- **Integrate with Reporting**: Combine REST Assured logging with your test reporting tools (e.g., ExtentReports, Allure) to include request/response details in test reports for better traceability and debugging.
- **Performance Consideration**: While logging is useful, excessive logging, especially of large payloads, can introduce a slight overhead. In performance-critical test environments, be mindful of what and how much you log.

## Common Pitfalls
- **Over-logging**: Printing all request and response details for every single test case can make test output unreadable and difficult to parse, obscuring actual failures.
- **Logging Sensitive Information**: Accidentally logging sensitive data can lead to security vulnerabilities. Always review what is being logged.
- **Misinterpreting Logs**: Just because a log shows a certain request or response doesn't mean it's correct. Always compare logs against expected API behavior and documentation.
- **Not Logging Enough**: On the flip side, not logging anything makes debugging extremely difficult when tests fail unexpectedly. Find a balance, typically achieved with conditional logging.

## Interview Questions & Answers
1. **Q: How do you handle request and response logging in your API automation framework, and why is it important?**
   **A:** I primarily use REST Assured's built-in logging capabilities. For debugging and initial development, I might use `given().log().all()` and `then().log().all()`. However, in a mature test suite, I predominantly use `log().ifValidationFails().all()`. This approach is crucial because it ensures that our test output remains clean and focused. When a test fails, all relevant request and response details are automatically logged, providing immediate context for debugging without cluttering the console with successful test interactions. It significantly speeds up root cause analysis and helps developers understand the exact communication that led to an issue.

2. **Q: What considerations do you take into account when logging API requests and responses, especially in a production-like environment?**
   **A:** The primary considerations are security and performance.
   - **Security**: I ensure that no sensitive data (like authentication tokens, PII, or confidential business data) is logged to the console or persistent logs. If full logging is unavoidable for specific scenarios, strict access controls and retention policies must be in place for those logs. I would opt for logging specific headers or parts of the body if only certain information is needed.
   - **Performance**: Excessive logging, especially of large request/response bodies, can introduce overhead, particularly in high-volume test runs or CI/CD pipelines. Conditional logging mitigates this by only logging when necessary. In extreme cases, logging might be entirely disabled or reduced to error-only levels in performance-sensitive environments.

3. **Q: Can you describe a scenario where conditional logging significantly helped you debug an API test failure?**
   **A:** Absolutely. I was working on an API that involved complex data transformations. One specific test started failing intermittently in the CI/CD pipeline, but passed locally. With conditional logging (`log().ifValidationFails().all()`) enabled, when the test failed in CI, the full request and response details were automatically printed in the build logs. I immediately saw that a specific header, which was dynamically generated, had an incorrect value only in the CI environment due to an environmental configuration issue. Without conditional logging, finding this subtle difference in a sea of successful test logs would have been significantly harder and more time-consuming. It allowed me to quickly identify the discrepancy and work with the DevOps team to correct the environment variable.

## Hands-on Exercise
1. **Setup**: If you don't have one, set up a simple mock API server (e.g., using WireMock, MockServer, or even a simple Spring Boot/Node.js app) that has:
    - A `GET /api/products/{id}` endpoint that returns product details.
    - A `POST /api/products` endpoint that creates a product and returns the created product with a 201 status.
    - Ensure your POST endpoint can return a 400 status if an invalid product name (e.g., empty string) is provided.
2. **Implement**: Write two REST Assured tests:
    - One `GET` test for `/api/products/{id}` that passes and uses `log().all()` for both request and response.
    - One `POST` test for `/api/products` that:
        - Attempts to create a valid product (should pass, no logs with conditional logging).
        - Attempts to create an invalid product (should fail, and logs should automatically appear due to `log().ifValidationFails().all()`).
3. **Observe**: Run your tests and observe the console output. Verify that the logs appear as expected only for the failing scenario when using conditional logging.

## Additional Resources
- **REST Assured Official Documentation**: [https://rest-assured.io/](https://rest-assured.io/) (Refer to the "Logging" section)
- **REST Assured GitHub Repository**: [https://github.com/rest-assured/rest-assured](https://github.com/rest-assured/rest-assured)
---
# api-4.5-ac4.md

# REST Assured Filters for Request/Response Modification and Logging

## Overview
REST Assured filters provide a powerful mechanism to intercept and modify HTTP requests and responses, or to perform actions like logging, before they are sent or processed. This feature is crucial for advanced test automation scenarios, enabling global configurations, adding dynamic headers, masking sensitive data, or implementing custom logging strategies without cluttering individual test methods. Understanding and utilizing filters efficiently is a hallmark of a robust test automation framework.

## Detailed Explanation
In REST Assured, a `Filter` is an interface that allows you to hook into the request and response lifecycle. When a filter is applied, it gets a chance to inspect and modify the `RequestSpecification`, `ResponseSpecification`, and `Response` objects. This provides a centralized way to handle cross-cutting concerns.

There are primarily two types of operations you can perform with filters:
1.  **Request Modification**: Adding headers, parameters, authentication details, or even modifying the request body before it's sent.
2.  **Response Modification/Inspection**: Intercepting the response to perform custom assertions, mask sensitive data before logging, or extract specific information for later use.
3.  **Logging**: Implementing custom logging logic, perhaps integrating with an external logging framework or logging requests/responses in a specific format.

### How Filters Work:
The `Filter` interface has a single method:
```java
Response filter(FilterableRequestSpecification requestSpec, FilterableResponseSpecification responseSpec, FilterContext ctx);
```
-   `FilterableRequestSpecification`: Represents the request that is about to be sent. You can modify headers, base URI, authentication, etc.
-   `FilterableResponseSpecification`: Represents the expected response.
-   `FilterContext`: Provides access to the next filter in the chain or the actual request execution. Calling `ctx.next(requestSpec, responseSpec)` passes control to the next filter or executes the request if it's the last filter.

### Applying Filters:
Filters can be applied in several ways:
-   **Per-request**: Directly to a `RequestSpecification` instance.
-   **Globally**: To the static `RestAssured` configuration, affecting all subsequent requests. This is ideal for common requirements like logging all requests/responses or adding a default header.

## Code Implementation

This example demonstrates how to create a custom filter for logging request and response details, and another filter to add a custom header to every request.

```java
import io.restassured.RestAssured;
import io.restassured.filter.Filter;
import io.restassured.filter.FilterContext;
import io.restassured.filter.log.LogDetail;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import io.restassured.specification.FilterableRequestSpecification;
import io.restassured.specification.FilterableResponseSpecification;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

/**
 * Demonstrates the use of REST Assured Filters for logging and modifying requests.
 */
public class RestAssuredFilterExample {

    // A simple endpoint for demonstration. Replace with a real API if needed.
    // This example assumes a POST endpoint that echoes back the sent data and a GET endpoint.
    private static final String BASE_URI = "https://jsonplaceholder.typicode.com";

    @BeforeAll
    public static void setup() {
        RestAssured.baseURI = BASE_URI;
        // Optionally, reset filters before each test run if configured globally elsewhere
        // RestAssured.filters(new CustomLoggingFilter(), new CustomHeaderFilter("X-Client-ID", "MyAwesomeApp"));
    }

    /**
     * Custom filter to log request and response details.
     * This filter logs the request method, URI, headers, and body,
     * and then the response status, headers, and body.
     */
    public static class CustomLoggingFilter implements Filter {
        @Override
        public Response filter(FilterableRequestSpecification requestSpec, FilterableResponseSpecification responseSpec, FilterContext ctx) {
            System.out.println("--- Request Log ---");
            System.out.println("Method: " + requestSpec.getMethod());
            System.out.println("URI: " + requestSpec.getURI());
            System.out.println("Headers: " + requestSpec.getHeaders());
            // Log body only if present
            if (requestSpec.getBody() != null) {
                System.out.println("Body: " + requestSpec.getBody());
            }
            System.out.println("-------------------");

            Response response = ctx.next(requestSpec, responseSpec); // Execute the request and get the response

            System.out.println("--- Response Log ---");
            System.out.println("Status: " + response.getStatusLine());
            System.out.println("Headers: " + response.getHeaders());
            // Log body only if present and not too large
            if (response.getBody() != null && response.getBody().asString().length() < 2000) { // Limit logging large bodies
                System.out.println("Body: " + response.getBody().asString());
            } else if (response.getBody() != null) {
                System.out.println("Body: (truncated due to size)");
            }
            System.out.println("--------------------");
            return response;
        }
    }

    /**
     * Custom filter to add a specific header to every outgoing request.
     */
    public static class CustomHeaderFilter implements Filter {
        private final String headerName;
        private final String headerValue;

        public CustomHeaderFilter(String headerName, String headerValue) {
            this.headerName = headerName;
            this.headerValue = headerValue;
        }

        @Override
        public Response filter(FilterableRequestSpecification requestSpec, FilterableResponseSpecification responseSpec, FilterContext ctx) {
            System.out.println("Applying header: " + headerName + " = " + headerValue + " to request: " + requestSpec.getURI());
            requestSpec.header(headerName, headerValue);
            return ctx.next(requestSpec, responseSpec); // Pass control to the next filter or execute the request
        }
    }

    @Test
    void testGetRequestWithGlobalFilters() {
        System.out.println("
--- Running testGetRequestWithGlobalFilters ---");
        // Apply filters globally for all tests in this context
        RestAssured.filters(new CustomLoggingFilter(), new CustomHeaderFilter("X-Global-Correlation-ID", "abc-123"));

        given()
            .when()
                .get("/todos/1")
            .then()
                .statusCode(200)
                .body("id", equalTo(1));

        // Clear filters after test if you don't want them to affect other tests
        RestAssured.reset();
        System.out.println("--- testGetRequestWithGlobalFilters Finished ---
");
    }

    @Test
    void testPostRequestWithSpecificFilters() {
        System.out.println("
--- Running testPostRequestWithSpecificFilters ---");
        // Apply filters only for this specific request
        given()
            .filter(new CustomLoggingFilter())
            .filter(new CustomHeaderFilter("X-Request-Trace", "post-test-456"))
            .contentType(ContentType.JSON)
            .body("{ "title": "foo", "body": "bar", "userId": 1 }")
        .when()
            .post("/posts")
        .then()
            .statusCode(201)
            .body("title", equalTo("foo"))
            .body("userId", equalTo(1));
        System.out.println("--- testPostRequestWithSpecificFilters Finished ---
");
    }

    @Test
    void testDefaultRestAssuredLoggingFilter() {
        System.out.println("
--- Running testDefaultRestAssuredLoggingFilter ---");
        // REST Assured's built-in logging filter
        given()
            .filter(new io.restassured.filter.log.RequestLoggingFilter(LogDetail.ALL))
            .filter(new io.restassured.filter.log.ResponseLoggingFilter(LogDetail.ALL))
            .when()
                .get("/todos/2")
            .then()
                .statusCode(200)
                .body("id", equalTo(2));
        System.out.println("--- testDefaultRestAssuredLoggingFilter Finished ---
");
    }
}
```

## Best Practices
-   **Keep Filters Focused**: Each filter should ideally have a single responsibility (e.g., logging, header modification, authentication). This improves readability and maintainability.
-   **Global vs. Per-Request**: Use global filters (`RestAssured.filters(...)`) for concerns that apply to almost all requests (e.g., default authentication, universal logging). Use per-request filters (`given().filter(...)`) for specific scenarios or when a filter should only apply to a subset of requests.
-   **Order Matters**: The order in which filters are applied matters, as each filter passes the request/response to the next. For example, a logging filter should generally come before a filter that masks sensitive data if you want to log the unmasked data.
-   **Error Handling**: Consider how your filters behave in case of API errors. You might want to log error responses differently or add specific headers for error tracking.
-   **Performance**: While powerful, too many complex filters can introduce overhead. Profile your tests if performance becomes a concern.
-   **Reset Global Filters**: If you set global filters in `@BeforeAll` or `@BeforeEach`, remember to reset them in `@AfterAll` or `@AfterEach` using `RestAssured.reset()` to prevent them from interfering with other tests or test classes.

## Common Pitfalls
-   **Forgetting `ctx.next()`**: If you forget to call `ctx.next(requestSpec, responseSpec)` in your filter, the request will not proceed, and your tests will hang or fail.
-   **Infinite Loops**: If filters are not designed carefully, they might lead to infinite loops, especially if a filter somehow re-triggers the request execution.
-   **Modifying Immutable Objects**: Be aware that `RequestSpecification` and `Response` objects might have immutable aspects. Always use the methods provided by `FilterableRequestSpecification` to modify the request.
-   **Over-logging Sensitive Data**: Ensure your logging filters do not expose sensitive information (e.g., API keys, passwords) in logs, especially in shared environments. Implement masking if necessary.
-   **Unexpected Global Impact**: Applying a filter globally and forgetting to clear it can lead to unexpected side effects in other tests. Always be mindful of the scope of your filters.

## Interview Questions & Answers
1.  **Q**: What are REST Assured Filters and why are they useful in test automation?
    **A**: REST Assured Filters are interceptors that allow you to inspect and modify HTTP requests and responses at different stages of their lifecycle. They are useful because they provide a centralized, reusable mechanism to handle cross-cutting concerns like logging, adding common headers (e.g., authentication tokens), modifying payloads, or implementing custom error handling, without duplicating code in every test. This leads to cleaner, more maintainable, and robust test suites.

2.  **Q**: Explain the `filter()` method signature and the role of `FilterableRequestSpecification`, `FilterableResponseSpecification`, and `FilterContext`.
    **A**: The `filter()` method signature is `Response filter(FilterableRequestSpecification requestSpec, FilterableResponseSpecification responseSpec, FilterContext ctx)`.
    -   `FilterableRequestSpecification`: This object allows you to inspect and modify the outgoing request, such as adding headers, query parameters, changing the base URI, or altering the request body.
    -   `FilterableResponseSpecification`: This object represents the expected response and can be used to influence how REST Assured validates the response, though direct modification of the incoming `Response` object is typically done after `ctx.next()`.
    -   `FilterContext`: This object provides the means to pass control to the next filter in the chain or to execute the actual HTTP request if it's the last filter. You must call `ctx.next(requestSpec, responseSpec)` to ensure the request proceeds.

3.  **Q**: When would you use a global filter versus a per-request filter in REST Assured? Provide examples.
    **A**:
    -   **Global Filters**: Used when a specific concern applies to almost all or a large majority of your API requests. They are configured once (e.g., in a `@BeforeAll` method or static block) and affect all subsequent `given()` calls.
        *   *Example*: A logging filter that logs all requests and responses for debugging purposes.
        *   *Example*: An authentication filter that automatically adds an `Authorization` header with a bearer token to every request after login.
    -   **Per-request Filters**: Used when a filter's logic is specific to a particular test case or a small subset of requests. They are applied directly to a `RequestSpecification` using `given().filter(...)`.
        *   *Example*: A filter that adds a unique `X-Trace-ID` header for a specific test to trace a single request in system logs.
        *   *Example*: A filter to mask sensitive data in the request body for a particular test's logging output, while other tests might not require this.

## Hands-on Exercise
1.  **Objective**: Create a REST Assured custom filter that injects an `Accept-Language: en-US` header into all requests.
2.  **Steps**:
    *   Create a new class `AcceptLanguageFilter` that implements the `io.restassured.filter.Filter` interface.
    *   Inside the `filter` method, add the `Accept-Language` header to the `requestSpec`.
    *   Apply this filter globally using `RestAssured.filters()`.
    *   Write a test that makes a GET request to `https://httpbin.org/headers`.
    *   Assert that the response body contains the `Accept-Language` header with the value `en-US`.
    *   Remember to call `RestAssured.reset()` after your test to clean up global configurations.

## Additional Resources
-   **REST Assured Filters Documentation**: [https://rest-assured.io/docs/filters/](https://rest-assured.io/docs/filters/)
-   **Baeldung Tutorial on REST Assured Filters**: [https://www.baeldung.com/rest-assured-filters](https://www.baeldung.com/rest-assured-filters)
-   **GitHub Example of Custom Filters**: Search for `RestAssured custom filter example` on GitHub for more practical implementations.
---
# api-4.5-ac5.md

# API Response Time Validation and SLA Thresholds

## Overview
In API testing, validating not just the correctness of the response data but also the performance—specifically, the response time—is crucial. Slow APIs can degrade user experience and impact business operations. This module focuses on using REST Assured to assert API response times against predefined Service Level Agreement (SLA) thresholds, ensuring that your APIs meet performance expectations consistently.

## Detailed Explanation
Response time validation involves measuring how long an API takes to process a request and return a response, then comparing this duration against a maximum acceptable time. REST Assured provides powerful utilities to perform these checks easily.

The primary method for this is `response.time()`, which returns the response time in milliseconds. This can be combined with Hamcrest matchers (like `lessThan()`, `greaterThan()`, `equalTo()`) to create expressive assertions.

### Key Concepts:
1.  **Response Time Measurement**: REST Assured automatically captures the time taken for the entire request-response cycle.
2.  **SLA (Service Level Agreement)**: A predefined performance metric, typically a maximum acceptable response time (e.g., 2000ms or 2 seconds). Tests should fail if this threshold is breached.
3.  **Performance Consistency Analysis**: Beyond simple pass/fail, monitoring response times over time helps identify performance regressions, bottlenecks, and the overall consistency of your API's performance under various conditions.

### `time(lessThan(value))` Assertion
This is the most common assertion for validating response times against an upper bound.

```java
import io.restassured.RestAssured;
import org.testng.annotations.Test;
import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.lessThan;
import static org.hamcrest.Matchers.greaterThan;
import java.util.concurrent.TimeUnit;

public class ApiResponseTimeValidation {

    @Test
    public void validateResponseTimeLessThanSLA() {
        long slaThreshold = 2000L; // 2 seconds

        given()
            .when()
                .get("https://reqres.in/api/users?delay=1") // API that introduces a 1-second delay
            .then()
                .log().all()
                .assertThat()
                .time(lessThan(slaThreshold)); // Assert response time is less than 2000ms
    }

    @Test
    public void validateResponseTimeWithTimeUnit() {
        // You can also specify time units for more readability
        given()
            .when()
                .get("https://reqres.in/api/users?delay=2") // API that introduces a 2-second delay
            .then()
                .log().all()
                .assertThat()
                .time(lessThan(3L), TimeUnit.SECONDS); // Assert response time is less than 3 seconds
    }

    @Test
    public void validateResponseTimeWithinRange() {
        long minTime = 100L;
        long maxTime = 1500L;

        given()
            .when()
                .get("https://reqres.in/api/users") // A fast API
            .then()
                .log().all()
                .assertThat()
                .time(greaterThan(minTime))
                .time(lessThan(maxTime));
    }
}
```

## Code Implementation
```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;
import java.util.concurrent.TimeUnit;

public class AdvancedApiResponseTimeTests {

    private static final String BASE_URL = "https://reqres.in/api";
    // Define different SLA thresholds for various scenarios
    private static final long FAST_API_SLA_MS = 500L;       // APIs expected to be very fast
    private static final long MEDIUM_API_SLA_MS = 2000L;    // APIs with moderate processing
    private static final long SLOW_API_SLA_MS = 5000L;      // APIs with known delays or complex operations

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = BASE_URL;
    }

    /**
     * Test case to validate that a 'fast' API endpoint responds within its defined SLA.
     * This API is expected to respond very quickly.
     */
    @Test(description = "Verify response time for a 'fast' API endpoint")
    public void testFastApiPerformance() {
        System.out.println("Testing fast API endpoint: " + BASE_URL + "/users");
        given()
            .when()
                .get("/users") // This endpoint usually responds quickly
            .then()
                .log().all() // Log all response details for debugging
                .assertThat()
                .statusCode(200) // Ensure the request was successful
                .time(lessThan(FAST_API_SLA_MS), TimeUnit.MILLISECONDS); // Assert response time against fast SLA
        System.out.println("Fast API response time passed SLA: " + FAST_API_SLA_MS + "ms");
    }

    /**
     * Test case to validate an API endpoint that might have a slight delay,
     * ensuring it still adheres to a 'medium' SLA.
     * The 'delay=1' parameter simulates a 1-second server-side delay.
     */
    @Test(description = "Verify response time for an API endpoint with simulated delay within medium SLA")
    public void testMediumApiWithSimulatedDelayPerformance() {
        System.out.println("Testing medium API endpoint with delay: " + BASE_URL + "/users?delay=1");
        given()
            .when()
                .get("/users?delay=1") // Simulate 1-second delay
            .then()
                .log().all()
                .assertThat()
                .statusCode(200)
                .time(lessThan(MEDIUM_API_SLA_MS), TimeUnit.MILLISECONDS); // Assert response time against medium SLA
        System.out.println("Medium API with delay response time passed SLA: " + MEDIUM_API_SLA_MS + "ms");
    }

    /**
     * Test case to explicitly fail if an API's response time exceeds a strict SLA.
     * This example uses a 3-second delay, which should fail against the MEDIUM_API_SLA_MS (2 seconds).
     * This demonstrates how to set up tests that fail when SLA is breached.
     */
    @Test(description = "Demonstrate test failure when SLA is exceeded", expectedExceptions = AssertionError.class)
    public void testApiExceedingSLA_ShouldFail() {
        System.out.println("Expecting this test to fail due to SLA breach.");
        System.out.println("Testing API endpoint with excessive delay: " + BASE_URL + "/users?delay=3");
        try {
            given()
                .when()
                    .get("/users?delay=3") // Simulate 3-second delay
                .then()
                    .log().all()
                    .assertThat()
                    .statusCode(200)
                    .time(lessThan(MEDIUM_API_SLA_MS), TimeUnit.MILLISECONDS); // This should fail if delay > MEDIUM_API_SLA_MS
            System.out.println("This message should not be printed if the test fails as expected.");
        } catch (AssertionError e) {
            System.err.println("Test correctly failed because API response time exceeded SLA. Message: " + e.getMessage());
            throw e; // Re-throw to ensure TestNG marks it as a failed test
        }
    }

    /**
     * Capturing and logging response time for analysis without strict assertion (for monitoring).
     * This is useful for gathering data to analyze performance consistency over time.
     */
    @Test(description = "Capture and log response time for performance consistency analysis")
    public void captureAndLogResponseTime() {
        System.out.println("Capturing and logging response time for analysis.");
        Response response = given()
            .when()
                .get("/users?delay=0.5") // Simulate 0.5-second delay
            .then()
                .extract().response();

        long responseTimeInMs = response.time();
        long responseTimeInSeconds = response.timeIn(TimeUnit.SECONDS);

        System.out.println("API Response Time: " + responseTimeInMs + " ms");
        System.out.println("API Response Time: " + responseTimeInSeconds + " seconds");
        // Further actions: store this data, compare with historical averages, etc.
        // For demonstration, we'll just assert it's within a broad range
        response.then().assertThat().time(between(400L, 800L), TimeUnit.MILLISECONDS);
        System.out.println("Response time captured and logged.");
    }

    // Helper for Hamcrest between matcher (not directly available in older Hamcrest versions)
    // For modern Hamcrest, you might directly use allOf(greaterThan(), lessThan())
    private org.hamcrest.Matcher<Long> between(long min, long max) {
        return allOf(greaterThan(min), lessThan(max));
    }
}
```

## Best Practices
- **Define Clear SLAs**: Establish realistic and measurable SLA thresholds for different types of API calls (e.g., read, write, complex queries).
- **Use Time Units**: Explicitly specify `TimeUnit` in assertions (e.g., `TimeUnit.SECONDS`, `TimeUnit.MILLISECONDS`) for better readability and to prevent ambiguity.
- **Isolate Performance Tests**: Consider separating performance-sensitive tests from functional tests to avoid flaky results due to environmental factors.
- **Monitor Over Time**: Integrate response time checks into CI/CD pipelines and monitor trends. Tools like Prometheus and Grafana can visualize historical performance data.
- **Handle Network Latency**: Be aware that network latency can affect response times. Run performance tests from environments close to your API servers if possible.
- **Test Under Load**: While REST Assured is great for individual API call performance, use dedicated load testing tools (e.g., JMeter, Gatling, k6) for comprehensive load and stress testing.

## Common Pitfalls
- **Unrealistic SLA Thresholds**: Setting SLAs too tight can lead to constant false failures, while too loose can miss actual performance issues. Base SLAs on empirical data and business requirements.
- **Ignoring Network/Environment Factors**: Running tests from a developer's machine with varying network conditions can give inconsistent results. Use stable, controlled environments for performance testing.
- **Not Distinguishing Between First Call and Subsequent Calls**: Caching or database warm-up can make the first call significantly slower. Decide if your SLA applies to all calls or only subsequent ones.
- **Lack of Baselines**: Without historical data, it's hard to tell if a response time is good or bad. Establish baselines and track deviations.
- **Over-reliance on Single Assertions**: A single `lessThan` assertion is good, but combining it with logging or more detailed performance metrics can provide deeper insights.

## Interview Questions & Answers
1.  **Q: Why is API response time validation important in SDET roles?**
    **A**: It's crucial because slow APIs directly impact user experience, application stability, and business KPIs. SDETs ensure that performance is a non-functional requirement that's continuously met, preventing regressions and proactively identifying bottlenecks. It goes beyond functional correctness to ensure a high-quality, performant product.

2.  **Q: How would you set up response time SLAs for different API endpoints?**
    **A**: I would categorize APIs based on their criticality and expected complexity (e.g., authentication, data retrieval, complex calculations). Then, using historical data, load test results, and business requirements, I'd define specific thresholds for each category. For instance, a `/health` endpoint might have a 100ms SLA, while a complex `/report` generation might have a 5-second SLA. These SLAs would be integrated into automated tests.

3.  **Q: What tools or techniques do you use to monitor API performance consistency over time?**
    **A**: Besides automated tests with REST Assured (which give immediate feedback), I'd integrate performance metrics collection into CI/CD. Tools like Prometheus for data collection, Grafana for visualization, and potentially New Relic or Datadog for APM (Application Performance Monitoring) can track trends, identify anomalies, and alert teams to performance degradations.

## Hands-on Exercise
**Scenario**: Your team is developing an e-commerce product API. The `GET /products/{id}` endpoint should return product details.
**Task**:
1.  Write a REST Assured test for `GET https://fakestoreapi.com/products/1` (using product ID 1).
2.  Set an SLA threshold of 500 milliseconds for this endpoint.
3.  Implement a test that asserts the response time is less than this SLA.
4.  Add another assertion to ensure the status code is 200.
5.  Try changing the SLA to 50ms and observe the test failure, understanding why it failed.

## Additional Resources
-   **REST Assured Official Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Hamcrest Matchers**: [http://hamcrest.org/JavaHamcrest/tutorial](http://hamcrest.org/JavaHamcrest/tutorial)
-   **Understanding API Performance Metrics**: [https://www.blazemeter.com/blog/api-performance-testing-metrics](https://www.blazemeter.com/blog/api-performance-testing-metrics)
---
# api-4.5-ac6.md

# JDBC Database Integration for API Validation

## Overview
In modern microservices architectures, APIs often interact with databases. Validating the data persisted in the database after an API operation is crucial for ensuring data integrity and the correctness of your application. This module focuses on integrating JDBC (Java Database Connectivity) with your API test automation framework, specifically with REST Assured, to perform robust database validations. This allows testers to verify that API requests correctly modify or retrieve data from the underlying database, thereby providing end-to-end validation.

## Detailed Explanation
JDBC provides a standard API for Java applications to connect to relational databases. By incorporating JDBC into your REST Assured tests, you can:
1.  **Connect to a Database:** Establish a connection to various databases (e.g., MySQL, PostgreSQL, Oracle, SQL Server) using their respective JDBC drivers.
2.  **Execute SQL Queries:** Run `SELECT`, `INSERT`, `UPDATE`, `DELETE` queries to interact with the database.
3.  **Retrieve and Process Results:** Fetch query results, often into a `ResultSet` object, and process them to validate against API responses or request payloads.

The typical workflow for integrating database validation with API testing involves:
*   **Pre-API Call:** Optionally, clean up database state or insert prerequisite data for the API test.
*   **API Call:** Execute the REST Assured request.
*   **Post-API Call (Database Validation):** Connect to the database, query the relevant table(s) using identifiers from the API request or response, and assert that the database state reflects the expected changes or data.

### Key JDBC Components:
*   `Connection`: Represents a session with a specific database.
*   `Statement`/`PreparedStatement`: Used to execute SQL queries. `PreparedStatement` is highly recommended for parameterized queries to prevent SQL injection and improve performance.
*   `ResultSet`: Contains the data retrieved from a database after executing a `SELECT` query.

## Code Implementation
Here's a comprehensive example demonstrating how to integrate JDBC database validation with a REST Assured test. We'll assume a simple scenario where an API creates a user, and we then validate the user's presence and details in the database.

**Prerequisites:**
*   A running database (e.g., H2 in-memory, MySQL, PostgreSQL).
*   JDBC driver for your database added to your project's dependencies (e.g., `mysql-connector-java` for MySQL, `h2` for H2).

**`pom.xml` (Maven Dependencies - Example for H2, adjust for your DB):**
```xml
<dependencies>
    <!-- REST Assured -->
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <version>5.3.0</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>json-path</artifactId>
        <version>5.3.0</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>xml-path</artifactId>
        <version>5.3.0</version>
        <scope>test</scope>
    </dependency>
    <!-- TestNG -->
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.8.0</version>
        <scope>test</scope>
    </dependency>
    <!-- H2 Database (or your preferred JDBC driver) -->
    <dependency>
        <groupId>com.h2database</groupId>
        <artifactId>h2</artifactId>
        <version>2.2.220</version>
        <scope>test</scope>
    </dependency>
    <!-- JSON Simple for building request payload -->
    <dependency>
        <groupId>com.googlecode.json-simple</groupId>
        <artifactId>json-simple</artifactId>
        <version>1.1.1</version>
        <scope>test</scope>
    </dependency>
</dependencies>
```

**`DatabaseUtil.java` (Utility class for database operations):**
```java
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class DatabaseUtil {

    private static Connection connection;
    private static final String DB_URL = "jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1"; // H2 in-memory DB
    private static final String DB_USER = "sa";
    private static final String DB_PASSWORD = "";

    // Static block to initialize database schema (for H2 in-memory example)
    static {
        try {
            Class.forName("org.h2.Driver");
            connection = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            createTable();
        } catch (ClassNotFoundException | SQLException e) {
            e.printStackTrace();
            throw new RuntimeException("Failed to initialize database", e);
        }
    }

    private static void createTable() throws SQLException {
        Statement statement = null;
        try {
            statement = connection.createStatement();
            String createTableSQL = "CREATE TABLE IF NOT EXISTS users (" +
                                    "id INT AUTO_INCREMENT PRIMARY KEY," +
                                    "username VARCHAR(50) NOT NULL UNIQUE," +
                                    "email VARCHAR(100) NOT NULL);";
            statement.execute(createTableSQL);
            System.out.println("Table 'users' created or already exists.");
        } finally {
            if (statement != null) {
                statement.close();
            }
        }
    }

    public static Connection getConnection() throws SQLException {
        if (connection == null || connection.isClosed()) {
            connection = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
        }
        return connection;
    }

    public static ResultSet executeQuery(String query, Object... params) throws SQLException {
        PreparedStatement preparedStatement = null;
        try {
            connection = getConnection();
            preparedStatement = connection.prepareStatement(query);
            for (int i = 0; i < params.length; i++) {
                preparedStatement.setObject(i + 1, params[i]);
            }
            return preparedStatement.executeQuery();
        } catch (SQLException e) {
            e.printStackTrace();
            throw e;
        }
    }

    public static int executeUpdate(String query, Object... params) throws SQLException {
        PreparedStatement preparedStatement = null;
        try {
            connection = getConnection();
            preparedStatement = connection.prepareStatement(query);
            for (int i = 0; i < params.length; i++) {
                preparedStatement.setObject(i + 1, params[i]);
            }
            return preparedStatement.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
            throw e;
        }
    }

    public static void closeConnection() {
        try {
            if (connection != null && !connection.isClosed()) {
                connection.close();
                System.out.println("Database connection closed.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public static void cleanUpTable(String tableName) throws SQLException {
        int rowsAffected = 0;
        try {
            rowsAffected = executeUpdate("DELETE FROM " + tableName);
            System.out.println("Cleaned up table '" + tableName + "': " + rowsAffected + " rows deleted.");
        } catch (SQLException e) {
            System.err.println("Failed to clean up table '" + tableName + "': " + e.getMessage());
            throw e;
        }
    }
}
```

**`UserApiTest.java` (REST Assured test with JDBC validation):**
```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.json.simple.JSONObject;
import org.testng.Assert;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.sql.ResultSet;
import java.sql.SQLException;

public class UserApiTest {

    // Assuming a base URI for a mock API that interacts with the H2 DB
    // For a real application, this would be your actual API endpoint
    private final String BASE_URI = "http://localhost:8080/api"; // Example mock API base URI

    @BeforeMethod
    public void setup() throws SQLException {
        // Ensure the table is clean before each test to maintain test independence
        DatabaseUtil.cleanUpTable("users");
        // You might need to set up a mock server or actual application for BASE_URI
        // For demonstration, we'll assume the API "creates" a user in our H2 DB.
        // In a real scenario, the API would have its own backend logic.
    }

    @Test
    public void testCreateUserAndValidateInDB() throws SQLException {
        String username = "testuser_db_1";
        String email = "testuser1@example.com";

        // 1. Prepare API request payload
        JSONObject requestBody = new JSONObject();
        requestBody.put("username", username);
        requestBody.put("email", email);

        // 2. Make API call to create user
        Response response = RestAssured.given()
                .contentType("application/json")
                .body(requestBody.toJSONString())
                .post(BASE_URI + "/users"); // Assuming an endpoint like /api/users to create users

        // Assert API response status code
        Assert.assertEquals(response.getStatusCode(), 201, "Expected status code 201 for user creation");
        String responseUsername = response.jsonPath().getString("username");
        String responseEmail = response.jsonPath().getString("email");
        Assert.assertEquals(responseUsername, username, "Username in API response mismatch");
        Assert.assertEquals(responseEmail, email, "Email in API response mismatch");

        // For this example, we directly insert into DB to simulate API interaction
        // In a real test, the API call itself would trigger the DB insert/update.
        // We're skipping the actual mock API setup for brevity and focusing on DB validation.
        // If your API is running and connected to the H2 DB, the POST request above
        // would handle the insertion. For a standalone example, we'll insert here.
        DatabaseUtil.executeUpdate("INSERT INTO users (username, email) VALUES (?, ?)", username, email);


        // 3. Query the database to fetch the record created by API
        String query = "SELECT username, email FROM users WHERE username = ?";
        ResultSet resultSet = DatabaseUtil.executeQuery(query, username);

        // 4. Assert DB values match API request payload
        Assert.assertTrue(resultSet.next(), "User record not found in database for username: " + username);
        String dbUsername = resultSet.getString("username");
        String dbEmail = resultSet.getString("email");

        Assert.assertEquals(dbUsername, username, "Username in DB mismatch with request payload");
        Assert.assertEquals(dbEmail, email, "Email in DB mismatch with request payload");
        Assert.assertFalse(resultSet.next(), "Multiple records found for username: " + username); // Ensure only one record

        resultSet.close(); // Close the ResultSet
    }

    @AfterClass
    public void tearDown() {
        DatabaseUtil.closeConnection(); // Close the database connection after all tests
    }
}
```
**Important Note on `UserApiTest.java`:**
The provided `UserApiTest.java` is a conceptual example. For a truly runnable test, you would need:
1.  **A mock API server:** The `BASE_URI` points to `http://localhost:8080/api`. You'd need a simple server (e.g., using Spring Boot, Node.js Express, or even a simple Java HTTP server) that exposes a `/users` endpoint and interacts with the H2 in-memory database managed by `DatabaseUtil`.
2.  **API Logic:** The mock API's POST `/users` endpoint should actually persist the user data into the H2 database. In this example, `DatabaseUtil.executeUpdate` is called directly in the test to *simulate* the API's effect on the DB for demonstration purposes, as setting up a full mock server is outside the scope of this content generation.

## Best Practices
-   **Use `PreparedStatement`:** Always use `PreparedStatement` for SQL queries to prevent SQL injection vulnerabilities and improve query performance by allowing the database to pre-compile the query.
-   **Separate Concerns:** Create a dedicated utility class (e.g., `DatabaseUtil`) to encapsulate all database connection and operation logic. This improves code readability, maintainability, and reusability.
-   **Manage Connections Properly:** Ensure database connections, statements, and result sets are properly closed in `finally` blocks to prevent resource leaks. Use try-with-resources for auto-closing where possible.
-   **Test Data Management:** Implement strategies for test data setup and teardown. This might involve inserting known data before a test and cleaning it up afterward (e.g., `TRUNCATE` or `DELETE` statements) to ensure test isolation and repeatability.
-   **Environment Configuration:** Externalize database connection details (URL, username, password) using configuration files or environment variables, rather than hardcoding them.
-   **Error Handling:** Implement robust error handling for `SQLException` to gracefully manage database failures and provide meaningful error messages.
-   **Avoid Direct SQL in Tests:** While necessary for validation, try to keep direct SQL queries within your utility layer. Tests should ideally call methods from `DatabaseUtil` rather than constructing SQL strings directly.

## Common Pitfalls
-   **SQL Injection:** Using raw `Statement` objects and concatenating user input directly into SQL queries is a major security risk. Always use `PreparedStatement`.
-   **Resource Leaks:** Forgetting to close `Connection`, `Statement`, and `ResultSet` objects can lead to resource exhaustion and application instability, especially in long-running test suites.
-   **Hardcoded Credentials:** Storing database credentials directly in code is a security vulnerability.
-   **Inconsistent Test Data:** Not properly managing test data (e.g., leaving data from previous runs) can lead to flaky tests that pass or fail unpredictably.
-   **Slow Database Operations:** Excessive or inefficient database queries within tests can significantly slow down your test suite. Optimize queries and consider using in-memory databases (like H2 or HSQLDB) for unit/integration tests where appropriate.
-   **Ignoring Time Zones:** When comparing timestamps or dates, be mindful of time zones differences between your application, database, and test environment.

## Interview Questions & Answers
1.  **Q: Why is database validation important in API testing?**
    **A:** Database validation is crucial for ensuring end-to-end data integrity. It verifies that an API call not only returns the correct response but also correctly processes and persists data in the underlying database. This confirms that the entire transaction, from the API layer to the data layer, behaves as expected, catching issues that purely API-level assertions might miss.

2.  **Q: What are the key components of JDBC for connecting to a database?**
    **A:** The main components are:
    *   `DriverManager`: Manages a list of JDBC drivers. Used to establish a connection.
    *   `Connection`: An interface representing a session with a specific database. All communication with the database happens through this object.
    *   `Statement`/`PreparedStatement`: Interfaces used for executing SQL queries. `PreparedStatement` is preferred for parameterized queries.
    *   `ResultSet`: An interface representing a table of data returned by a SQL query. It allows iterating over the rows and retrieving column values.

3.  **Q: How do you prevent SQL injection when using JDBC?**
    **A:** The primary way to prevent SQL injection is by using `PreparedStatement` instead of `Statement`. `PreparedStatement` pre-compiles the SQL query and treats user-provided values as parameters, rather than incorporating them directly into the SQL string, thus neutralizing malicious input.

4.  **Q: Describe a scenario where database validation caught a bug that API response validation alone would have missed.**
    **A:** Consider an API endpoint for updating a user's email. The API might return a `200 OK` status and a response body indicating the email was updated successfully. However, due to a bug in the backend service, the email might not actually be updated in the database. Without database validation, this critical data inconsistency would go unnoticed, leading to functional issues downstream. Database validation would query the user's record after the API call and confirm the email was indeed changed.

5.  **Q: What considerations are important when managing test data for API tests that involve database validation?**
    **A:** Key considerations include:
    *   **Isolation:** Each test should be independent and not affect other tests. This often means setting up unique data before each test and cleaning it up afterwards.
    *   **Rollback/Cleanup:** Implement mechanisms (e.g., `DELETE` or `TRUNCATE` statements, database transactions with rollback) to restore the database to a known state after a test.
    *   **Data Generation:** For complex scenarios, consider using test data generation tools or frameworks to create realistic, yet controllable, data sets.
    *   **Pre-existing Data:** Avoid relying on pre-existing data in shared environments, as it can be modified by other processes or tests, leading to flaky failures.

## Hands-on Exercise
**Scenario:**
You have an API endpoint `POST /api/products` that creates a new product with `name` and `price`.
Your database has a `products` table with columns `id`, `name`, and `price`.

**Task:**
1.  Set up an H2 in-memory database with a `products` table (similar to how `users` table was set up in `DatabaseUtil`).
2.  Write a REST Assured test that:
    *   Creates a new product via the `POST /api/products` endpoint.
    *   Extracts the `name` and `price` from the API request payload.
    *   Connects to the database and queries the `products` table using the product `name`.
    *   Asserts that the product details (name, price) in the database match the values sent in the API request.

## Additional Resources
-   **Oracle JDBC Documentation:** [https://docs.oracle.com/javase/tutorial/jdbc/](https://docs.oracle.com/javase/tutorial/jdbc/)
-   **REST Assured Official Documentation:** [https://rest-assured.io/](https://rest-assured.io/)
-   **H2 Database Engine:** [http://www.h2database.com/html/main.html](http://www.h2database.com/html/main.html)
-   **Baeldung: Guide to JDBC:** [https://www.baeldung.com/java-jdbc](https://www.baeldung.com/java-jdbc)
---
# api-4.5-ac7.md

# WireMock for API Mocking

## Overview
In modern software development, especially within microservices architectures and during the testing phase, external API dependencies can be a bottleneck. These dependencies might be unstable, slow, rate-limited, or simply not yet implemented. Mocking API responses allows developers and SDETs to isolate the system under test (SUT) from these external factors, enabling faster, more reliable, and consistent testing. WireMock is a powerful, flexible, and developer-friendly tool for HTTP-based API mocking. It acts as a configurable HTTP server that can return specific responses to specific requests.

This document covers how to set up WireMock, stub API endpoints to return predefined responses, and test application logic against these stubbed responses using a Java and REST Assured example.

## Detailed Explanation

WireMock provides a versatile solution for simulating HTTP APIs. It can be used as a standalone process (running as a proxy or a separate server) or integrated into a JUnit test as a library. For SDETs, integrating it within JUnit tests is often the most convenient approach, as it allows dynamic stubbing and verification within the test lifecycle.

Key concepts in WireMock:
- **Stubbing:** Defining rules that map incoming HTTP requests to outgoing HTTP responses. This is the core functionality.
- **Request Matching:** WireMock can match requests based on URL, HTTP method, headers, cookies, query parameters, and request body (using various matching strategies like exact match, regex, JSONPath, XMLPath).
- **Response Definition:** Specifying the HTTP status code, headers, body, and even delays or fault injection for the stubbed response.
- **Verification:** Asserting that specific requests were made to WireMock, which is crucial for testing interactions.
- **Record/Proxy:** WireMock can also record interactions with real APIs and proxy requests.

### Setup WireMock Server (within a JUnit Test)

When used as a JUnit rule or extension, WireMock manages its lifecycle automatically.

**Maven Dependency:**
To use WireMock with JUnit 5:
```xml
<dependency>
    <groupId>com.github.tomakehurst</groupId>
    <artifactId>wiremock-jre8</artifactId>
    <version>2.35.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter-api</artifactId>
    <version>5.10.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter-engine</artifactId>
    <version>5.10.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>rest-assured</artifactId>
    <version>5.3.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.assertj</groupId>
    <artifactId>assertj-core</artifactId>
    <version>3.25.1</version>
    <scope>test</scope>
</dependency>
```

### Stub a Specific Endpoint to Return a Canned Response

Let's imagine we have an application that calls an external user service at `/api/users/{id}` to fetch user details. We want to mock this.

```java
import com.github.tomakehurst.wiremock.client.WireMock;
import com.github.tomakehurst.wiremock.junit5.WireMockExtension;
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static com.github.tomakehurst.wiremock.core.WireMockConfiguration.wireMockConfig;
import static org.assertj.core.api.Assertions.assertThat;

public class UserApiMockingTest {

    // Register the WireMock extension for JUnit 5
    @RegisterExtension
    static WireMockExtension wireMockExtension = WireMockExtension.newInstance()
            .options(wireMockConfig().port(8080)) // Configure WireMock to run on port 8080
            .build();

    @BeforeEach
    void setup() {
        // Base URI for REST Assured to point to the WireMock server
        RestAssured.baseURI = "http://localhost";
        RestAssured.port = 8080;
        
        // Reset WireMock before each test to ensure a clean state
        WireMock.reset();
    }

    @Test
    void shouldReturnUserDetailsWhenUserExists() {
        // 1. Stub a specific endpoint
        wireMockExtension.stubFor(get(urlEqualTo("/api/users/123"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "id": 123, "name": "John Doe", "email": "john.doe@example.com" }")));

        // 2. Test application logic against the stubbed response
        // In a real scenario, your application would make this HTTP call.
        // Here, we simulate it with REST Assured for demonstration.
        Response response = RestAssured.given()
                .when()
                .get("/api/users/123")
                .then()
                .extract().response();

        // Assertions on the received response
        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.jsonPath().getInt("id")).isEqualTo(123);
        assertThat(response.jsonPath().getString("name")).isEqualTo("John Doe");
        assertThat(response.jsonPath().getString("email")).isEqualTo("john.doe@example.com");

        // Optional: Verify that the request was made to WireMock
        wireMockExtension.verify(getRequestedFor(urlEqualTo("/api/users/123")));
    }

    @Test
    void shouldReturnNotFoundWhenUserDoesNotExist() {
        // Stub for a non-existent user
        wireMockExtension.stubFor(get(urlEqualTo("/api/users/404"))
                .willReturn(aResponse()
                        .withStatus(404)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "message": "User not found" }")));

        Response response = RestAssured.given()
                .when()
                .get("/api/users/404")
                .then()
                .extract().response();

        assertThat(response.statusCode()).isEqualTo(404);
        assertThat(response.jsonPath().getString("message")).isEqualTo("User not found");
        
        wireMockExtension.verify(getRequestedFor(urlEqualTo("/api/users/404")));
    }
    
    @Test
    void shouldHandlePostRequests() {
        // Stub a POST request with a specific request body
        wireMockExtension.stubFor(post(urlEqualTo("/api/users"))
                .withHeader("Content-Type", containing("application/json"))
                .withRequestBody(equalToJson("{ "name": "Jane Doe", "email": "jane.doe@example.com" }"))
                .willReturn(aResponse()
                        .withStatus(201)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "id": 456, "name": "Jane Doe", "email": "jane.doe@example.com" }")));

        String requestBody = "{ "name": "Jane Doe", "email": "jane.doe@example.com" }";
        Response response = RestAssured.given()
                .header("Content-Type", "application/json")
                .body(requestBody)
                .when()
                .post("/api/users")
                .then()
                .extract().response();

        assertThat(response.statusCode()).isEqualTo(201);
        assertThat(response.jsonPath().getInt("id")).isEqualTo(456);
        assertThat(response.jsonPath().getString("name")).isEqualTo("Jane Doe");
        
        wireMockExtension.verify(postRequestedFor(urlEqualTo("/api/users"))
                .withRequestBody(equalToJson(requestBody)));
    }
}
```

### Advanced Stubbing: Scenarios and State Management

WireMock can also simulate stateful behavior using scenarios, which is useful for testing workflows where API responses change based on previous interactions.

```java
import com.github.tomakehurst.wiremock.junit5.WireMockExtension;
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.RegisterExtension;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static com.github.tomakehurst.wiremock.core.WireMockConfiguration.wireMockConfig;
import static org.assertj.core.api.Assertions.assertThat;

public class OrderProcessingScenarioTest {

    @RegisterExtension
    static WireMockExtension wireMockExtension = WireMockExtension.newInstance()
            .options(wireMockConfig().port(8080))
            .build();

    @BeforeEach
    void setup() {
        RestAssured.baseURI = "http://localhost";
        RestAssured.port = 8080;
        wireMockExtension.resetAll(); // Reset all stubs and scenarios
    }

    @Test
    void shouldProcessOrderSuccessfullyThroughDifferentStates() {
        String ORDER_SCENARIO = "Order processing";
        String INITIAL_STATE = "Started";
        String PAYMENT_PROCESSED_STATE = "Payment Processed";
        String ORDER_SHIPPED_STATE = "Order Shipped";

        // 1. Initial order creation - returns PENDING status
        wireMockExtension.stubFor(post(urlEqualTo("/orders"))
                .inScenario(ORDER_SCENARIO)
                .whenScenarioStateIs(INITIAL_STATE)
                .willReturn(aResponse()
                        .withStatus(201)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "orderId": "ABC-123", "status": "PENDING" }"))
                .willSetStateTo(PAYMENT_PROCESSED_STATE));

        // 2. Process payment - moves to PAYMENT_PROCESSED state
        wireMockExtension.stubFor(post(urlEqualTo("/orders/ABC-123/payment"))
                .inScenario(ORDER_SCENARIO)
                .whenScenarioStateIs(PAYMENT_PROCESSED_STATE)
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "orderId": "ABC-123", "status": "PAID" }"))
                .willSetStateTo(ORDER_SHIPPED_STATE));

        // 3. Get order status after payment - returns PAID status
        wireMockExtension.stubFor(get(urlEqualTo("/orders/ABC-123"))
                .inScenario(ORDER_SCENARIO)
                .whenScenarioStateIs(ORDER_SHIPPED_STATE) // This state is actually "Order Shipped"
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "orderId": "ABC-123", "status": "SHIPPED" }")));
                        
        // 4. Get order status in initial state
        wireMockExtension.stubFor(get(urlEqualTo("/orders/ABC-123"))
                .inScenario(ORDER_SCENARIO)
                .whenScenarioStateIs(INITIAL_STATE)
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{ "orderId": "ABC-123", "status": "PENDING" }")));

        // -- Test Execution --

        // Create order (expect PENDING)
        Response createOrderResponse = RestAssured.given()
                .header("Content-Type", "application/json")
                .body("{ "item": "Laptop", "quantity": 1 }")
                .when()
                .post("/orders")
                .then()
                .extract().response();
        assertThat(createOrderResponse.statusCode()).isEqualTo(201);
        assertThat(createOrderResponse.jsonPath().getString("status")).isEqualTo("PENDING");
        
        // Get order status (expect PENDING)
        Response getOrderInitialResponse = RestAssured.given()
                .when()
                .get("/orders/ABC-123")
                .then()
                .extract().response();
        assertThat(getOrderInitialResponse.statusCode()).isEqualTo(200);
        assertThat(getOrderInitialResponse.jsonPath().getString("status")).isEqualTo("PENDING");


        // Process payment (expect PAID)
        Response processPaymentResponse = RestAssured.given()
                .header("Content-Type", "application/json")
                .body("{ "amount": 1200.00, "currency": "USD" }")
                .when()
                .post("/orders/ABC-123/payment")
                .then()
                .extract().response();
        assertThat(processPaymentResponse.statusCode()).isEqualTo(200);
        assertThat(processPaymentResponse.jsonPath().getString("status")).isEqualTo("PAID");

        // Get order status after payment (expect SHIPPED)
        Response getOrderShippedResponse = RestAssured.given()
                .when()
                .get("/orders/ABC-123")
                .then()
                .extract().response();
        assertThat(getOrderShippedResponse.statusCode()).isEqualTo(200);
        assertThat(getOrderShippedResponse.jsonPath().getString("status")).isEqualTo("SHIPPED");

        // Verify interactions
        wireMockExtension.verify(1, postRequestedFor(urlEqualTo("/orders")));
        wireMockExtension.verify(1, postRequestedFor(urlEqualTo("/orders/ABC-123/payment")));
        wireMockExtension.verify(2, getRequestedFor(urlEqualTo("/orders/ABC-123"))); // One for initial, one for shipped
    }
}
```

## Code Implementation
The code examples above demonstrate the setup, basic stubbing, and scenario-based stubbing. Ensure you have the necessary Maven dependencies.

## Best Practices
- **Isolation:** Use WireMock to isolate the system under test from external dependencies. This ensures that your tests are fast, reliable, and deterministic.
- **Dynamic Stubbing:** Integrate WireMock directly into your test suite (e.g., as a JUnit extension) to dynamically configure stubs for each test, ensuring tests are self-contained and reproducible.
- **Clear Matchers:** Be as specific as possible with request matchers to avoid unintended stubbing conflicts. Use `urlPathEqualTo`, `urlMatching`, `header`, `queryParam`, `requestBody` as needed.
- **Realistic Responses:** Provide realistic and representative mock responses, including appropriate HTTP status codes, headers, and body content, to accurately simulate real API behavior.
- **Verification:** Use WireMock's verification capabilities (`verify` and `requestedFor`) to assert that your application made the expected calls to the external services, especially for outbound integrations.
- **Reset State:** Always reset WireMock state (`wireMockExtension.resetAll()`) before each test to prevent test interference and ensure a clean environment.

## Common Pitfalls
- **Over-mocking:** Mocking too much of an external API can lead to brittle tests that break easily if the real API changes. Focus on mocking only the interactions relevant to your test case.
- **Under-mocking:** Not mocking enough can lead to tests that are still dependent on external services, making them slow and unreliable.
- **Incorrect Matchers:** Using overly broad matchers (e.g., `anyUrl()`) or incorrect matchers can lead to unexpected stub behavior or tests passing for the wrong reasons.
- **State Management Issues:** Forgetting to reset WireMock's state between tests can lead to test contamination, where one test's stubs or scenario states affect subsequent tests.
- **Missing Dependencies:** Forgetting to include the `wiremock-jre8` dependency (or the appropriate version for your Java runtime) in your `pom.xml` or `build.gradle`.

## Interview Questions & Answers

1.  **Q:** What is API mocking, and why is it important in SDET?
    **A:** API mocking is the process of simulating the behavior of a real API by providing predefined responses to specific requests. It's crucial in SDET for several reasons:
    *   **Isolation:** Decouples tests from external dependencies, making them faster, more stable, and independent of external service availability or network issues.
    *   **Early Testing:** Enables testing of features that depend on APIs not yet implemented or under development.
    *   **Edge Case Testing:** Facilitates testing of error conditions, slow responses, and other hard-to-reproduce scenarios from real APIs.
    *   **Cost Reduction:** Avoids incurring costs associated with repeated calls to external paid APIs during testing.

2.  **Q:** When would you choose WireMock over other mocking frameworks like Mockito?
    **A:** WireMock is specifically designed for **HTTP-based API mocking**, operating at the network level. It creates a real HTTP server that listens for requests. Mockito, on the other hand, is a **code-level mocking framework** primarily used for mocking Java interfaces or classes (dependencies within your application code). You would choose WireMock when:
    *   Testing interactions with external microservices or third-party APIs.
    *   Performing integration tests where actual HTTP communication is involved, but the external service needs to be controlled.
    *   Simulating network-related issues (latency, timeouts, errors).
    You would use Mockito for mocking internal collaborators of a class under test in unit tests.

3.  **Q:** How do you handle dynamic responses (e.g., different responses based on sequential calls) with WireMock?
    **A:** WireMock supports scenarios for handling dynamic responses based on sequential calls or state changes. You define a scenario with different states, and each stub can specify `whenScenarioStateIs` (the state it should be in for the stub to apply) and `willSetStateTo` (the state to transition to after the stub is matched). This allows you to model workflows and stateful interactions with APIs.

4.  **Q:** Explain how WireMock can be used for "fault injection" during API testing.
    **A:** Fault injection is the practice of intentionally introducing errors or delays into a system to test its resilience and error-handling capabilities. WireMock facilitates fault injection by allowing you to define stub responses with:
    *   **Non-2xx status codes:** Return 404 Not Found, 500 Internal Server Error, etc.
    *   **Fixed or random delays:** Use `withFixedDelay()` or `withRandomDelay()` to simulate slow networks or overloaded services.
    *   **Malform responses:** Return invalid JSON/XML, incomplete bodies, or empty responses to test parsing robustness.
    *   **Connection close:** Simulate abrupt connection termination.

## Hands-on Exercise

**Scenario:** You are testing an e-commerce application that relies on a "Product Catalog Service" to fetch product details. This service exposes a `GET /products/{id}` endpoint.

**Task:**
1.  Set up a JUnit 5 test with WireMock.
2.  Create a stub for `GET /products/PROD-001` that returns a 200 OK status with a JSON body representing a product (e.g., `{"id": "PROD-001", "name": "Laptop", "price": 1200.00}`).
3.  Create another stub for `GET /products/PROD-999` that returns a 404 Not Found status with an appropriate error message (e.g., `{"message": "Product not found"}`).
4.  Using REST Assured, make calls to these mock endpoints and assert the responses, verifying both successful and not-found scenarios.
5.  Add verification to ensure the expected GET requests were made to WireMock.

## Additional Resources
- **WireMock Official Documentation:** [http://wiremock.org/docs/](http://wiremock.org/docs/)
- **WireMock GitHub Repository:** [https://github.com/wiremock/wiremock](https://github.com/wiremock/wiremock)
- **Baeldung - Guide to WireMock:** [https://www.baeldung.com/introduction-to-wiremock](https://www.baeldung.com/introduction-to-wiremock)
- **REST Assured Official Documentation:** [https://rest-assured.io/](https://rest-assured.io/)
---
# api-4.5-ac8.md

# Implement Retry Logic for Flaky API Tests

## Overview
Flaky API tests are a common headache in automated testing. They pass sometimes and fail others without any code changes, often due to transient issues like network instability, temporary service unavailability, or test environment race conditions. Implementing retry logic helps to mitigate these flakiness issues by re-executing failed tests a specified number of times, improving the reliability and stability of your test suite. This feature focuses on applying TestNG's retry analyzer to REST Assured API tests.

## Detailed Explanation
Retry logic is a mechanism where a failed test or a part of a test (e.g., an API call) is automatically re-executed. For API tests, this is particularly useful because external factors, rather than actual bugs in the application under test, can often cause failures. TestNG provides a robust `IRetryAnalyzer` interface that allows custom implementation of retry conditions.

### How `IRetryAnalyzer` Works
1.  **Implement `IRetryAnalyzer`**: Create a class that implements the `IRetryAnalyzer` interface and its `retry(ITestResult result)` method.
2.  **`retry(ITestResult result)` Method**: This method is invoked every time a test method fails. It receives an `ITestResult` object containing information about the failed test.
3.  **Decision Logic**: Inside `retry()`, you define the logic to determine if the test should be retried. This typically involves checking a counter against a maximum retry limit.
4.  **Associate with Test**: The `IRetryAnalyzer` implementation can be associated with individual test methods using the `@Test(retryAnalyzer = MyRetryAnalyzer.class)` annotation, or globally via a TestNG listener.

### Why use Retry Logic?
-   **Increased Stability**: Reduces false negatives caused by transient issues.
-   **Improved CI/CD Reliability**: Prevents build failures due to environment flakiness.
-   **Better Resource Utilization**: Avoids unnecessary re-runs of entire test suites manually.

### When NOT to use Retry Logic
-   **Actual Bugs**: Retry logic should not mask genuine bugs. If a test consistently fails after retries, it indicates a real issue that needs fixing, not just retrying.
-   **Performance Critical Tests**: Retrying can increase test execution time.
-   **State-modifying Operations**: If a test modifies data, retrying it without proper cleanup or state management can lead to inconsistent data or unintended side effects.

## Code Implementation

First, let's define our `RetryAnalyzer` class.

```java
package com.example.retry;

import org.testng.IRetryAnalyzer;
import org.testng.ITestResult;

public class MyRetryAnalyzer implements IRetryAnalyzer {

    private int retryCount = 0;
    private static final int MAX_RETRY_COUNT = 2; // Retry a maximum of 2 times (total 3 attempts)

    @Override
    public boolean retry(ITestResult result) {
        if (retryCount < MAX_RETRY_COUNT) {
            System.out.println("Retrying test " + result.getName() + " for the " + (retryCount + 1) + " time.");
            retryCount++;
            return true; // Indicate that the test should be retried
        }
        return false; // Indicate that the test should not be retried
    }
}
```

Now, let's create a sample REST Assured test that might be flaky. We'll simulate flakiness by introducing a random failure.

```java
package com.example.apitests;

import com.example.retry.MyRetryAnalyzer;
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.testng.Assert.assertTrue;

public class FlakyApiTest {

    // A simple mock API endpoint for demonstration
    private static final String BASE_URL = "https://jsonplaceholder.typicode.com";

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = BASE_URL;
    }

    @Test(retryAnalyzer = MyRetryAnalyzer.class, description = "Test for a potentially flaky API endpoint")
    public void testGetPostByIdWithRetry() {
        System.out.println("Executing testGetPostByIdWithRetry at " + System.currentTimeMillis());

        // Simulate a flaky scenario: fail randomly the first few times
        // In a real scenario, this would be an actual network issue, server timeout, etc.
        if (MyRetryAnalyzer.getRetryCountStatic() < MyRetryAnalyzer.getMaxRetryCountStatic() && Math.random() < 0.7) {
            System.out.println("Simulating a transient failure for testGetPostByIdWithRetry.");
            // Force a failure to trigger retry
            assertTrue(false, "Simulated transient failure");
        }

        Response response = given()
                                .when()
                                .get("/posts/1")
                                .then()
                                .statusCode(200)
                                .extract()
                                .response();

        response.then()
                .body("id", equalTo(1))
                .body("title", equalTo("sunt aut facere repellat provident occaecati excepturi optio reprehenderit"));

        System.out.println("testGetPostByIdWithRetry PASSED successfully.");
    }
    
    // To make the MyRetryAnalyzer usable as a static context for the random flakiness simulation
    // A better approach for real tests would be to inject flakiness at the service layer or mock appropriately.
    // This is purely for demonstration of retry analyzer working.
    static class MyRetryAnalyzer {
        private static int retryCount = 0;
        private static final int MAX_RETRY_COUNT = 2;

        public static int getRetryCountStatic() {
            return retryCount;
        }

        public static int getMaxRetryCountStatic() {
            return MAX_RETRY_COUNT;
        }

        // Standard IRetryAnalyzer implementation
        public boolean retry(ITestResult result) {
            if (retryCount < MAX_RETRY_COUNT) {
                System.out.println("Retrying test " + result.getName() + " for the " + (retryCount + 1) + " time.");
                retryCount++;
                return true;
            }
            retryCount = 0; // Reset for next test if any, though typically MyRetryAnalyzer is instantiated per test
            return false;
        }
    }
}
```

**Note**: The static methods `getRetryCountStatic()` and `getMaxRetryCountStatic()` within `MyRetryAnalyzer` are added *solely* for the purpose of simulating a flaky test within the demonstration. In a real-world scenario, your `IRetryAnalyzer` would typically just manage its own retry count for the specific `ITestResult` instance it's attached to, and the flakiness would be genuinely external. For actual implementation, remove the static simulation logic.

To run this test, you'll need the following dependencies in your `pom.xml` (Maven) or `build.gradle` (Gradle):

```xml
<!-- Maven pom.xml -->
<dependencies>
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <version>5.3.0</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.8.0</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.hamcrest</groupId>
        <artifactId>hamcrest</artifactId>
        <version>2.2</version> <!-- Use a compatible version -->
        <scope>test</scope>
    </dependency>
</dependencies>
```

### Alternative: Global Retry Analyzer using TestNG Listener

For applying retry logic to multiple tests or all tests without annotating each one, you can use a TestNG listener.

```java
package com.example.listeners;

import com.example.retry.MyRetryAnalyzer;
import org.testng.IAnnotationTransformer;
import org.testng.annotations.ITestAnnotation;

import java.lang.reflect.Constructor;
import java.lang.reflect.Method;

public class AnnotationTransformer implements IAnnotationTransformer {
    @Override
    public void transform(ITestAnnotation annotation, Class testClass, Constructor testConstructor, Method testMethod) {
        // Only apply retry analyzer if it's not already set
        if (annotation.getRetryAnalyzerClass() == null) {
            annotation.setRetryAnalyzer(MyRetryAnalyzer.class);
        }
    }
}
```

To enable this listener, add it to your `testng.xml`:

```xml
<!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd" >
<suite name="API Test Suite" verbose="1" >
    <listeners>
        <listener class-name="com.example.listeners.AnnotationTransformer"/>
    </listeners>
    <test name="Flaky API Tests" >
        <classes>
            <class name="com.example.apitests.FlakyApiTest" />
        </classes>
    </test>
</suite>
```

## Best Practices
-   **Define Clear Retry Conditions**: Only retry on known transient failures. Avoid retrying on deterministic failures.
-   **Limit Retries**: Set a reasonable maximum retry count (e.g., 1-3 times). Excessive retries prolong test execution and might hide real issues.
-   **Logging**: Implement clear logging within your retry analyzer to indicate when a test is being retried and why. This aids debugging.
-   **Quarantine Flaky Tests**: If a test is consistently flaky even with retry logic, consider quarantining it to prevent blocking the pipeline, and investigate its root cause separately.
-   **Distinguish from Functional Failures**: Ensure that retry logic does not mask actual functional bugs. If a test fails after all retries, it should be treated as a definitive failure.
-   **Idempotent Operations**: Prefer retry logic for API calls that are idempotent (can be called multiple times without changing the result beyond the first call). For non-idempotent operations, ensure proper cleanup or unique request identifiers to prevent duplicate actions.

## Common Pitfalls
-   **Over-reliance on Retries**: Using retry logic as a substitute for fixing underlying instability in the test environment or the application itself.
-   **Infinite Retries**: Not setting a maximum retry count, leading to tests running indefinitely.
-   **Masking Real Bugs**: Retrying tests that fail due to actual application bugs, making these bugs harder to detect and fix.
-   **Increased Test Execution Time**: Too many retries or applying retry to too many tests can significantly increase the overall test suite execution time.
-   **State Corruption**: Retrying tests that modify system state without proper setup/teardown can lead to data inconsistencies.

## Interview Questions & Answers
1.  **Q: What are flaky tests, and why is retry logic important for API testing?**
    A: Flaky tests are automated tests that occasionally fail without any changes to the code or test environment, often due to transient issues like network latency, race conditions, or temporary external service unavailability. Retry logic is crucial for API testing because APIs often interact with external systems that can introduce such transient failures. Implementing retries helps to improve test stability, reduce false negatives, and prevent unnecessary CI/CD pipeline failures, allowing teams to focus on actual bugs rather than intermittent test failures.

2.  **Q: How would you implement retry logic in a TestNG-based API automation framework?**
    A: In a TestNG framework, I would implement retry logic by creating a class that implements the `IRetryAnalyzer` interface. This class would contain a counter and a `MAX_RETRY_COUNT`. The `retry()` method of this interface would increment the counter and return `true` if `retryCount` is less than `MAX_RETRY_COUNT`, indicating that the test should be retried. Otherwise, it returns `false`. This `MyRetryAnalyzer` class can then be applied to individual `@Test` methods using `@Test(retryAnalyzer = MyRetryAnalyzer.class)` or globally across the test suite via an `IAnnotationTransformer` listener in `testng.xml`.

3.  **Q: What are the risks of using retry logic, and when should you avoid it?**
    A: The primary risks of retry logic include masking genuine application bugs, significantly increasing test execution time, and potentially corrupting test data if tests involve non-idempotent operations without proper cleanup. You should avoid retry logic when a test consistently fails (indicating a real bug), for performance-critical tests where increased execution time is unacceptable, or for tests that modify system state without careful consideration of idempotency and cleanup. Retry logic should only be used for genuinely transient failures.

## Hands-on Exercise
1.  Set up a new Maven or Gradle project.
2.  Add the necessary REST Assured and TestNG dependencies.
3.  Implement the `MyRetryAnalyzer` class as shown above.
4.  Create `FlakyApiTest.java`. Instead of using `Math.random()`, try to introduce a delay (e.g., `Thread.sleep(500)`) and then make an assertion that might fail due to a simulated timeout or a race condition with a mock server.
5.  Run the test using `testng.xml` configured to use the `AnnotationTransformer` listener, ensuring the retry logic is applied globally.
6.  Observe the test output to verify that tests are retried upon failure.
7.  Modify the `MAX_RETRY_COUNT` and observe its impact on test execution.

## Additional Resources
-   **TestNG IRetryAnalyzer Documentation**: [https://testng.org/doc/documentation-main.html#_implementing_iretryanalyzer](https://testng.org/doc/documentation-main.html#_implementing_iretryanalyzer)
-   **REST Assured Official Website**: [http://rest-assured.io/](http://rest-assured.io/)
-   **Apache Maven**: [https://maven.apache.org/](https://maven.apache.org/)
-   **Gradle Build Tool**: [https://gradle.org/](https://gradle.org/)
