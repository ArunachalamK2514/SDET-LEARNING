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
