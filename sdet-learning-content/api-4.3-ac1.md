# Basic Authentication using `preemptive().basic()` in REST Assured

## Overview
Basic Authentication is a simple authentication scheme built into the HTTP protocol. It's often used for securing APIs where a username and password are provided with each request. In the context of API testing, especially with REST Assured, implementing Basic Authentication is a common requirement to access protected resources. `preemptive().basic()` in REST Assured provides a straightforward way to include these credentials in your API requests, ensuring they are sent with the initial request without waiting for a 401 Unauthorized challenge. This is crucial for seamless automation and avoiding unnecessary request-response cycles.

## Detailed Explanation
HTTP Basic Authentication works by sending a header in the format `Authorization: Basic <credentials>`, where `<credentials>` is the Base64 encoding of `username:password`.

REST Assured's `preemptive().basic(username, password)` method automatically handles the Base64 encoding and sets the `Authorization` header for you. The "preemptive" aspect means that REST Assured sends the authentication header with the *initial* request. This is generally preferred over "challenging" authentication, where the client first makes a request, receives a 401 Unauthorized response, and then re-sends the request with authentication details. Preemptive authentication reduces network round trips and can be more efficient, especially in test automation scenarios.

When you use `given().auth().preemptive().basic("username", "password")`, REST Assured will ensure that every subsequent request in that chain includes the appropriate `Authorization` header.

### When to use `preemptive()` vs. `basic()` (without preemptive)
- **`preemptive().basic()`**: Use this when you know the endpoint requires authentication and you want to send the credentials with the very first request. This is the most common and recommended approach for API testing as it's more efficient.
- **`basic()` (without preemptive)**: This approach sends credentials only after receiving a 401 Unauthorized challenge from the server. While technically compliant with the HTTP spec, it results in an extra round trip for each authenticated request, making it less efficient for testing. It's rarely needed in automated testing unless you are specifically testing the server's challenge-response mechanism.

## Code Implementation
Let's assume we have an API endpoint that requires basic authentication. For this example, we'll use a public API like `http://httpbin.org/basic-auth/user/passwd` which is designed to test basic authentication.

```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

public class BasicAuthTest {

    // Define base URI if all tests use the same base
    // @BeforeClass
    // public void setup() {
    //     RestAssured.baseURI = "http://httpbin.org";
    // }

    @Test(description = "Verify successful Basic Authentication using preemptive().basic()")
    public void testBasicAuthenticationSuccess() {
        String username = "user";
        String password = "passwd";

        Response response = given()
            .auth()
            .preemptive()
            .basic(username, password)
        .when()
            .get("http://httpbin.org/basic-auth/" + username + "/" + password) // Directly using full URL for clarity
        .then()
            .statusCode(200) // Expecting 200 OK for successful authentication
            .body("authenticated", is(true)) // Verifying the response body confirms authentication
            .log().body() // Log the response body for debugging
            .extract().response();

        System.out.println("Response Body: " + response.asString());
    }

    @Test(description = "Verify Basic Authentication failure with incorrect credentials")
    public void testBasicAuthenticationFailure() {
        String username = "user";
        String wrongPassword = "wrongpassword";

        given()
            .auth()
            .preemptive()
            .basic(username, wrongPassword)
        .when()
            .get("http://httpbin.org/basic-auth/user/passwd") // Endpoint expects 'user'/'passwd'
        .then()
            .statusCode(401) // Expecting 401 Unauthorized for incorrect credentials
            .body(containsString("401 Unauthorized")) // Verify response body indicates unauthorized access
            .log().all(); // Log all details for debugging
    }

    @Test(description = "Verify that not providing authentication results in 401 Unauthorized")
    public void testBasicAuthenticationNoCredentials() {
        given()
        .when()
            .get("http://httpbin.org/basic-auth/user/passwd") // Endpoint expects 'user'/'passwd'
        .then()
            .statusCode(401) // Expecting 401 Unauthorized when no credentials are provided
            .log().all();
    }
}
```

