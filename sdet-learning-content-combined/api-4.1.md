# api-4.1-ac1.md

# REST Assured Fundamentals: Advantages for API Testing

## Overview
REST Assured is a powerful Java-based library designed to simplify the testing of RESTful web services. It provides a domain-specific language (DSL) that makes writing readable and maintainable tests straightforward. In the landscape of API testing tools, REST Assured stands out, especially when compared to GUI-based tools like Postman or Newman, due to its deep integration with the development ecosystem, flexibility, and superior fit for automated CI/CD pipelines. This document explores the key advantages of using REST Assured for API testing.

## Detailed Explanation

### REST Assured vs. Postman/Newman

| Feature             | REST Assured                                      | Postman/Newman                                   |
| :------------------ | :------------------------------------------------ | :----------------------------------------------- |
| **Type**            | Java library                                      | GUI tool (Postman), CLI runner (Newman)          |
| **Code-based**      | Fully code-driven, Java-centric                   | GUI-driven, JavaScript for scripting             |
| **Integration**     | Seamless with Java projects, build tools (Maven, Gradle), and test frameworks (JUnit, TestNG) | Separate application, integrates via API calls or CLI |
| **Version Control** | Tests are plain code, easily version-controlled with Git | Collections/environments often stored as JSON, can be version-controlled but less granular |
| **Reusability**     | High. Functions, classes, and helper methods can be extensively reused across tests. | Limited to snippets and environment variables within collections. |
| **CI/CD Fit**       | Excellent. Designed for automated execution in build pipelines. | Good with Newman (CLI runner), but still relies on pre-defined collections. |
| **Debugging**       | Utilizes standard Java debugging tools (IDEs)     | Built-in console/debugger in Postman GUI.        |
| **Learning Curve**  | Moderate for Java developers.                     | Low for basic usage, moderate for advanced scripting. |

### Java Integration and BDD Syntax Benefits

REST Assured's core strength lies in its native Java integration. This means:
*   **Leveraging Existing Skills**: Java developers can write API tests using a language they are already proficient in, reducing the learning curve and increasing team productivity.
*   **Ecosystem Compatibility**: It seamlessly integrates with popular Java build tools like Maven and Gradle, and testing frameworks such as JUnit and TestNG. This allows API tests to be part of the same project structure as the application code.
*   **BDD (Behavior-Driven Development) Syntax**: REST Assured adopts a BDD-like syntax (`given().when().then()`), which makes tests highly readable and expressive, almost like plain English. This improves collaboration between technical and non-technical stakeholders, as the tests describe the expected behavior of the API.
    *   `given()`: Sets up the request, including headers, parameters, body, authentication.
    *   `when()`: Specifies the HTTP method and endpoint.
    *   `then()`: Validates the response, including status code, headers, and body.

### CI/CD Pipeline Integration

REST Assured tests are fundamentally executable code. This characteristic makes them ideal for integration into a Continuous Integration/Continuous Delivery (CI/CD) pipeline:
1.  **Automated Execution**: Tests can be triggered automatically with every code commit or build, ensuring immediate feedback on API health.
2.  **No Manual Intervention**: Unlike GUI tools that might require manual clicks or specific setup, REST Assured tests run headless and are fully scriptable.
3.  **Fast Feedback Loop**: Failures are detected early in the development cycle, reducing the cost and effort of fixing issues.
4.  **Scalability**: Easy to scale by running tests in parallel across multiple environments or machines, a task that is often more complex with GUI tools.
5.  **Reporting**: Can be integrated with standard reporting frameworks (e.g., Extent Reports, Allure) to generate comprehensive test reports.

## Code Implementation

Here's a simple example of testing a GET endpoint using REST Assured, typically within a TestNG or JUnit test class.

```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*; // For Hamcrest matchers

public class UserApiTest {

    private static final String BASE_URL = "https://reqres.in/api"; // Example API

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = BASE_URL;
    }

    @Test
    public void testGetAllUsers() {
        // Given no specific prerequisites (e.g., headers, params) for this simple GET
        given()
        .when() // When we make a GET request to the /users endpoint
            .get("/users")
        .then() // Then we expect the following
            .statusCode(200) // The status code should be 200 OK
            .body("data", hasSize(greaterThan(0))) // The 'data' array in the response should not be empty
            .body("data[0].id", notNullValue()) // The first user should have an ID
            .body("data[0].email", containsString("@reqres.in")) // The first user's email should contain "@reqres.in"
            .log().all(); // Log all details of the request and response for debugging
    }

    @Test
    public void testGetSingleUser() {
        int userId = 2; // User ID to retrieve
        given()
            .pathParam("userId", userId) // Set a path parameter for the request
        .when()
            .get("/users/{userId}") // Make a GET request to the specific user endpoint
        .then()
            .statusCode(200)
            .body("data.id", equalTo(userId)) // Validate the returned user's ID
            .body("data.first_name", equalTo("Janet")) // Validate a specific field
            .log().body(); // Log only the response body
    }

    @Test
    public void testCreateUser() {
        String requestBody = "{ "name": "morpheus", "job": "leader" }"; // JSON request body

        given()
            .contentType("application/json") // Specify the content type of the request body
            .body(requestBody) // Attach the JSON body
        .when()
            .post("/users") // Make a POST request to create a user
        .then()
            .statusCode(201) // Expect a 201 Created status
            .body("name", equalTo("morpheus")) // Validate the name in the response
            .body("job", equalTo("leader")) // Validate the job in the response
            .body("id", notNullValue()) // Ensure an ID is generated
            .body("createdAt", notNullValue()) // Ensure a createdAt timestamp is present
            .log().body();
    }
}
```

To run this code, you would need:
*   **Maven Dependency**:
    ```xml
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <version>5.3.0</version> <!-- Use the latest version -->
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.8.0</version> <!-- Or JUnit 5 -->
        <scope>test</scope>
    </dependency>
    ```
*   **Gradle Dependency**:
    ```gradle
    testImplementation 'io.rest-assured:rest-assured:5.3.0' // Use the latest version
    testImplementation 'org.testng:testng:7.8.0' // Or JUnit 5
    ```

## Best Practices
-   **Parameterization**: Use data providers (TestNG) or parameterized tests (JUnit) to test the same endpoint with different data sets.
-   **Reusability**: Create utility methods or classes for common authentication, header setups, or response validations to avoid code duplication.
-   **Environment Configuration**: Externalize base URLs, API keys, and other environment-specific configurations to properties files or environment variables.
-   **Logging**: Use `log().all()`, `log().body()`, `log().headers()`, etc., judiciously for debugging, but avoid excessive logging in production test runs.
-   **BDD Adoption**: Stick to the `given-when-then` structure for clarity and readability.
-   **Schema Validation**: For robust tests, validate response JSON against a predefined schema.

## Common Pitfalls
-   **Hardcoding Values**: Directly embedding URLs, credentials, or expected data in tests makes them brittle and hard to maintain. Always externalize.
-   **Over-validating**: Testing every single field in a large JSON response can make tests cumbersome. Focus on critical fields and use schema validation for overall structure.
-   **Ignoring Error Scenarios**: Only testing positive flows is insufficient. Always include tests for invalid inputs, unauthorized access, and other error conditions.
-   **Lack of Readability**: Poorly structured or commented tests reduce their value. Leverage REST Assured's DSL and add meaningful comments.
-   **Not Cleaning Up Test Data**: For APIs that create or modify data, ensure proper cleanup after tests to maintain test independence and data integrity.

## Interview Questions & Answers
1.  **Q**: What are the main advantages of using a code-driven API testing framework like REST Assured over GUI tools like Postman?
    **A**: The primary advantages include better integration with CI/CD pipelines for automated execution, superior version control of tests as they are plain code, higher reusability of test logic through programming constructs, and the ability to leverage existing programming skills (e.g., Java) and debugging tools. It also allows for more complex test scenarios and seamless integration with build systems.

2.  **Q**: Explain the `given().when().then()` syntax in REST Assured.
    **A**: This is REST Assured's BDD-style syntax, which improves test readability:
    *   `given()`: Used to set up the request. This is where you define prerequisites like request headers, query/path parameters, request body, authentication details, cookies, etc.
    *   `when()`: Specifies the action, which is typically the HTTP method (GET, POST, PUT, DELETE) and the endpoint being tested.
    *   `then()`: Used to validate the response. Here, you assert on the status code, response body, headers, cookies, and other aspects of the API response using Hamcrest matchers or other assertion libraries.

3.  **Q**: How does REST Assured contribute to a robust CI/CD pipeline for API testing?
    **A**: REST Assured tests, being code-based, can be executed as part of the automated build process without any manual intervention. They integrate seamlessly with build tools (Maven/Gradle) and CI servers (Jenkins, GitLab CI, GitHub Actions). This enables fast feedback on API health with every code change, prevents regressions, and helps maintain a high-quality API by running tests continuously and automatically. This makes it far more efficient than relying on GUI tools for regular, automated checks.

## Hands-on Exercise
**Objective**: Test a public API with authentication (if applicable) and perform CRUD operations.

1.  Choose a public API that requires authentication (e.g., GitHub API, a mock API that simulates authentication). If authentication is too complex, use `https://jsonplaceholder.typicode.com/` for simpler exercises.
2.  **GET Request**: Write a REST Assured test to fetch a list of resources or a single resource. Validate the status code, at least two fields in the response body, and one response header.
3.  **POST Request**: Write a REST Assured test to create a new resource. Send a valid JSON request body. Validate the status code (e.g., 201 Created) and that the response body contains the data sent and any generated IDs.
4.  **(Optional) PUT/DELETE Request**: Implement tests for updating and deleting resources. Ensure proper status code and response validation.
5.  Refactor your tests to use `BeforeClass` or `BeforeMethod` for common setup (e.g., `baseURI`, authentication tokens).

