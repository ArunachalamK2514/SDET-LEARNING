# JSON Schema Validation with `json-schema-validator` in REST Assured

## Overview
In the world of API testing, merely checking HTTP status codes or individual field values is often insufficient. Ensuring the structural integrity and data types of JSON responses against a predefined contract is crucial for robust test automation. JSON Schema provides a powerful way to describe the structure of JSON data, and `json-schema-validator` (often used with REST Assured) allows us to validate API responses against these schemas effortlessly. This capability is vital for maintaining API consistency, catching unexpected changes, and preventing issues early in the development cycle.

## Detailed Explanation
JSON Schema is a vocabulary that allows you to annotate and validate JSON documents. It's like a blueprint for your JSON data, defining what properties are expected, their data types, whether they are optional or required, and even their formats or patterns.

When testing APIs, particularly RESTful services that return JSON, validating against a schema provides a higher level of confidence than simply asserting on a few fields. It helps ensure:
1.  **Structural Consistency**: The response always adheres to the expected layout.
2.  **Data Type Integrity**: Each field contains data of the correct type (e.g., an `id` is an integer, a `name` is a string).
3.  **Completeness**: All required fields are present.
4.  **Early Bug Detection**: Catches unexpected changes in the API response structure that might break client applications.

The `json-schema-validator` library integrates seamlessly with REST Assured, allowing you to perform schema validation with a single line of code using `matchesJsonSchemaInClasspath`. This method expects the JSON Schema file to be available in the classpath of your test project.

**Steps to implement JSON Schema validation:**
1.  **Generate JSON Schema**: Obtain or create a JSON Schema file (`.json` extension) that represents the expected structure of your API response. Tools like JSON Schema Generator or online validators can help generate schemas from sample JSON responses.
2.  **Add Dependency**: Include the `json-schema-validator` dependency in your project's `pom.xml` (for Maven) or `build.gradle` (for Gradle).
3.  **Place Schema in Classpath**: Put the generated JSON Schema file(s) in a location that's part of your project's classpath (e.g., `src/test/resources/schemas/`).
4.  **Implement Validation**: Use `body(matchesJsonSchemaInClasspath("path/to/your/schema.json"))` in your REST Assured test.

## Code Implementation

Let's assume we have an API endpoint `/users/{id}` that returns a JSON response like this:
```json
{
  "id": 1,
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "age": 30,
  "isActive": true
}
```

First, let's create a JSON Schema for this response. Save this as `user_schema.json` in `src/test/resources/schemas/`:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "User",
  "description": "Schema for a user object",
  "type": "object",
  "required": [
    "id",
    "firstName",
    "lastName",
    "email",
    "age",
    "isActive"
  ],
  "properties": {
    "id": {
      "type": "integer",
      "description": "Unique identifier for the user"
    },
    "firstName": {
      "type": "string",
      "description": "First name of the user"
    },
    "lastName": {
      "type": "string",
      "description": "Last name of the user"
    },
    "email": {
      "type": "string",
      "format": "email",
      "description": "Email address of the user"
    },
    "age": {
      "type": "integer",
      "minimum": 0,
      "description": "Age of the user"
    },
    "isActive": {
      "type": "boolean",
      "description": "Whether the user account is active"
    }
  },
  "additionalProperties": false
}
```

Now, add the `json-schema-validator` dependency to your `pom.xml`:

```xml
<!-- pom.xml snippet -->
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>json-schema-validator</artifactId>
    <version>5.3.0</version> <!-- Use the latest version -->
    <scope>test</scope>
</dependency>
```

Finally, here's the REST Assured test code:

```java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;
import static io.restassured.module.jsv.JsonSchemaValidator.matchesJsonSchemaInClasspath;
import static org.hamcrest.Matchers.equalTo;

public class UserApiSchemaValidationTest {