## Best Practices
- **Use `preemptive()` for efficiency:** Always prefer `preemptive().basic()` to minimize network overhead in your test automation.
- **Environment variables/Configuration:** Avoid hardcoding credentials directly in your tests. Instead, store them in environment variables, configuration files (e.g., `application.properties`, `config.json`), or a secure vault. This improves security and maintainability.
- **Separate credentials:** If different environments (dev, staging, prod) use different credentials, ensure your test framework can dynamically pick the correct ones.
- **Clear test naming:** Use descriptive test method names that clearly indicate what is being tested (e.g., `testBasicAuthenticationSuccess`, `testBasicAuthenticationFailure`).
- **Validate status code AND response body:** Don't just check for a 200 OK. Always validate the response body or specific headers to confirm the *successful outcome* of the authenticated request, not just that the server responded.

## Common Pitfalls
- **Hardcoding credentials:** This is a major security risk and makes tests difficult to maintain across different environments.
- **Forgetting `preemptive()`:** If you use `.basic()` without `preemptive()`, your tests might fail or take longer due to the extra round trip, especially if the server doesn't immediately send a 401 challenge.
- **Incorrect Base64 encoding (if manual):** If you were to manually encode credentials, any error in Base64 encoding would lead to authentication failure. `preemptive().basic()` handles this automatically, so avoid manual encoding.
- **Misunderstanding endpoint requirements:** Some APIs might require different authentication schemes (e.g., OAuth2, Bearer Token). Ensure you're using Basic Auth only when the API truly expects it.
- **Lack of error handling tests:** It's not enough to test successful authentication. You *must* also test scenarios where authentication fails (e.g., incorrect username/password, missing credentials) to ensure your API handles these cases gracefully.

## Interview Questions & Answers
1.  **Q:** Explain the difference between `preemptive().basic()` and `basic()` in REST Assured. When would you use each?
    **A:** `preemptive().basic()` sends the `Authorization` header with the initial request, assuming the server requires authentication. This is more efficient as it avoids an extra round trip. `basic()` (without `preemptive()`) only sends the `Authorization` header after the server responds with a 401 Unauthorized challenge. You would almost always use `preemptive().basic()` in automated testing for efficiency. `basic()` might be used if you specifically want to test the server's challenge-response mechanism, but this is rare.

2.  **Q:** How would you handle sensitive authentication credentials in your REST Assured tests to ensure security and maintainability?
    **A:** I would never hardcode credentials. Instead, I'd use environment variables, external configuration files (like `config.properties` or `config.yaml`), or a secure vault/secret management system (e.g., HashiCorp Vault, AWS Secrets Manager) if the project uses one. This approach keeps credentials out of source control, allows for easy switching between environments, and enhances security.

3.  **Q:** What status code would you expect for a successful Basic Authentication, and what else should you verify in the response?
    **A:** For successful Basic Authentication, I would expect a `200 OK` status code. Beyond the status code, it's crucial to verify the response body or specific headers to confirm that the request was processed as intended. For example, if it's a login API, I'd check for a session token or a success message in the JSON response. If it's a data retrieval API, I'd check for the presence and correctness of the expected data.

## Hands-on Exercise
**Scenario:** You are given an API endpoint `https://postman-echo.com/basic-auth` that requires Basic Authentication with username `postman` and password `password`.

**Task:**
1.  Write a REST Assured test that successfully authenticates to this endpoint using `preemptive().basic()`.
2.  Assert that the response status code is `200 OK`.
3.  Assert that the JSON response body contains `{"authenticated": true}`.
4.  Write another test that attempts to authenticate with incorrect credentials (e.g., `wronguser`/`wrongpass`) and asserts that it receives a `401 Unauthorized` status code.

## Additional Resources
-   **REST Assured Authentication:** [https://rest-assured.io/docs/reference/#authentication](https://rest-assured.io/docs/reference/#authentication)
-   **HTTP Basic Authentication (Wikipedia):** [https://en.wikipedia.org/wiki/Basic_access_authentication](https://en.wikipedia.org/wiki/Basic_access_authentication)
-   **Httpbin.org (for testing purposes):** [https://httpbin.org/](https://httpbin.org/)
