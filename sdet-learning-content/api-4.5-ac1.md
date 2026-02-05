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