    private static final String BASE_URI = "http://localhost:8080"; // Replace with your actual API base URI

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = BASE_URI;
        // You might want to start a mock server for reliable testing
        // or ensure your API is running.
        // For demonstration, let's assume a mock server is running or API is accessible.
    }

    @Test
    public void testGetUserByIdAndValidateSchema() {
        int userId = 1;

        // Mock API response for demonstration purposes if a live API is not available
        // In a real scenario, this would be an actual API call.
        // For this example, we're assuming a real API call would return the JSON above.
        // If you're running a mock server (e.g., WireMock), configure it to return the sample JSON.

        // Example of a basic GET request with schema validation
        given()
            .pathParam("id", userId)
            .when()
            .get("/users/{id}")
            .then()
            .log().all() // Log all response details for debugging
            .statusCode(200) // Assert HTTP status code
            .contentType(ContentType.JSON) // Assert content type
            .body("id", equalTo(userId)) // Basic field assertion (optional, but good practice)
            .body(matchesJsonSchemaInClasspath("schemas/user_schema.json")); // Validate against JSON Schema
    }

    @Test
    public void testCreateUserAndValidateSchema() {
        String requestBody = "{
" +
                             "  "firstName": "Jane",
" +
                             "  "lastName": "Smith",
" +
                             "  "email": "jane.smith@example.com",
" +
                             "  "age": 28,
" +
                             "  "isActive": false
" +
                             "}";

        // This test would typically validate the response after a POST request
        // For schema validation, the response body would be validated.
        given()
            .contentType(ContentType.JSON)
            .body(requestBody)
            .when()
            .post("/users")
            .then()
            .log().all()
            .statusCode(201) // Assuming 201 Created for successful creation
            .body(matchesJsonSchemaInClasspath("schemas/user_schema.json")); // Validate the response of the created user
    }
}
```

## Best Practices
-   **Keep Schemas Versioned**: Treat your JSON Schemas as part of your API contract. Version them along with your API to ensure tests remain relevant.
-   **Granular Schemas**: For complex APIs, break down large schemas into smaller, reusable components using `$ref`. This improves readability and maintainability.
-   **Automate Schema Generation**: If your API is documented (e.g., OpenAPI/Swagger), consider automating JSON Schema generation from your API specification.
-   **`additionalProperties: false`**: Use `additionalProperties: false` in your schema to strictly disallow any properties not explicitly defined. This helps catch unexpected fields in the response.
-   **Early Integration**: Integrate schema validation early in the development lifecycle to catch API contract deviations as soon as they occur.
-   **Mock Servers**: Use mock servers (like WireMock) to provide stable and predictable responses for schema validation tests, isolating them from actual backend volatility.

## Common Pitfalls
-   **Outdated Schemas**: Schemas can quickly become outdated if the API evolves without corresponding schema updates. This leads to false positives (tests pass but API is broken) or false negatives (tests fail but API is actually correct).
    *   **How to Avoid**: Implement a robust API documentation and schema management strategy. Integrate schema generation/update into CI/CD if possible, or establish clear communication channels between API developers and testers.
-   **Incorrect Classpath**: The `matchesJsonSchemaInClasspath` method relies on the schema file being correctly placed in the test classpath. A common mistake is placing it in the wrong directory or having a typo in the path.
    *   **How to Avoid**: Always verify the path. The standard location is `src/test/resources/`. Ensure the path in the test method matches the relative path from `src/test/resources/` (e.g., `schemas/user_schema.json`).
-   **Overly Permissive Schemas**: If a schema is too lenient (e.g., allows `additionalProperties: true` everywhere, or doesn't specify required fields), it might not catch breaking changes effectively.
    *   **How to Avoid**: Be as strict as possible with your schemas. Define all expected properties, their types, and use `required` and `additionalProperties: false` where appropriate.
-   **Schema Complexity**: Overly complex or deeply nested schemas can be hard to read and maintain.
    *   **How to Avoid**: Use `$ref` to break down schemas into modular parts. Keep individual schema files focused on a single entity or object.

## Interview Questions & Answers
1.  **Q: Why is JSON Schema validation important in API test automation?**
    **A:** JSON Schema validation is critical because it verifies the contract between the API producer and consumer. It ensures that the API response adheres to a predefined structure, data types, and required fields. This helps in catching breaking changes early, preventing client-side issues, improving API reliability, and providing a higher level of confidence in the API's stability beyond just functional correctness.

2.  **Q: How do you integrate JSON Schema validation with REST Assured?**
    **A:** Integration with REST Assured is straightforward. First, add the `json-schema-validator` dependency. Then, place your JSON Schema files in the `src/test/resources` directory (or a subdirectory within it) to make them available in the classpath. Finally, in your REST Assured test, use the `body(matchesJsonSchemaInClasspath("path/to/your/schema.json"))` assertion method as part of your `.then()` block.

3.  **Q: What are the common challenges with JSON Schema validation and how do you address them?**
    **A:** Common challenges include maintaining up-to-date schemas as APIs evolve, correctly placing schema files in the classpath, and writing schemas that are sufficiently strict without being overly brittle. I address these by:
    *   **Schema Maintenance**: Establishing a process for schema updates alongside API changes, potentially integrating schema generation/validation into CI/CD pipelines.
    *   **Classpath Issues**: Double-checking file paths and ensuring schemas are in `src/test/resources`.
    *   **Strictness vs. Brittleness**: Using `additionalProperties: false` and `required` fields for strict validation, but also leveraging `$ref` for modularity to manage complexity and reduce brittleness when minor, non-breaking changes occur in sub-objects.

## Hands-on Exercise
**Scenario**: You are testing a simple "Product Catalog" API.
**Endpoint**: `GET /products/{id}`
**Sample Response**:
```json
{
  "productId": "PROD001",
  "name": "Laptop Pro",
  "description": "High-performance laptop for professionals",
  "price": 1299.99,
  "inStock": true,
  "categories": ["Electronics", "Computers"]
}
```
**Task**:
1.  Create a JSON Schema file (`product_schema.json`) for the above response, ensuring `productId`, `name`, `price`, and `inStock` are required. `price` should be a number with a minimum value of 0. `categories` should be an array of strings.
2.  Place the schema file in `src/test/resources/schemas/`.
3.  Write a REST Assured test that makes a `GET` request to `/products/{id}` (you can mock the response or use a real API if available) and validates the response against your `product_schema.json`.

## Additional Resources
-   **JSON Schema Official Website**: [https://json-schema.org/](https://json-schema.org/) - Comprehensive documentation on JSON Schema.
-   **REST Assured JSON Schema Validation Guide**: [https://github.com/rest-assured/json-schema-validator](https://github.com/rest-assured/json-schema-validator) - Official GitHub repository and usage examples.
-   **Online JSON to JSON Schema Converter**: [https://jsonschema.net/](https://jsonschema.net/) - A helpful tool to generate schemas from sample JSON.
-   **Baeldung Tutorial on REST Assured JSON Schema Validation**: [https://www.baeldung.com/rest-assured-json-schema](https://www.baeldung.com/rest-assured-json-schema) - Another good tutorial with practical examples.