## Additional Resources
-   **REST Assured Official Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Hamcrest Matchers Tutorial**: [http://hamcrest.org/JavaHamcrest/tutorial](http://hamcrest.org/JavaHamcrest/tutorial)
-   **Maven/Gradle Guides for Test Automation**: Search for "Maven Test Automation Tutorial" or "Gradle Test Automation Tutorial" to understand dependency management.
---
# api-4.1-ac2.md

# REST Assured BDD-style Syntax: given(), when(), then()

## Overview
REST Assured is a popular Java library for testing RESTful web services. One of its most powerful features is its support for Behavior-Driven Development (BDD) style syntax, which significantly enhances test readability and maintainability. By using `given()`, `when()`, and `then()` clauses, tests closely resemble user stories, making them understandable not only to developers but also to business analysts and other stakeholders. This approach promotes clear communication about the expected behavior of the API.

## Detailed Explanation
The BDD-style syntax in REST Assured is inspired by frameworks like Cucumber and Spock. It structures API tests into three main blocks, mirroring a user story:

*   **`given()`**: This block sets up the preconditions for the test. It includes all the data and configurations needed before the API request is made. This can involve setting request headers, parameters (query, path, form), authentication details, and the request body. Essentially, it defines "what we have" or "what needs to be in place" for the test to run.

*   **`when()`**: This block describes the action or event being tested. It specifies the HTTP method (GET, POST, PUT, DELETE, PATCH) and the endpoint (URI) to which the request is sent. This is the "what we do" part, representing the interaction with the API.

*   **`then()`**: This block verifies the expected outcomes after the API request has been executed. It contains assertions about the response, such as status codes, headers, and the response body. This is the "what we expect" or "what should happen" part, ensuring the API behaves as intended.

The fluent and chaining nature of this syntax allows for very concise and expressive tests.

### Importing Static Methods
To use `given()`, `when()`, and `then()` directly without prefixing them with `RestAssured.`, you need to import them statically:
`import static io.restassured.RestAssured.*;`

This makes your test code cleaner and more readable, aligning with the BDD philosophy.

## Code Implementation

Let's consider an example of testing a simple `GET` API that returns a list of users.

```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*; // For powerful assertions

public class BDDStyleApiTest {

    // Base URI for the API. It's good practice to set this up once.
    private static final String BASE_URI = "https://jsonplaceholder.typicode.com";

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = BASE_URI;
        // Optionally, you can set common request specifications like content type
        // RestAssured.requestSpecification = new RequestSpecBuilder()
        //     .setContentType(ContentType.JSON)
        //     .build();
    }

    /**
     * Test to verify fetching all users successfully.
     * Demonstrates a basic GET request with status code and body assertions.
     */
    @Test
    public void testGetAllUsers() {
        given()
            // No specific preconditions like headers or parameters for this simple GET
        .when()
            .get("/users") // Perform the GET request to the /users endpoint
        .then()
            .statusCode(200) // Assert that the status code is 200 (OK)
            .body("size()", greaterThan(0)) // Assert that the response body is a list with more than 0 items
            .body("[0].id", equalTo(1)) // Assert that the first user's ID is 1
            .body("[0].name", is(notNullValue())); // Assert that the first user's name is not null
    }

    /**
     * Test to verify fetching a single user by ID.
     * Demonstrates path parameter usage and more specific body assertions.
     */
    @Test
    public void testGetSingleUserById() {
        int userId = 5; // The ID of the user we want to fetch

        given()
            .pathParam("id", userId) // Set a path parameter named "id" with value userId
        .when()
            .get("/users/{id}") // Perform the GET request, {id} will be replaced by pathParam
        .then()
            .statusCode(200) // Assert status code is 200
            .body("id", equalTo(userId)) // Assert the 'id' field in the response matches the requested userId
            .body("name", equalTo("Chelsey Dietrich")) // Assert specific data for the user
            .body("email", endsWith("@outlook.com")); // Demonstrate another Hamcrest matcher
    }

    /**
     * Test to verify creating a new user (POST request).
     * Demonstrates sending a request body and asserting creation status.
     */
    @Test
    public void testCreateNewUser() {
        String requestBody = "{
" +
                             "    "name": "Gemini CLI User",
" +
                             "    "username": "geminichat",
" +
                             "    "email": "gemini.user@example.com"
" +
                             "}";

        given()
            .header("Content-Type", "application/json") // Specify content type of the request body
            .body(requestBody) // Set the request body
        .when()
            .post("/users") // Perform the POST request to create a user
        .then()
            .statusCode(201) // Assert status code is 201 (Created)
            .body("id", notNullValue()) // Assert that a new ID is assigned
            .body("name", equalTo("Gemini CLI User")); // Verify the name sent in the request is reflected
    }

    /**
     * Test to verify a non-existent endpoint or resource.
     * Demonstrates error handling assertions.
     */
    @Test
    public void testResourceNotFound() {
        given()
        .when()
            .get("/nonexistent-endpoint") // Request a path that does not exist
        .then()
            .statusCode(404) // Assert status code is 404 (Not Found)
            .body(emptyOrNullString()); // Assert the body is empty or null for a 404
    }
}
```

## Best Practices
-   **Static Imports**: Always use `import static io.restassured.RestAssured.*` and `import static org.hamcrest.Matchers.*` to make your tests more concise and readable.
-   **Base URI Setup**: Configure `RestAssured.baseURI` in a `@BeforeClass` or `@BeforeSuite` method to avoid repetition across tests.
-   **Clear Separation**: Keep `given`, `when`, and `then` distinct. Avoid mixing setup logic in `when` or `then` blocks.
-   **Meaningful Assertions**: Use Hamcrest matchers (`equalTo`, `hasItems`, `notNullValue`, `greaterThan`, etc.) for powerful and readable assertions in the `then()` block.
-   **Scenario-Based Naming**: Name your test methods descriptively (e.g., `testGetAllUsers`, `testGetSingleUserById`) to reflect the scenario being tested.
-   **Request/Response Logging**: For debugging, use `.log().all()` in `given()`, `when()`, or `then()` to print request/response details. Be mindful not to leave this in production code.

## Common Pitfalls
-   **Missing Static Imports**: Forgetting `import static io.restassured.RestAssured.*` will force you to use `RestAssured.given()`, `RestAssured.when()`, etc., which reduces readability.
-   **Overly Complex Test Steps**: Trying to test too many things in a single `then()` block can make tests brittle and hard to debug. Break down complex assertions.
-   **Hardcoding Values**: Avoid hardcoding values (like user IDs or specific data) in your tests. Use variables, parameters, or test data factories for better maintainability.
-   **Ignoring Error Scenarios**: Only testing "happy paths" leaves a significant gap. Always include tests for invalid inputs, unauthorized access, and resource not found scenarios.
-   **Lack of Readability in Request Bodies**: For complex `POST` or `PUT` requests, building JSON bodies as raw strings can be cumbersome. Consider using POJOs (Plain Old Java Objects) with libraries like Jackson or GSON for better serialization/deserialization.

## Interview Questions & Answers
1.  **Q: Explain the benefits of using BDD-style syntax (`given`, `when`, `then`) in API testing with REST Assured.**
    **A:** The primary benefit is enhanced readability and collaboration. It structures tests to mimic natural language (like user stories), making them easily understandable by both technical and non-technical team members. This improves communication, reduces ambiguity, and ensures that tests accurately reflect business requirements. It also promotes a clear separation of concerns: setup (given), action (when), and verification (then).

2.  **Q: How do you handle path parameters and query parameters using REST Assured's BDD syntax? Provide an example.**
    **A:**
    *   **Path Parameters**: Used within the `given()` block with `pathParam("paramName", value)`. The corresponding placeholder in the URL (e.g., `{paramName}`) will be replaced.
        Example: `given().pathParam("id", 1).when().get("/users/{id}").then()...`
    *   **Query Parameters**: Also used within the `given()` block with `queryParam("paramName", value)`. These are appended to the URL as `?paramName=value`.
        Example: `given().queryParam("name", "John").when().get("/users").then()...`

3.  **Q: What is Hamcrest and why is it commonly used with REST Assured for assertions?**
    **A:** Hamcrest is a framework for writing matcher objects, which allows for highly expressive and flexible assertions. REST Assured integrates seamlessly with Hamcrest in its `then().body()` method. It provides a rich set of matchers (e.g., `equalTo`, `containsString`, `hasItems`, `greaterThan`) that make assertions very readable, self-descriptive, and powerful, allowing complex validation of JSON or XML response bodies.

## Hands-on Exercise
**Exercise: Test a `PUT` request to update a user.**
Using the `https://jsonplaceholder.typicode.com` API:
1.  **Objective**: Write a test to update an existing user's information.
2.  **Steps**:
    *   Choose an existing user ID (e.g., `1`).
    *   Construct a JSON request body with updated `name` and `email` fields.
    *   Use `given()` to set the `Content-Type` header, path parameter, and the request body.
    *   Use `when()` to send a `PUT` request to `/users/{id}`.
    *   Use `then()` to assert:
        *   The status code is `200 OK`.
        *   The response body reflects the updated `name` and `email`.
        *   The `id` in the response body matches the ID you sent.

## Additional Resources
-   **REST Assured Official Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Hamcrest Tutorial**: [http://hamcrest.org/JavaHamcrest/tutorial](http://hamcrest.org/JavaHamcrest/tutorial)
-   **JSONPlaceholder API**: [https://jsonplaceholder.typicode.com/](https://jsonplaceholder.typicode.com/)
---
# api-4.1-ac3.md

# HTTP Methods Testing with REST Assured

## Overview
API testing is crucial for ensuring the reliability and functionality of web services. A fundamental aspect of RESTful APIs involves different HTTP methods, each serving a specific purpose in interacting with resources. This document covers how to effectively test all standard HTTP methods—GET, POST, PUT, PATCH, and DELETE—using REST Assured, a popular Java library for simplifying API testing. Understanding and thoroughly testing these operations ensures that your API behaves as expected across various data manipulations.

## Detailed Explanation

RESTful APIs are built around a set of stateless operations, primarily defined by HTTP methods, which act upon resources identified by URLs.

*   **GET**: Used to retrieve data from a specified resource. It should only retrieve data and have no other effect on the data. GET requests are idempotent and safe.
*   **POST**: Used to send data to a server to create a new resource. The new resource is usually created under the URI of the parent resource, and the server assigns it a unique ID. POST requests are neither idempotent nor safe.
*   **PUT**: Used to update an existing resource or create a new one if it doesn't exist, at a specified URI. PUT requests are idempotent; multiple identical PUT requests should have the same effect as a single one (though the response might differ).
*   **PATCH**: Used to apply partial modifications to a resource. Unlike PUT, which replaces the entire resource, PATCH applies only the changes indicated in the request body. PATCH requests are neither idempotent nor safe.
*   **DELETE**: Used to request the removal of a specified resource. DELETE requests are idempotent.

## Code Implementation

Let's use `ReqRes` (https://reqres.in/) as our sample API for demonstration. This API provides endpoints for various HTTP methods, making it ideal for learning.

First, ensure you have the necessary Maven/Gradle dependencies for REST Assured and TestNG (or JUnit).

**Maven Dependencies:**
```xml
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>rest-assured</artifactId>
    <version>5.3.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testng</groupId>
    <artifactId>testng</artifactId>
    <version>7.8.0</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.15.2</version>
    <scope>test</scope>
</dependency>
```

**Java Test Class:**

```java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;
import java.util.Map;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

public class HttpMethodsTest {

    private static final String BASE_URI = "https://reqres.in/api";

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = BASE_URI;
    }

    @Test(priority = 1)
    public void testGetUsers() {
        System.out.println("--- Executing GET Request ---");
        given()
            .when()
                .get("/users?page=2")
            .then()
                .log().body() // Log the response body for inspection
                .statusCode(200)
                .contentType(ContentType.JSON)
                .body("page", equalTo(2))
                .body("data[0].id", equalTo(7))
                .body("data.first_name", hasItems("Michael", "Lindsay", "Tobias"));
        System.out.println("--- GET Request Passed ---");
    }

    @Test(priority = 2)
    public void testPostCreateUser() {
        System.out.println("--- Executing POST Request ---");
        Map<String, Object> newUser = new HashMap<>();
        newUser.put("name", "morpheus");
        newUser.put("job", "leader");

        given()
                .contentType(ContentType.JSON)
                .body(newUser)
            .when()
                .post("/users")
            .then()
                .log().body()
                .statusCode(201) // 201 Created
                .body("name", equalTo("morpheus"))
                .body("job", equalTo("leader"))
                .body("id", notNullValue())
                .body("createdAt", notNullValue());
        System.out.println("--- POST Request Passed ---");
    }

    @Test(priority = 3)
    public void testPutUpdateUser() {
        System.out.println("--- Executing PUT Request ---");
        Map<String, Object> updatedUser = new HashMap<>();
        updatedUser.put("name", "morpheus");
        updatedUser.put("job", "zion resident");

        given()
                .contentType(ContentType.JSON)
                .body(updatedUser)
            .when()
                .put("/users/2") // User with ID 2
            .then()
                .log().body()
                .statusCode(200) // 200 OK
                .body("name", equalTo("morpheus"))
                .body("job", equalTo("zion resident"))
                .body("updatedAt", notNullValue());
        System.out.println("--- PUT Request Passed ---");
    }

    @Test(priority = 4)
    public void testPatchUpdateUser() {
        System.out.println("--- Executing PATCH Request ---");
        Map<String, Object> partialUpdate = new HashMap<>();
        partialUpdate.put("job", "tester"); // Only updating the job

        given()
                .contentType(ContentType.JSON)
                .body(partialUpdate)
            .when()
                .patch("/users/2") // User with ID 2
            .then()
                .log().body()
                .statusCode(200) // 200 OK
                .body("job", equalTo("tester"))
                .body("updatedAt", notNullValue());
        System.out.println("--- PATCH Request Passed ---");
    }

    @Test(priority = 5)
    public void testDeleteUser() {
        System.out.println("--- Executing DELETE Request ---");
        given()
            .when()
                .delete("/users/2") // User with ID 2
            .then()
                .log().all() // Log all details (request and response)
                .statusCode(204); // 204 No Content
        System.out.println("--- DELETE Request Passed ---");
    }

    @Test(priority = 6)
    public void testGetNonExistentUser() {
        System.out.println("--- Executing GET for non-existent user ---");
        given()
            .when()
                .get("/users/9999") // A user ID that likely doesn't exist
            .then()
                .log().body()
                .statusCode(404); // 404 Not Found
        System.out.println("--- GET Non-Existent User Passed ---");
    }
}
```

## Best Practices
-   **Use `given().when().then()` structure**: This BDD-style syntax makes tests highly readable and organized.
-   **Log requests and responses**: Use `log().all()`, `log().body()`, `log().headers()`, etc., for debugging and clear test reporting. Be mindful of sensitive data in production.
-   **Parameterization**: Avoid hardcoding values. Use parameters for base URIs, endpoints, and test data to make tests flexible and reusable.
-   **Clear Assertions**: Assert on status codes, response body content (using Hamcrest matchers), headers, and response time.
-   **Idempotency and Safety**: Understand which HTTP methods are idempotent (GET, PUT, DELETE) and safe (GET, HEAD, OPTIONS, TRACE) and design tests accordingly.
-   **Error Handling**: Include tests for expected error scenarios, such as 404 Not Found, 401 Unauthorized, 400 Bad Request, etc.
-   **Payload Construction**: Use `Map` or Pojo (Plain Old Java Object) for complex JSON request bodies. Jacksondatabind is excellent for converting Java objects to JSON and vice-versa.

## Common Pitfalls
-   **Confusing PUT and PATCH**: PUT replaces the entire resource, while PATCH applies partial updates. Using the wrong one can lead to unintended data loss or incorrect updates.
-   **Missing `Content-Type` Header**: For POST, PUT, and PATCH requests, failing to set `Content-Type: application/json` (or appropriate content type) can lead to the server rejecting the request.
-   **Inadequate Assertions**: Just checking the status code is not enough. Always verify the response body, headers, and any other relevant data to confirm the API's behavior.
-   **Hardcoding Base URI/Path**: This makes tests difficult to manage and update across different environments (dev, staging, production). Use `RestAssured.baseURI` and `RestAssured.basePath`.
-   **Ignoring Negative Scenarios**: Only testing successful cases leaves gaps. Always test what happens when invalid data is sent, required parameters are missing, or unauthorized access is attempted.

## Interview Questions & Answers

1.  **Q: Explain the difference between PUT and PATCH HTTP methods.**
    **A:** **PUT** is used to replace an entire resource. If a resource exists, PUT updates it with the entire body provided in the request. If the resource does not exist at the specified URI, PUT might create it. It is idempotent, meaning multiple identical PUT requests will result in the same state on the server. **PATCH** is used for partial modifications to a resource. It applies only the changes specified in the request body, leaving other parts of the resource untouched. It is not necessarily idempotent.

2.  **Q: How do you handle different types of authentication (e.g., Basic, OAuth2, API Key) in REST Assured?**
    **A:** REST Assured provides various ways to handle authentication:
    *   **Basic Authentication**: `given().auth().preemptive().basic("username", "password")`
    *   **OAuth2**: `given().auth().oauth2("accessToken")`
    *   **API Key**: Often sent as a header: `given().header("X-API-Key", "your-api-key")` or as a query parameter: `given().queryParam("api_key", "your-api-key")`.
    *   **Digest Authentication**: `given().auth().digest("username", "password")`

3.  **Q: What are the common assertions you would make in API tests for each HTTP method?**
    **A:**
    *   **GET**: Assert status code 200 (OK), content type (e.g., JSON), specific fields in the response body, array size, absence of sensitive data.
    *   **POST**: Assert status code 201 (Created) or 200 (OK), content type, that the newly created resource's ID is not null, and that the request body data is reflected in the response.
    *   **PUT/PATCH**: Assert status code 200 (OK), content type, that the updated fields reflect the changes, and `updatedAt` timestamps (if applicable) are recent.
    *   **DELETE**: Assert status code 204 (No Content) or 200 (OK), and then ideally perform a subsequent GET request for the deleted resource to confirm it returns 404 (Not Found).

## Hands-on Exercise
Choose another public API (e.g., JSONPlaceholder: `https://jsonplaceholder.typicode.com/`) and write a comprehensive test suite for a specific resource (e.g., `/posts` or `/comments`). Ensure your tests cover:
1.  Fetching a list of resources (GET).
2.  Fetching a single resource by ID (GET).
3.  Creating a new resource (POST).
4.  Updating an existing resource (PUT and/or PATCH).
5.  Deleting a resource (DELETE), followed by a GET to verify deletion.
Include error handling tests for scenarios like invalid IDs or malformed requests.

## Additional Resources
-   **REST Assured Official Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **HTTP Methods - MDN Web Docs**: [https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods)
-   **ReqRes API**: [https://reqres.in/](https://reqres.in/)
-   **JSONPlaceholder API**: [https://jsonplaceholder.typicode.com/](https://jsonplaceholder.typicode.com/)
---
# api-4.1-ac4.md

# Status Code Validation in REST Assured

## Overview
Status codes are a fundamental part of the HTTP protocol, indicating the outcome of an API request. Validating these codes is a critical step in API testing to ensure that the server responds as expected under various scenarios (success, client errors, server errors, etc.). REST Assured provides a straightforward and powerful way to assert HTTP status codes, making it an indispensable tool for robust API automation. This document covers how to validate common status codes like 200 (OK), 201 (Created), 400 (Bad Request), 404 (Not Found), and 500 (Internal Server Error).

## Detailed Explanation

HTTP status codes are three-digit integers grouped into five classes:
*   **1xx Informational:** Request received, continuing process.
*   **2xx Success:** The action was successfully received, understood, and accepted.
*   **3xx Redirection:** Further action needs to be taken to complete the request.
*   **4xx Client Error:** The request contains bad syntax or cannot be fulfilled.
*   **5xx Server Error:** The server failed to fulfill an apparently valid request.

In API testing, we primarily focus on `2xx`, `4xx`, and `5xx` codes. REST Assured's `statusCode()` matcher allows us to assert these codes directly.

### Common Status Codes and Their Usage in Testing:

*   **200 OK:** Indicates that the request has succeeded. This is the most common successful response.
    *   *Testing Scenario:* A successful GET request to retrieve resources.
*   **201 Created:** The request has been fulfilled and resulted in a new resource being created.
    *   *Testing Scenario:* A successful POST request to create a new resource.
*   **400 Bad Request:** The server cannot or will not process the request due to something that is perceived to be a client error (e.g., malformed request syntax, invalid request message framing, or deceptive request routing).
    *   *Testing Scenario:* Sending a POST/PUT request with invalid or missing mandatory fields.
*   **404 Not Found:** The server cannot find the requested resource. Links that lead to a 404 page are often called broken or dead links.
    *   *Testing Scenario:* Attempting to retrieve, update, or delete a resource that does not exist using an invalid ID.
*   **500 Internal Server Error:** A generic error message, given when an unexpected condition was encountered and no more specific message is suitable.
    *   *Testing Scenario:* Simulating server-side issues (e.g., through invalid parameters that cause an unhandled exception on the server) or testing system resilience.

## Code Implementation

Let's illustrate status code validation with practical REST Assured examples. We'll use a hypothetical API endpoint for `users`.

First, ensure you have the necessary REST Assured dependencies in your `pom.xml` (for Maven) or `build.gradle` (for Gradle).

```xml
<!-- Maven pom.xml -->
<dependencies>
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <version>5.3.0</version>
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
</dependencies>
```

```java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

public class StatusCodeValidationTest {

    private static final String BASE_URL = "https://reqres.in/api"; // Using a public test API

    @BeforeAll
    public static void setup() {
        RestAssured.baseURI = BASE_URL;
    }

    @Test
    public void testStatusCode200_Success() {
        // Test a successful GET request, expecting 200 OK
        given()
            .when()
                .get("/users?page=2") // Endpoint that should return 200 OK
            .then()
                .statusCode(200) // Assert the status code is 200
                .log().body(); // Log the response body for debugging
    }

    @Test
    public void testStatusCode201_ResourceCreation() {
        // Test a successful POST request for resource creation, expecting 201 Created
        String requestBody = "{"name": "morpheus", "job": "leader"}";

        given()
            .contentType(ContentType.JSON) // Set content type for request body
            .body(requestBody) // Attach the JSON request body
            .when()
                .post("/users") // Endpoint for creating a user
            .then()
                .statusCode(201) // Assert the status code is 201
                .body("name", equalTo("morpheus")) // Optionally, validate response body
                .body("job", equalTo("leader"))
                .log().body();
    }

    @Test
    public void testStatusCode400_BadRequest() {
        // Test a POST request with invalid data, expecting 400 Bad Request
        // Note: reqres.in might return 200 for invalid POST, so this example is conceptual
        // For a real API, you'd send an invalid request (e.g., missing mandatory field)
        String invalidRequestBody = "{"invalid_field": "value"}"; // Missing 'name' and 'job'

        given()
            .contentType(ContentType.JSON)
            .body(invalidRequestBody)
            .when()
                .post("/register") // Using a /register endpoint that might return 400 for bad input
            .then()
                // On reqres.in, this might return 200 with an error message in body.
                // For a truly robust test, you'd need an API that explicitly returns 400.
                .statusCode(anyOf(equalTo(400), equalTo(200))) // Adjust based on API behavior
                // If it returns 200 with an error, you'd check the error message in the body
                .log().body();
    }

    @Test
    public void testStatusCode404_NotFound() {
        // Test a GET request for a non-existent resource, expecting 404 Not Found
        given()
            .when()
                .get("/users/99999") // User with ID 99999 unlikely to exist
            .then()
                .statusCode(404) // Assert the status code is 404
                .log().body();
    }

    @Test
    public void testStatusCode500_InternalServerErrorSimulation() {
        // Simulating a 500 Internal Server Error.
        // Public APIs rarely provide endpoints that intentionally throw 500 errors
        // via client-side input. For real-world scenarios, this would involve:
        // 1. Calling an endpoint with parameters known to cause server errors.
        // 2. Setting up a mock server that returns 500.
        // 3. Directly testing server-side logic that generates 500s.

        // This is a conceptual example as reqres.in doesn't have an endpoint to trigger 500 easily.
        // If an endpoint `/simulate-error` existed which is designed to fail with 500:
        given()
            .when()
                .get("/nonexistent-endpoint-to-force-error") // A URL that is likely to fail
            .then()
                .statusCode(anyOf(equalTo(500), equalTo(404))) // Adjust based on specific endpoint behavior
                .log().body();

        System.out.println("Note: Simulating 500 requires an API endpoint designed to return it, or a mock server.");
        System.out.println("The above example for 500 might return 404 if the endpoint just doesn't exist.");
    }
}
```

## Best Practices
-   **Use Descriptive Test Names:** Make test method names reflect the scenario and expected status code (e.g., `testStatusCode200_Success`).
-   **Parameterize Tests:** For endpoints that can return various error codes based on different inputs (e.g., 400 for invalid data, 401 for unauthorized, 403 for forbidden), use parameterized tests to cover all relevant scenarios efficiently.
-   **Combine with Body Assertions:** Always combine status code validation with assertions on the response body, especially for error cases, to verify the error message or structure.
-   **Avoid Hardcoding:** Use configuration files or environment variables for `BASE_URI` to easily switch between environments (dev, staging, prod).
-   **Test Negative Scenarios Thoroughly:** Explicitly test for `4xx` and `5xx` status codes to ensure your API handles errors gracefully and provides meaningful error messages.

## Common Pitfalls
-   **Ignoring Response Body for Errors:** Just checking the status code for `4xx` or `5xx` is insufficient. The response body often contains critical information about *why* the error occurred. Always inspect it.
-   **Assuming 200 for All Successes:** While 200 is common, `201 Created` (for POST), `202 Accepted` (for asynchronous processing), `204 No Content` (for successful DELETE), etc., are also success codes. Use the appropriate one.
-   **Not Handling Network Issues:** Status code validation primarily deals with API responses. Network issues (connection refused, timeouts) might manifest differently before a status code is even received. These require different handling (e.g., `try-catch` blocks or specific timeout configurations).
-   **Over-reliance on `statusCode(200)`:** Some APIs might return `200 OK` even for logical errors, with the actual error details in the response body. Always cross-check with body assertions.

## Interview Questions & Answers
1.  **Q: Why is validating HTTP status codes crucial in API testing?**
    **A:** Validating status codes is crucial because they are the primary indicator of the API's operational outcome. They tell us immediately if a request succeeded, if there was a client-side error, or a server-side error. This ensures that the API behaves as per its contract, handles valid inputs correctly, and gracefully manages invalid inputs or unexpected server conditions. Without status code validation, a test might pass even if the API returned an error, leading to false positives.

2.  **Q: Can an API return a 200 status code but still indicate an error? How would you test for this?**
    **A:** Yes, this is a common anti-pattern, especially in older or less-RESTful APIs. An API might return `200 OK` but include an error message, an error code, or an empty/malformed data structure within the JSON/XML response body.
    To test for this, you would:
    *   First, assert the `statusCode(200)`.
    *   Then, you would perform additional assertions on the response body to check for the presence of specific error fields (e.g., `"error": true`, `"errorCode": "some_code"`) or the absence of expected success data. For example: `body("status", equalTo("failure"))` or `body("data", is(empty()))`.

3.  **Q: How do you differentiate between 4xx and 5xx errors, and what are their implications for testing?**
    **A:**
    *   **4xx (Client Error):** These indicate that the client's request was somehow flawed (e.g., bad syntax, missing authentication, non-existent resource). From a testing perspective, 4xx errors usually mean the test itself provided invalid input or made an incorrect request. Tests for 4xx errors are often positive tests for *error handling capabilities*, ensuring the API correctly rejects bad requests.
    *   **5xx (Server Error):** These indicate that the server failed to fulfill a valid request. This points to an issue on the server side (e.g., database down, internal application error, unhandled exception). From a testing perspective, 5xx errors typically signify a bug in the API's implementation or infrastructure. Testing for 5xx often involves simulating extreme conditions or specific edge cases that might expose server vulnerabilities, or verifying that the server provides minimal information in public responses (to prevent information leakage).

## Hands-on Exercise
1.  **Setup a Mock API:** Use a tool like WireMock, MockServer, or a public service like `jsonplaceholder.typicode.com` or `reqres.in`.
2.  **Create a Test Class:** Set up a new Java project with Maven/Gradle and add REST Assured and JUnit 5 dependencies.
3.  **Write Tests for Each Scenario:**
    *   Write a test that makes a GET request to a valid endpoint and asserts a `200 OK`.
    *   Write a test that makes a POST request to create a resource and asserts a `201 Created`.
    *   Write a test that makes a GET request to a non-existent resource (e.g., `/users/nonexistentid`) and asserts a `404 Not Found`.
    *   *Challenge (Optional):* If you can configure your mock server or find a public API that explicitly returns `400 Bad Request` for malformed input, write a test for that. Otherwise, simulate it conceptually.

## Additional Resources
-   **REST Assured Official Documentation:** [https://rest-assured.io/](https://rest-assured.io/)
-   **HTTP Status Codes (MDN Web Docs):** [https://developer.mozilla.org/en-US/docs/Web/HTTP/Status](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
-   **JUnit 5 Official Documentation:** [https://junit.org/junit5/docs/current/user-guide/](https://junit.org/junit5/docs/current/user-guide/)
---
# api-4.1-ac5.md

# Extract and Validate Response Body using JsonPath in REST Assured

## Overview
In the realm of API testing, validating the response body is paramount to ensure that the API returns the correct data. REST Assured, a popular Java library for testing RESTful APIs, provides powerful mechanisms for parsing and asserting JSON and XML response bodies. One of the most effective ways to navigate and extract data from JSON responses is by using **JsonPath**. This feature allows testers to pinpoint specific elements within a complex JSON structure, enabling robust and flexible validation. Understanding JsonPath is crucial for any SDET working with RESTful APIs, as it directly impacts the reliability and maintainability of API automation tests.

## Detailed Explanation

JsonPath is an expression language for JSON, similar to XPath for XML. It allows you to select and extract data from a JSON document. REST Assured integrates JsonPath seamlessly, providing methods to parse the response and extract values using JsonPath expressions.

### Key Concepts

1.  **Root Element (`$`):** Represents the root of the JSON document.
2.  **Dot Notation (`.`)**: Used to access properties of an object. E.g., `$.store.book`.
3.  **Bracket Notation (`[]`)**:
    *   Used to access array elements by index. E.g., `$.store.book[0]`.
    *   Used to access properties with special characters or dynamic names. E.g., `$.['store-name']`.
4.  **Wildcard (`*`)**: Matches all elements in an object or array. E.g., `$.store.book[*]`.
5.  **Filters (`?()`)**: Allows filtering elements in an array based on a condition. E.g., `$.store.book[?(@.price < 10)]`. The `@` symbol refers to the current item being processed.

### REST Assured Integration

REST Assured offers two primary ways to use JsonPath for extraction and validation:

1.  `extract().path("jsonPathExpression")`: Directly extracts a value from the response body after a request has been made. This is useful when you need to store the extracted value for further operations or assertions.
2.  `jsonPath().getString("jsonPathExpression")` or `jsonPath().getObject("jsonPathExpression", Class.class)`: This method is called on the `JsonPath` object itself, which can be obtained from the response. It's often used when you want to work with the `JsonPath` object independently or perform multiple extractions.

### Examples

Let's consider a sample JSON response:

```json
{
  "store": {
    "name": "Gemini Books",
    "address": {
      "street": "123 Main St",
      "city": "Anytown",
      "zip": "12345"
    },
    "books": [
      {
        "category": "fiction",
        "author": "J.K. Rowling",
        "title": "Harry Potter",
        "price": 15.99
      },
      {
        "category": "science",
        "author": "Carl Sagan",
        "title": "Cosmos",
        "price": 12.50
      },
      {
        "category": "fiction",
        "author": "Jane Austen",
        "title": "Pride and Prejudice",
        "price": 9.99
      }
    ]
  },
  "manager": "Alice Smith",
  "totalValue": 38.48
}
```

## Code Implementation

```java
import io.restassured.RestAssured;
import io.restassured.path.json.JsonPath;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static io.restassured.RestAssured.given;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class JsonPathValidationTests {

    // Dummy endpoint for demonstration. In a real scenario, this would be a live API.
    // For this example, we'll simulate a response body directly.
    private static final String SAMPLE_JSON_RESPONSE = """
            {
              "store": {
                "name": "Gemini Books",
                "address": {
                  "street": "123 Main St",
                  "city": "Anytown",
                  "zip": "12345"
                },
                "books": [
                  {
                    "category": "fiction",
                    "author": "J.K. Rowling",
                    "title": "Harry Potter",
                    "price": 15.99
                  },
                  {
                    "category": "science",
                    "author": "Carl Sagan",
                    "title": "Cosmos",
                    "price": 12.50
                  },
                  {
                    "category": "fiction",
                    "author": "Jane Austen",
                    "title": "Pride and Prejudice",
                    "price": 9.99
                  }
                ]
              },
              "manager": "Alice Smith",
              "totalValue": 38.48
            }
            """;

    // In a real test, you would hit an actual endpoint:
    // @BeforeAll
    // public static void setup() {
    //     RestAssured.baseURI = "http://api.example.com";
    // }

    @Test
    void testExtractStoreNameUsingPath() {
        // Simulating a response for demonstration purposes
        Response response = given().body(SAMPLE_JSON_RESPONSE).when().post("/dummy"); // No actual call made

        // Extracting a simple field using extract().path()
        String storeName = response.extract().path("store.name");
        assertEquals("Gemini Books", storeName, "Store name should be 'Gemini Books'");
    }

    @Test
    void testExtractCityUsingJsonPathObject() {
        // Get JsonPath object from the response body
        JsonPath jsonPathEvaluator = JsonPath.from(SAMPLE_JSON_RESPONSE);

        // Extracting a nested field using getString()
        String city = jsonPathEvaluator.getString("store.address.city");
        assertEquals("Anytown", city, "City should be 'Anytown'");
    }

    @Test
    void testExtractFirstBookTitle() {
        JsonPath jsonPathEvaluator = JsonPath.from(SAMPLE_JSON_RESPONSE);

        // Extracting an element from an array by index
        String firstBookTitle = jsonPathEvaluator.getString("store.books[0].title");
        assertEquals("Harry Potter", firstBookTitle, "First book title should be 'Harry Potter'");
    }

    @Test
    void testExtractAllBookTitles() {
        JsonPath jsonPathEvaluator = JsonPath.from(SAMPLE_JSON_RESPONSE);

        // Extracting all values for a field from an array
        List<String> bookTitles = jsonPathEvaluator.getList("store.books.title");
        assertThat(bookTitles, containsInAnyOrder("Harry Potter", "Cosmos", "Pride and Prejudice"));
        assertEquals(3, bookTitles.size(), "There should be 3 book titles");
    }

    @Test
    void testExtractBooksByFilterCondition() {
        JsonPath jsonPathEvaluator = JsonPath.from(SAMPLE_JSON_RESPONSE);

        // Extracting books that match a condition (price < 10)
        List<Map<String, Object>> cheapBooks = jsonPathEvaluator.getList("store.books.findAll { it.price < 10 }");
        assertEquals(1, cheapBooks.size(), "There should be one book cheaper than 10");
        assertEquals("Pride and Prejudice", cheapBooks.get(0).get("title"));

        // Extracting titles of books cheaper than 10
        List<String> cheapBookTitles = jsonPathEvaluator.getList("store.books.findAll { it.price < 10 }.title");
        assertThat(cheapBookTitles, contains("Pride and Prejudice"));
    }

    @Test
    void testValidateManagerNameUsingHamcrest() {
        given().body(SAMPLE_JSON_RESPONSE).when().post("/dummy")
                .then()
                .assertThat()
                .body("manager", equalTo("Alice Smith")); // Direct validation using Hamcrest matcher
    }

    @Test
    void testValidateNestedFieldUsingDotNotation() {
        given().body(SAMPLE_JSON_RESPONSE).when().post("/dummy")
                .then()
                .assertThat()
                .body("store.address.zip", equalTo("12345"));
    }

    @Test
    void testValidateArraySize() {
        given().body(SAMPLE_JSON_RESPONSE).when().post("/dummy")
                .then()
                .assertThat()
                .body("store.books", hasSize(3));
    }

    @Test
    void testValidateExistenceOfField() {
        given().body(SAMPLE_JSON_RESPONSE).when().post("/dummy")
                .then()
                .assertThat()
                .body("totalValue", notNullValue());
    }
}
```

## Best Practices
-   **Use Specific JsonPath Expressions:** Always aim for the most specific JsonPath expression to avoid unintended matches, especially in large and complex JSON structures.
-   **Parameterize Expressions:** For reusable tests, parameterize your JsonPath expressions or parts of them to make your tests more dynamic and maintainable.
-   **Combine with Hamcrest Matchers:** REST Assured's `body()` method integrates beautifully with Hamcrest matchers, allowing for expressive and readable assertions directly within the `then()` block.
-   **Handle Null/Missing Values Gracefully:** When extracting values, be aware that a JsonPath expression might not always return a value (e.g., if the field is optional or missing). Use appropriate checks or default values to prevent `NullPointerException`s.
-   **Keep JSON Structure in Mind:** Always have a clear understanding of the JSON response structure you are working with. Visualizing the JSON (e.g., using a JSON formatter) can help in writing correct JsonPath expressions.

## Common Pitfalls
-   **Incorrect Path Syntax:** A common mistake is typos or incorrect syntax in JsonPath expressions (e.g., missing dots, wrong brackets, or case sensitivity issues). Always double-check your paths.
-   **Assuming Array Order:** Unless explicitly required, avoid relying on the order of elements in a JSON array if the API contract doesn't guarantee it. Use `containsInAnyOrder` for lists if order isn't important.
-   **Over-extracting Data:** Don't extract more data than you need for a specific assertion. This can make tests slower and harder to read.
-   **Not Handling Dynamic Keys:** If your JSON response has dynamic keys (e.g., `item-1`, `item-2`), simple dot notation won't work. You'll need to use more advanced JsonPath features or iterate through the keys.
-   **Ignoring Error Responses:** Even error responses can contain valuable JSON bodies. Ensure your JsonPath logic is robust enough to handle different response types, including errors.

## Interview Questions & Answers
1.  **Q: What is JsonPath and why is it important in API testing with REST Assured?**
    **A:** JsonPath is a query language for JSON that allows you to select and extract specific elements from a JSON document. In API testing with REST Assured, it's crucial for efficiently parsing complex JSON response bodies and asserting specific data points without having to deserialize the entire JSON into Java objects. This makes tests more concise, readable, and less prone to breaking if the JSON structure changes in unrelated parts.

2.  **Q: Explain the difference between `extract().path()` and `jsonPath().getString()` in REST Assured.**
    **A:** Both are used for extracting values using JsonPath.
    *   `extract().path("jsonPathExpression")`: This method is called directly on the `Response` object obtained after making a request. It's a convenient one-liner for extracting a single value and is part of the fluent API style.
    *   `jsonPath().getString("jsonPathExpression")`: This method is called on a `JsonPath` object, which is typically created using `JsonPath.from(responseBody)` or `response.jsonPath()`. It's useful when you need to perform multiple extractions from the same JSON response or if you want to work with the `JsonPath` object independently.

3.  **Q: How would you validate a nested field within an array of objects using JsonPath? Provide an example.**
    **A:** You can use a combination of array indexing (or filters) and dot notation.
    Example (referring to the sample JSON above): To validate the title of the second book:
    `response.then().body("store.books[1].title", equalTo("Cosmos"));`
    Or to find a book by a property and then get its title:
    `List<String> fictionBookTitles = jsonPathEvaluator.getList("store.books.findAll { it.category == 'fiction' }.title");`

4.  **Q: What are some common challenges you face when using JsonPath for response validation, and how do you overcome them?**
    **A:**
    *   **Complex JSON Structures:** Navigating deeply nested or highly dynamic JSON can be challenging. Overcome this by using JSON visualizers, breaking down paths into smaller segments, and starting with simpler paths before building complex ones.
    *   **Missing or Null Fields:** If a field might be absent or `null`, directly asserting its value can lead to errors. Overcome this by checking for `notNullValue()` first or by using `assertThat(value, is(nullValue()))` explicitly if null is an expected state.
    *   **Performance on Large Payloads:** For extremely large JSON payloads, repeated JsonPath parsing can be slow. In such cases, consider deserializing only the relevant parts into POJOs if performance becomes a bottleneck, or optimize your JsonPath expressions.

## Hands-on Exercise
**Scenario:** You are testing an e-commerce API that returns a list of products.

**JSON Response Example:**
```json
{
  "products": [
    {
      "id": "prod101",
      "name": "Laptop Pro",
      "category": "Electronics",
      "price": 1200.00,
      "inStock": true
    },
    {
      "id": "prod102",
      "name": "Mechanical Keyboard",
      "category": "Accessories",
      "price": 75.50,
      "inStock": false
    },
    {
      "id": "prod103",
      "name": "Wireless Mouse",
      "category": "Accessories",
      "price": 25.00,
      "inStock": true
    }
  ],
  "totalProducts": 3,
  "currency": "USD"
}
```

**Tasks:**
1.  Write a REST Assured test that asserts the `totalProducts` count is 3.
2.  Extract the `name` of the product with `id` "prod102" and assert it is "Mechanical Keyboard".
3.  Extract a list of all product names that are currently `inStock` and assert that the list contains "Laptop Pro" and "Wireless Mouse".
4.  Validate that the `currency` field exists and its value is "USD".

## Additional Resources
-   **REST Assured Official Documentation:** [https://rest-assured.io/](https://rest-assured.io/)
-   **JsonPath GitHub Repository:** [https://github.com/json-path/JsonPath](https://github.com/json-path/JsonPath) (Provides detailed syntax and examples)
-   **Baeldung Tutorial on REST Assured JsonPath:** [https://www.baeldung.com/rest-assured-jsonpath](https://www.baeldung.com/rest-assured-jsonpath)
---
# api-4.1-ac6.md

# REST Assured: Validating Response Headers, Cookies, and Response Time

## Overview
In API testing, beyond just validating the response body, it's crucial to ensure that the response metadata like headers, cookies, and the overall response time align with expected behavior and performance requirements. REST Assured provides a powerful and intuitive DSL (Domain Specific Language) for asserting these aspects, enabling comprehensive and robust API test automation. This document will cover how to validate headers, extract cookie values, and assert response times using REST Assured.

## Detailed Explanation

### 1. Validating Response Headers
Headers carry important metadata about the response, such as content type, caching instructions, server information, and more. Validating headers ensures the API is returning the correct format and adhering to security or architectural guidelines.

REST Assured allows direct assertions on header values using the `header()` method.

### 2. Extracting and Validating Cookies
Cookies are often used for session management, authentication, or tracking. In API testing, you might need to extract a cookie value to use in subsequent requests (e.g., a session ID) or simply validate its presence and value.

REST Assured provides `cookie()` methods for both direct assertion and extraction.

### 3. Asserting Response Time
Response time is a critical performance metric for APIs. Slow responses can lead to poor user experience or system bottlenecks. REST Assured allows you to set expectations on how quickly an API should respond, helping to catch performance regressions early in the development cycle.

The `time()` method, combined with matchers like `lessThan()`, is used for this purpose.

## Code Implementation

```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*; // For lessThan, containsString, equalTo, etc.
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Demonstrates how to validate response headers, extract cookies,
 * and assert response time using REST Assured.
 *
 * This example uses a publicly available API (e.g., https://reqres.in)
 * Please note that external API behavior can change.
 */
public class ApiResponseValidationTest {

    private static final String BASE_URI = "https://reqres.in/api";

    @BeforeAll
    public static void setup() {
        RestAssured.baseURI = BASE_URI;
        // Optionally configure logging for all requests/responses
        // RestAssured.filters(new RequestLoggingFilter(), new ResponseLoggingFilter());
    }

    @Test
    public void testValidateResponseHeaders() {
        System.out.println("--- Running testValidateResponseHeaders ---");
        given()
            .when()
                .get("/users?page=2")
            .then()
                .log().headers() // Log all response headers for debugging
                .statusCode(200)
                .header("Content-Type", equalTo("application/json; charset=utf-8")) // Exact match
                .header("Server", containsString("cloudflare")) // Partial match for server header
                .header("Cache-Control", containsString("max-age")) // Validate presence of a specific part
                .and() // 'and()' is optional, improves readability
                .header("Vary", notNullValue()); // Assert header exists
        System.out.println("--- testValidateResponseHeaders PASSED ---");
    }

    @Test
    public void testExtractAndValidateCookies() {
        System.out.println("--- Running testExtractAndValidateCookies ---");
        Response response = given()
            .when()
                .get("/users/2")
            .then()
                .log().cookies() // Log all response cookies
                .statusCode(200)
                .extract()
                .response();

        // Check if a specific cookie exists (if the API sets one)
        // Note: reqres.in generally doesn't set complex cookies on GET requests.
        // This is illustrative for APIs that do.
        String cfduidCookie = response.getCookie("__cfduid"); // Example cookie name
        if (cfduidCookie != null) {
            System.out.println("Extracted __cfduid cookie: " + cfduidCookie);
            assertNotNull(cfduidCookie, "Cookie __cfduid should not be null");
            assertTrue(cfduidCookie.length() > 0, "Cookie __cfduid should not be empty");
        } else {
            System.out.println("No __cfduid cookie found (as expected for this API).");
            // Example of how you might assert a cookie's absence if necessary:
            // given().when().get("/some-path").then().cookie("some_unexpected_cookie", nullValue());
        }

        // Another way to assert cookie existence and value directly in then() part
        // Example for an API that sets a simple cookie, e.g., session_id
        // given().when().get("/login").then().cookie("session_id", "abc123def456");
        // given().when().get("/login").then().cookie("session_id", notNullValue());
        System.out.println("--- testExtractAndValidateCookies PASSED ---");
    }

    @Test
    public void testAssertResponseTime() {
        System.out.println("--- Running testAssertResponseTime ---");
        long maxResponseTimeMs = 2000L; // Define maximum acceptable response time in milliseconds

        given()
            .when()
                .get("/users")
            .then()
                .statusCode(200)
                .time(lessThan(maxResponseTimeMs)); // Assert response time is less than 2000ms

        System.out.println("Response time is less than " + maxResponseTimeMs + "ms.");
        System.out.println("--- testAssertResponseTime PASSED ---");
    }

    @Test
    public void testAllValidationsCombined() {
        System.out.println("--- Running testAllValidationsCombined ---");
        Response response = given()
            .when()
                .get("/users/1")
            .then()
                .statusCode(200)
                .header("Content-Type", equalTo("application/json; charset=utf-8"))
                .cookie("PHPSESSID", nullValue()) // Assuming no PHPSESSID cookie is expected for this endpoint
                .time(lessThan(1500L)) // Expecting a faster response for a single resource
                .extract()
                .response();

        // Further cookie assertions if needed
        String actualCookie = response.getCookie("someOtherCookie");
        if (actualCookie != null) {
            System.out.println("Extracted someOtherCookie: " + actualCookie);
        } else {
            System.out.println("No 'someOtherCookie' found (expected).");
        }
        System.out.println("--- testAllValidationsCombined PASSED ---");
    }
}
```

## Best Practices
- **Be Specific with Headers**: When validating headers, be as specific as possible with the expected value or pattern. Use `equalTo()` for exact matches and `containsString()` for partial matches.
- **Dynamic Cookie Handling**: If cookie values are dynamic (e.g., session IDs), extract them and use them in subsequent requests rather than hardcoding.
- **Realistic Response Time Thresholds**: Set response time assertions based on realistic performance requirements and typical API behavior under load, not arbitrary numbers. Continuously monitor and adjust these thresholds.
- **Combine Assertions**: Leverage REST Assured's fluent API to chain multiple assertions for headers, cookies, and response time in a single test, improving readability and conciseness.
- **Consider Time Units**: Be mindful of the time unit when asserting response times (milliseconds, seconds, etc.). REST Assured's `time()` method defaults to milliseconds.

## Common Pitfalls
- **Over-specifying Headers**: Asserting too many headers or being too strict with dynamic header values (e.g., `Date`, `ETag`) can lead to flaky tests. Focus on critical headers.
- **Ignoring Cookie Security**: While validating, also consider cookie attributes like `HttpOnly`, `Secure`, and `SameSite` if security is a concern.
- **Unrealistic Performance Expectations**: Setting very low response time thresholds without proper performance testing environment can lead to false positives and unnecessary test failures.
- **Ambiguous Time Assertions**: Forgetting to add `lessThan()`, `greaterThan()`, etc., will cause the `time()` assertion to fail as it doesn't know the condition.
- **Network Flakiness**: Response time tests can be flaky due to network latency. Consider retries or running performance tests in a controlled environment.

## Interview Questions & Answers
1. Q: How would you validate that an API response is returning JSON content?
   A: We would assert the `Content-Type` header. Using REST Assured, we can do `header("Content-Type", equalTo("application/json; charset=utf-8"))` or a more flexible `header("Content-Type", containsString("application/json"))`.

2. Q: Describe a scenario where you would need to extract a cookie from an API response and what you would do with it.
   A: In an authentication flow, after a successful login API call, the server might send a session ID or authentication token in a cookie. I would extract this cookie (`response.getCookie("session_id")`) and then include it in the headers or as a cookie in subsequent authenticated API requests to maintain the user's session.

3. Q: Why is it important to test API response times, and what are some considerations when setting a response time threshold?
   A: Testing API response times is crucial for ensuring performance and scalability. Slow APIs degrade user experience and can indicate underlying system issues. When setting thresholds, I consider the API's complexity (e.g., simple data retrieval vs. complex computations), typical network latency, the expected load, and business requirements for performance. It's important to use realistic values and continuously monitor and adjust them.

## Hands-on Exercise
**Objective**: Test a public API that returns a session cookie after a POST request and validate its headers and response time.

**Task**:
1.  Find a publicly available API endpoint (e.g., a mock login API) that, upon a POST request, sets a cookie in its response. If you cannot find one, simulate it locally or assume a hypothetical `POST /login` endpoint.
2.  Send a POST request to this endpoint.
3.  Assert that the `Content-Type` header is `application/json`.
4.  Extract the value of a hypothetical `JSESSIONID` cookie and print it.
5.  Assert that the response time for this request is less than 3000ms.

## Additional Resources
- **REST Assured Official Documentation**: [https://github.com/rest-assured/rest-assured/wiki/Usage#validation](https://github.com/rest-assured/rest-assured/wiki/Usage#validation)
- **Hamcrest Matchers (used by REST Assured)**: [http://hamcrest.org/JavaHamcrest/javadoc/1.3/org/hamcrest/Matchers.html](http://hamcrest.org/JavaHamcrest/javadoc/1.3/org/hamcrest/Matchers.html)
- **Performance Testing with REST Assured**: (While not its primary function, good practices for timing are discussed in various blogs) - search for "REST Assured performance testing best practices"
---
# api-4.1-ac7.md

# Request and Response Specifications in REST Assured

## Overview
In REST Assured, Request and Response Specifications are powerful features that promote reusability, reduce code duplication, and enhance the maintainability of your API test automation framework. They allow you to define common configurations for requests (like base URI, headers, authentication, parameters) and responses (like expected status codes, content types, or body validations) once, and then apply them across multiple tests. This centralizes common setups, making your tests cleaner, more readable, and easier to manage.

## Detailed Explanation
When testing APIs, you often find yourself repeating the same configurations for requests (e.g., `baseUri`, `contentType`, `headers`) and validations for responses (e.g., `statusCode`, `contentType`). Request and Response Specifications address this by allowing you to pre-configure these elements.

### RequestSpecification
A `RequestSpecification` allows you to define common request parameters such as:
- Base URI (`baseUri()`, `basePath()`)
- Headers (`header()`)
- Content Type (`contentType()`)
- Authentication (`auth()`)
- Query parameters (`queryParam()`)
- Form parameters (`formParam()`)
- Cookies (`cookie()`)

You build a `RequestSpecification` using `RestAssured.given().spec(specification)` or by using `RequestSpecBuilder`.

### ResponseSpecification
A `ResponseSpecification` allows you to define common response expectations such as:
- Status Code (`statusCode()`)
- Content Type (`contentType()`)
- Body Validations (`body()`, `jsonPath()`, `xmlPath()`)
- Headers (`header()`)
- Cookies (`cookie()`)

You build a `ResponseSpecification` using `RestAssured.expect().spec(specification)` or by using `ResponseSpecBuilder`.

### Advantages
- **Reusability**: Define common configurations once and reuse them.
- **Readability**: Tests become cleaner and focus on specific test logic rather than setup.
- **Maintainability**: Changes to common configurations only need to be made in one place.
- **Consistency**: Ensures all tests adhere to a consistent set of request/response standards.

## Code Implementation

Let's imagine we are testing a simple "To-Do List" API.

```java
import io.restassured.RestAssured;
import io.restassured.builder.RequestSpecBuilder;
import io.restassured.builder.ResponseSpecBuilder;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import io.restassured.specification.ResponseSpecification;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItems;

public class TodoApiSpecificationTest {

    // Declare RequestSpecification and ResponseSpecification
    private static RequestSpecification requestSpec;
    private static ResponseSpecification responseSpec;

    @BeforeAll
    public static void setup() {
        // Assume our API is running locally on port 8080
        // And we always send/receive JSON and expect a 200 OK for successful operations

        // 1. Create a RequestSpecification using RequestSpecBuilder
        requestSpec = new RequestSpecBuilder()
                .setBaseUri("http://localhost")
                .setPort(8080)
                .setBasePath("/api/v1/todos")
                .setContentType(ContentType.JSON)
                .addHeader("Accept", ContentType.JSON.toString())
                .build();

        // 2. Create a ResponseSpecification using ResponseSpecBuilder
        responseSpec = new ResponseSpecBuilder()
                .expectStatusCode(200)
                .expectContentType(ContentType.JSON)
                .build();

        // Optional: Set default specifications if you want them applied to ALL RestAssured calls
        // RestAssured.requestSpecification = requestSpec;
        // RestAssured.responseSpecification = responseSpec;
    }

    @Test
    void testGetAllTodos() {
        // Reuse the defined specifications
        given()
            .spec(requestSpec) // Apply request specification
        .when()
            .get()
        .then()
            .spec(responseSpec) // Apply response specification
            .body("size()", equalTo(2)) // Example: Assuming there are 2 todos initially
            .body("title", hasItems("Buy groceries", "Learn REST Assured"));
    }

    @Test
    void testCreateNewTodo() {
        String newTodo = "{"title": "Write API tests", "completed": false}";

        given()
            .spec(requestSpec) // Apply request specification
            .body(newTodo)
        .when()
            .post()
        .then()
            .spec(responseSpec) // Apply response specification
            .statusCode(201) // Expect 201 Created for POST
            .body("title", equalTo("Write API tests"));
    }

    @Test
    void testGetSingleTodo() {
        // We can override or add to the specification for specific tests
        given()
            .spec(requestSpec)
            .pathParam("id", "1") // Add a path parameter for this specific test
        .when()
            .get("/{id}")
        .then()
            .spec(responseSpec)
            .body("title", equalTo("Buy groceries"));
    }

    @Test
    void testDeleteTodo() {
        given()
            .spec(requestSpec)
            .pathParam("id", "3") // Assuming a todo with ID 3 exists and can be deleted
        .when()
            .delete("/{id}")
        .then()
            .spec(responseSpec)
            .statusCode(204); // Expect 204 No Content for successful DELETE
    }

    // Example of a negative test case, where we expect a different status code
    @Test
    void testGetNonExistentTodo() {
        given()
            .spec(requestSpec)
            .pathParam("id", "999") // An ID that surely doesn't exist
        .when()
            .get("/{id}")
        .then()
            .expect()
            .statusCode(404) // Override the default 200 from responseSpec
            .contentType(ContentType.JSON); // We still expect JSON content
    }
}
```

## Best Practices
- **Centralize Specifications**: Define `RequestSpecification` and `ResponseSpecification` in a dedicated utility class or a base test class (`@BeforeAll` or `@BeforeEach`) for easy access and management.
- **Layer Specifications**: Create multiple specifications for different purposes (e.g., one for authenticated requests, another for public requests, one for different API versions). You can combine them using `merge()`.
- **Use `ResponseSpecBuilder` for Complex Validations**: For validations that involve multiple checks (e.g., `body("field1", equalTo("value"))`, `body("field2", notNullValue())`), `ResponseSpecBuilder` keeps the logic organized.
- **Don't Over-specify**: Only include truly common elements in your specifications. Specific parameters or validations for a single test should remain within that test.
- **Override When Necessary**: It's perfectly fine to override or add to a specification within a specific test if it has unique requirements, as shown in `testGetSingleTodo` and `testGetNonExistentTodo`.

## Common Pitfalls
- **Overriding Global `RestAssured` Config**: While `RestAssured.requestSpecification` and `RestAssured.responseSpecification` can set global defaults, using `given().spec()` and `then().spec()` directly in tests is generally preferred for clarity and avoiding unintended global side effects, especially in complex frameworks or parallel test execution.
- **Ignoring Specific Test Needs**: Not all tests will fit a generic specification. Forgetting to override or add specific details can lead to failed tests or incomplete validation.
- **Lack of Clarity**: Creating specifications that are too broad or contain too many varying elements can make them less useful and harder to understand. Keep them focused on distinct, reusable patterns.
- **Not Handling Errors in Specifications**: A `ResponseSpecification` might typically expect a 200 OK. For negative test cases, you MUST override the status code expectation to match the expected error code (e.g., 400, 401, 404).

## Interview Questions & Answers
1.  **Q: What are Request and Response Specifications in REST Assured, and why are they useful?**
    **A:** Request and Response Specifications are objects that encapsulate common configurations for requests (like base URI, headers, authentication) and common validations for responses (like status code, content type, body assertions). They are useful because they promote reusability, reduce code duplication across tests, improve test readability by separating setup from test logic, and make test suites easier to maintain by centralizing common patterns.

2.  **Q: How do you create and use RequestSpecification and ResponseSpecification?**
    **A:** You typically create them using `RequestSpecBuilder` and `ResponseSpecBuilder`, respectively. For example:
    ```java
    RequestSpecification requestSpec = new RequestSpecBuilder()
        .setBaseUri("https://api.example.com")
        .setContentType(ContentType.JSON)
        .build();

    ResponseSpecification responseSpec = new ResponseSpecBuilder()
        .expectStatusCode(200)
        .expectContentType(ContentType.JSON)
        .build();
    ```
    You then apply them to your tests using `given().spec(requestSpec)` and `then().spec(responseSpec)`.

3.  **Q: Can you combine multiple specifications or override parts of a specification? Provide an example.**
    **A:** Yes, you can combine specifications using the `merge()` method. For example, you might have a base specification and another for authenticated requests. You can also override parts of a specification by simply adding more configurations to your `given()` or `then()` chain after applying the spec.
    ```java
    RequestSpecification baseSpec = new RequestSpecBuilder().setBaseUri("http://localhost").build();
    RequestSpecification authSpec = new RequestSpecBuilder().addHeader("Authorization", "Bearer token").build();
    RequestSpecification finalSpec = baseSpec.merge(authSpec); // Combines both

    given().spec(finalSpec).queryParam("id", "123") // Adding specific parameter
    // ...
    ```

## Hands-on Exercise
**Scenario**: You are testing a user management API.
**Task**:
1.  Create a `RequestSpecification` that sets the `baseUri` to `https://your-user-api.com/v1`, `basePath` to `/users`, and `ContentType` to `JSON`. Also, add an `Authorization` header with a dummy bearer token (e.g., `Bearer abcdef12345`).
2.  Create a `ResponseSpecification` that expects a `statusCode` of `200` and `ContentType` of `JSON`.
3.  Write a test method `testCreateUser()` that uses these specifications to send a POST request to create a new user. The response should assert the `name` of the created user in the response body.
4.  Write another test method `testGetUserById()` that uses the same `RequestSpecification`, but overrides the `basePath` to include a specific user ID (`/users/{id}`) and validates the response using the `ResponseSpecification`. Ensure you use a path parameter.
5.  Implement a negative test case `testCreateUserWithInvalidData()` that uses the `RequestSpecification` but expects a `statusCode` of `400` for a malformed request body.

## Additional Resources
-   **REST Assured Official Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Baeldung Tutorial on REST Assured Specifications**: [https://www.baeldung.com/rest-assured-specifications](https://www.baeldung.com/rest-assured-specifications)
-   **RestAssured API Docs - RequestSpecBuilder**: [https://javadoc.io/doc/io.rest-assured/rest-assured/latest/io/restassured/builder/RequestSpecBuilder.html](https://javadoc.io/doc/io.rest-assured/rest-assured/latest/io/restassured/builder/RequestSpecBuilder.html)
-   **RestAssured API Docs - ResponseSpecBuilder**: [https://javadoc.io/doc/io.rest-assured/rest-assured/latest/io/restassured/builder/ResponseSpecBuilder.html](https://javadoc.io/doc/io.rest-assured/rest-assured/latest/io/restassured/builder/ResponseSpecBuilder.html)
---
# api-4.1-ac8.md

# REST Assured Fundamentals: Base URI, Headers, Path & Query Parameters

## Overview
In REST Assured, effectively managing your API request configuration is crucial for writing clean, maintainable, and robust API tests. This guide focuses on four fundamental aspects: setting a base URI, and incorporating path parameters, query parameters, and custom headers into your requests. These elements allow you to target specific API endpoints, filter data, and provide necessary contextual information for your API calls, making your test suite highly adaptable to real-world API interactions.

## Detailed Explanation

### 1. Base URI (`RestAssured.baseURI`)
The Base Uniform Resource Identifier (URI) is the common, unchanging part of your API endpoint URL. Configuring it allows you to define this common part once, avoiding repetition across multiple tests. This improves readability and makes your tests easier to update if the API's base URL changes.

*   **Global Configuration**: Set `RestAssured.baseURI` once, typically in a setup method or a static block, to apply it to all subsequent requests.
*   **Local Overriding**: You can override the `baseURI` for specific requests using `given().baseUri(...)` if a test needs to hit a different service.

**Example**: If your API endpoints are `https://api.example.com/users` and `https://api.example.com/products`, then `https://api.example.com` would be your base URI.

### 2. Query Parameters (`queryParam`)
Query parameters are key-value pairs appended to the URL after a question mark (`?`), separated by ampersands (`&`). They are primarily used to filter, sort, paginate, or provide additional optional data for a resource.

**Syntax**: `?key1=value1&key2=value2`
**Usage**: In REST Assured, you add them using the `.queryParam(key, value)` method.

**Example**: To get a list of active users, you might use `/users?status=active`.

### 3. Path Parameters (`pathParam`)
Path parameters are variable parts of the URL path that identify specific resources or subsets of resources. They are embedded directly within the URI structure.

**Syntax**: `/resource/{id}` where `{id}` is a placeholder.
**Usage**: In REST Assured, you define placeholders in your path (e.g., `/api/users/{userId}`) and then use the `.pathParam(key, value)` method to substitute the actual values.

**Example**: To get details of a user with ID `2`, you would use `/users/2`. Here, `2` is the path parameter.

### 4. Custom Headers (`header`)
HTTP headers are key-value pairs that are sent along with an HTTP request or response. They provide metadata about the request or response, such as content type, authorization credentials, client information, or caching instructions.

**Common Uses**:
*   **Authorization**: `Authorization: Bearer <token>`
*   **Content Type**: `Content-Type: application/json`
*   **Accept**: `Accept: application/xml` (to specify expected response format)
*   **Custom Data**: `X-Client-ID: myApp`

**Usage**: In REST Assured, you can add headers using `.header(name, value)` or `.headers(Map<String, String> headers)`.

## Code Implementation

Let's demonstrate these concepts with practical examples using the `https://reqres.in/api` endpoint. We'll use TestNG for test execution.

```java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import java.util.HashMap;
import java.util.Map;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

public class RestAssuredParametersAndHeadersTest {

    // Globally configure the base URI for all tests in this class
    @BeforeClass
    public void setup() {
        RestAssured.baseURI = "https://reqres.in";
        RestAssured.basePath = "/api"; // Optional: Can also set a base path
        System.out.println("Base URI and Path set to: " + RestAssured.baseURI + RestAssured.basePath);
    }

    @Test(description = "Verify GET request with a query parameter for filtering results")
    public void testGetUsersWithQueryParameter() {
        System.out.println("
--- Running testGetUsersWithQueryParameter ---");
        // GET /api/users?page=2
        given()
            .queryParam("page", 2) // Add query parameter
        .when()
            .get("/users") // Endpoint relative to baseURI and basePath
        .then()
            .statusCode(200)
            .body("page", equalTo(2))
            .body("data", hasSize(6)) // Verify response contains data for page 2
            .log().body(); // Log the response body for inspection
    }

    @Test(description = "Verify GET request with a path parameter for specific resource targeting")
    public void testGetSingleUserWithPathParameter() {
        System.out.println("
--- Running testGetSingleUserWithPathParameter ---");
        int userId = 5;
        // GET /api/users/5
        given()
            .pathParam("userId", userId) // Add path parameter
        .when()
            .get("/users/{userId}") // Use placeholder for path parameter
        .then()
            .statusCode(200)
            .body("data.id", equalTo(userId))
            .body("data.first_name", equalTo("Charles"))
            .log().body();
    }

    @Test(description = "Verify POST request with custom headers and a request body")
    public void testCreateUserWithCustomHeaders() {
        System.out.println("
--- Running testCreateUserWithCustomHeaders ---");
        String requestBody = "{ "name": "morpheus", "job": "leader" }";

        // Create a map for multiple headers (optional, can use multiple .header() calls)
        Map<String, String> headers = new HashMap<>();
        headers.put("X-Custom-Auth", "mySecretToken123"); // Example custom header
        headers.put("Accept", "application/json"); // Example standard header

        given()
            .contentType(ContentType.JSON) // Set Content-Type header
            .headers(headers) // Add multiple headers from a map
            .header("X-Request-ID", "unique-request-123") // Add a single header
            .body(requestBody)
        .when()
            .post("/users") // POST to /api/users
        .then()
            .statusCode(201) // Expected status code for resource creation
            .body("name", equalTo("morpheus"))
            .body("job", equalTo("leader"))
            .log().body();
    }

    @Test(description = "Demonstrate overriding baseURI for a specific request")
    public void testOverridingBaseURI() {
        System.out.println("
--- Running testOverridingBaseURI ---");
        // This test will hit a different base URI: "https://www.google.com"
        given()
            .baseUri("https://www.google.com") // Override baseURI for this request
        .when()
            .get() // Will hit "https://www.google.com/"
        .then()
            .statusCode(200)
            .log().status(); // Only log status as body might be large
    }
}
```

## Best Practices
-   **Centralize Base URI**: Always define your `RestAssured.baseURI` and `RestAssured.basePath` globally (e.g., in `@BeforeClass` or a common utility class) to ensure consistency and easy maintenance.
-   **Use `RequestSpecification` for Reusability**: For common headers, query parameters, or authentication, create and reuse `RequestSpecification` objects to avoid code duplication.
-   **Descriptive Parameter Names**: Use meaningful names for your path and query parameters that reflect their purpose.
-   **Encode Parameters**: REST Assured automatically encodes parameter values, but be mindful of special characters if constructing URLs manually or using complex values.
-   **Externalize Configuration**: Avoid hardcoding base URIs, API keys, or frequently changing parameters directly in your tests. Use configuration files (e.g., `config.properties`, environment variables) to manage these values.
-   **Clear Path Parameter Placeholders**: Use clear and consistent placeholders for path parameters (e.g., `{userId}`, `{productId}`).

## Common Pitfalls
-   **Confusing Path and Query Parameters**: Incorrectly using a path parameter when a query parameter is needed, or vice-versa, will lead to incorrect API calls or 404 errors.
-   **Hardcoding Values**: Directly embedding `baseURI` or other dynamic values makes tests brittle and hard to adapt to different environments.
-   **Missing Required Headers**: Forgetting to include essential headers like `Authorization` or `Content-Type` for POST/PUT requests can result in `401 Unauthorized` or `415 Unsupported Media Type` errors.
-   **Incorrect Placeholder Usage**: Mismatched path parameter names between the `.pathParam()` call and the URL string (e.g., `.pathParam("id", 1)` but `get("/users/{userId}")`) will cause issues.
-   **Not Resetting Global Configurations**: If you modify `RestAssured.baseURI` or `RestAssured.basePath` within a test without resetting it (or using `given().baseUri()`), it might affect subsequent tests unexpectedly.

## Interview Questions & Answers

1.  **Q: What is the primary difference between a path parameter and a query parameter in the context of RESTful APIs, and how would you implement them using REST Assured?**
    *   **A:** **Path parameters** are used to identify a specific resource or resources within a collection. They are part of the URL path itself, e.g., `/users/123` where `123` is the user ID. In REST Assured, you define them with placeholders like `given().pathParam("id", 123).when().get("/users/{id}")`.
        **Query parameters** are used to filter, sort, paginate, or provide additional optional information about a resource collection. They appear after a question mark (`?`) in the URL, e.g., `/users?status=active&limit=10`. In REST Assured, you use `given().queryParam("status", "active").queryParam("limit", 10).when().get("/users")`.

2.  **Q: How do you handle common headers like `Content-Type` and `Authorization` using REST Assured? Can you provide an example of setting multiple headers?**
    *   **A:** `Content-Type` can be set using `contentType(ContentType.JSON)` or `header("Content-Type", "application/json")`. `Authorization` is typically set using `header("Authorization", "Bearer <your_token>")`.
        To set multiple headers:
        ```java
        Map<String, String> headers = new HashMap<>();
        headers.put("Authorization", "Bearer abc123def456");
        headers.put("X-Custom-Client", "AutomationTest");
        given().headers(headers).when().get("/secure-endpoint");
        ```
        Alternatively, you can chain multiple `.header()` calls:
        ```java
        given().header("Header1", "Value1").header("Header2", "Value2").when().get("/endpoint");
        ```

3.  **Q: Explain the benefit of setting `RestAssured.baseURI` globally versus specifying the full URL in every `get()`, `post()`, etc., call.**
    *   **A:** Setting `RestAssured.baseURI` globally (e.g., `RestAssured.baseURI = "http://api.example.com";`) centralizes the base URL configuration. The main benefits are:
        1.  **Readability**: Test methods become cleaner, as they only need to specify the endpoint's relative path (e.g., `/users`).
        2.  **Maintainability**: If the API's base URL changes (e.g., from `dev.api.com` to `prod.api.com`), you only need to update it in one place, reducing the effort and risk of errors.
        3.  **Flexibility**: It integrates well with environment-specific configurations, allowing you to easily switch between different API environments (e.g., QA, Staging, Production) without modifying test code.

## Hands-on Exercise

Using a publicly available mock API (e.g., ReqRes.in or JSONPlaceholder) or setting up a local mock server:

1.  **Retrieve All Resources**: Write a test to retrieve a list of resources (e.g., users or posts) from a base endpoint (e.g., `/users`). Ensure you set the `baseURI` globally.
2.  **Filter Resources**: Add a query parameter to your GET request to filter the list of resources (e.g., `?page=2` for users on ReqRes.in). Assert that the response data matches the filter.
3.  **Retrieve Specific Resource**: Use a path parameter to retrieve a single, specific resource (e.g., `/users/1`). Assert the details of the retrieved resource.
4.  **Create Resource with Custom Header**: Send a POST request to create a new resource. Include a `Content-Type: application/json` header and at least one custom header (e.g., `X-Correlation-ID`). Verify the successful creation (status code 201) and that the response body contains the submitted data.

## Additional Resources
-   **REST Assured GitHub Wiki**: The official documentation for all features.
    [https://github.com/rest-assured/rest-assured/wiki/Usage#base-path](https://github.com/rest-assured/rest-assured/wiki/Usage#base-path)
-   **Baeldung - REST Assured Tutorial**: A comprehensive guide with various examples.
    [https://www.baeldung.com/rest-assured-tutorial](https://www.baeldung.com/rest-assured-tutorial)
-   **ReqRes - A Hosted REST-API ready to respond to your AJAX requests**: Useful for practicing API tests.
    [https://reqres.in/](https://reqres.in/)
