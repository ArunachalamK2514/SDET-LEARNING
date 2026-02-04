# API Testing: Authentication & Authorization Scenarios

## Overview
Authentication and authorization are critical aspects of secure API design. As an SDET, thoroughly testing these mechanisms is paramount to ensure that only legitimate users can access protected resources and perform authorized actions. This feature focuses on creating robust tests for authenticated and unauthenticated scenarios, covering positive flows with valid credentials and negative flows with missing, invalid, or expired authentication.

## Detailed Explanation

### Authentication vs. Authorization
*   **Authentication**: Verifying the identity of a user or system. (e.g., username/password, API key, OAuth token). "Are you who you say you are?"
*   **Authorization**: Determining what an authenticated user or system is allowed to do. (e.g., read-only access, admin privileges). "What are you allowed to do?"

Our tests will primarily focus on authentication, ensuring the API correctly handles various states of user identity.

### Testing Scenarios
1.  **Positive Test with Valid Authentication**:
    *   **Goal**: Verify that a request with valid authentication credentials successfully accesses a protected resource.
    *   **Process**: Obtain a valid authentication token (e.g., by logging in), include it in the request headers, and assert that the response is successful (e.g., 200 OK, 201 Created) and contains the expected data.

2.  **Negative Test with No Authentication**:
    *   **Goal**: Verify that a request to a protected resource without any authentication fails with an appropriate error.
    *   **Process**: Send a request to a protected endpoint *without* including any authentication headers. Assert that the API responds with an `Unauthorized` (401) or `Forbidden` (403) status code and a clear error message.

3.  **Negative Test with Invalid/Expired Authentication**:
    *   **Goal**: Verify that a request with invalid or expired authentication credentials fails with an appropriate error.
    *   **Process**:
        *   **Invalid Auth**: Use a syntactically correct but functionally incorrect token (e.g., a random string, a token for a non-existent user, or a tampered token).
        *   **Expired Auth**: Obtain a valid token, wait for it to expire (if possible within test limits, or simulate an expired token), then use it.
        *   Assert that the API responds with an `Unauthorized` (401) or `Forbidden` (403) status code and an informative error message.

4.  **Verify Appropriate Error Messages**:
    *   For all negative scenarios, it's crucial not just to check the status code but also the error message and structure. The message should be clear, user-friendly (without revealing sensitive internal details), and consistent across the API.

## Code Implementation

We'll use Java with TestNG and REST Assured for these examples.

```java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

public class AuthApiTests {

    private final String BASE_URI = "https://api.example.com"; // Replace with your API base URI
    private final String PROTECTED_ENDPOINT = "/api/v1/users/profile"; // A protected resource
    private final String LOGIN_ENDPOINT = "/auth/login"; // Endpoint to get a valid token

    private String validAuthToken;
    private String expiredAuthToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1MTYyMzkwMjJ9.N0K-b_f9OQz-b8Y-j9Q-q_zY-7x-0v_2N_1j_8e_6x-8"; // A JWT token that expired in 2018
    private String invalidAuthToken = "Invalid.Token.String"; // Syntactically invalid token
    private String nonExistentUserToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJub25leGlzdGVudCIsInBhcmFtcyI6eyJ1c2VySWQiOiIwMDAwIn0sImlhdCI6MTY3ODAwMDAwMCwiZXhwIjoxNjc4MDE2NDAwfQ.SignatureHere"; // Example of a token for a non-existent user

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = BASE_URI;
        // Assume a login endpoint exists that returns a JWT token
        // This is a placeholder for actual login logic.
        // In a real scenario, you'd make a POST request with credentials.
        Response loginResponse = given()
                .contentType(ContentType.JSON)
                .body("{ "username": "testuser", "password": "password123" }")
                .post(LOGIN_ENDPOINT);

        // This assumes the token is directly in the response body as a string.
        // Adjust based on your API's actual response structure.
        validAuthToken = loginResponse.jsonPath().getString("token");
        System.out.println("Obtained Valid Auth Token: " + validAuthToken);
    }

    @Test(priority = 1, description = "Positive: Access protected resource with valid authentication")
    public void testProtectedResourceWithValidAuth() {
        given()
            .header("Authorization", "Bearer " + validAuthToken)
        .when()
            .get(PROTECTED_ENDPOINT)
        .then()
            .statusCode(200)
            .contentType(ContentType.JSON)
            .body("username", equalTo("testuser")) // Assert expected data
            .log().body();
    }

    @Test(priority = 2, description = "Negative: Attempt to access protected resource with no authentication")
    public void testProtectedResourceWithNoAuth() {
        given()
        .when()
            .get(PROTECTED_ENDPOINT)
        .then()
            .statusCode(anyOf(equalTo(401), equalTo(403))) // Expect 401 Unauthorized or 403 Forbidden
            .contentType(ContentType.JSON)
            .body("error", notNullValue()) // Error message should exist
            .body("message", containsStringIgnoringCase("unauthorized")) // Specific error message check
            .log().body();
    }

    @Test(priority = 3, description = "Negative: Attempt to access protected resource with invalid authentication token")
    public void testProtectedResourceWithInvalidAuth() {
        given()
            .header("Authorization", "Bearer " + invalidAuthToken)
        .when()
            .get(PROTECTED_ENDPOINT)
        .then()
            .statusCode(anyOf(equalTo(401), equalTo(403))) // Expect 401 or 403
            .contentType(ContentType.JSON)
            .body("error", notNullValue())
            .body("message", containsStringIgnoringCase("invalid token")) // Check for specific invalid token message
            .log().body();
    }

    @Test(priority = 4, description = "Negative: Attempt to access protected resource with expired authentication token")
    public void testProtectedResourceWithExpiredAuth() {
        given()
            .header("Authorization", "Bearer " + expiredAuthToken)
        .when()
            .get(PROTECTED_ENDPOINT)
        .then()
            .statusCode(anyOf(equalTo(401), equalTo(403))) // Expect 401 or 403
            .contentType(ContentType.JSON)
            .body("error", notNullValue())
            .body("message", containsStringIgnoringCase("token expired")) // Check for specific expired token message
            .log().body();
    }

    @Test(priority = 5, description = "Negative: Attempt to access protected resource with token for non-existent user")
    public void testProtectedResourceWithNonExistentUserToken() {
        given()
            .header("Authorization", "Bearer " + nonExistentUserToken)
        .when()
            .get(PROTECTED_ENDPOINT)
        .then()
            .statusCode(anyOf(equalTo(401), equalTo(403))) // Expect 401 or 403
            .contentType(ContentType.JSON)
            .body("error", notNullValue())
            .body("message", containsStringIgnoringCase("user not found")) // Check for specific message
            .log().body();
    }
}
```

## Best Practices
-   **Isolate Authentication Logic**: Create helper methods or classes to handle token generation/retrieval to avoid code duplication and improve readability.
-   **Dynamic Token Generation**: Always generate fresh tokens for tests. Do not hardcode valid tokens, as they can expire or be revoked.
-   **Robust Error Assertions**: Beyond status codes, assert on the presence and content of error messages to ensure they are user-friendly and consistent.
-   **Test Edge Cases**: Consider malformed tokens, tokens with invalid signatures, and tokens with incorrect scopes/roles if authorization is also part of the endpoint's logic.
-   **Clean Up**: If tokens are stored persistently, ensure tests clean up any created test data or users.
-   **Environment Variables**: Use environment variables for sensitive data like usernames, passwords, and base URIs, especially in CI/CD pipelines.

## Common Pitfalls
-   **Hardcoding Tokens**: Leads to brittle tests that break when tokens expire or security policies change.
-   **Insufficient Error Message Validation**: Only checking status codes misses opportunities to validate the API's error handling quality and user experience.
-   **Ignoring Rate Limiting**: Repeated failed authentication attempts can trigger rate limits, causing tests to fail prematurely. Consider exponential backoff or mocking during login attempts if this is an issue.
-   **Not Testing Token Expiration**: Overlooking the scenario where a valid token becomes expired can expose security vulnerabilities.
-   **Testing in Production-like Environments**: Ensure your test environment accurately reflects production authentication mechanisms, including any SSO, OAuth providers, or identity servers.

## Interview Questions & Answers
1.  **Q**: How do you approach testing API authentication and authorization?
    **A**: I start by understanding the authentication mechanism (e.g., JWT, OAuth2, API Keys). For authentication, I design tests for positive (valid credentials), negative (no credentials, invalid credentials, expired credentials), and edge cases (malformed tokens). For authorization, I create tests for different user roles to ensure they can only access resources and perform actions permitted by their role. I focus on asserting correct HTTP status codes (401, 403) and meaningful error messages.

2.  **Q**: What's the difference between a 401 Unauthorized and a 403 Forbidden response, and when would you expect each in authentication testing?
    **A**: A **401 Unauthorized** means the client has not authenticated or needs to re-authenticate. You'd expect this when no credentials are provided or when the provided credentials are invalid or expired. A **403 Forbidden** means the client is authenticated but does not have permission to access the resource. You'd expect this if a user with a valid token tries to access a resource they are not authorized for (e.g., a regular user trying to access an admin-only endpoint).

3.  **Q**: How would you simulate an expired token for testing purposes if waiting for actual expiration isn't feasible?
    **A**: There are a few ways:
    *   **Backend Support**: Ideally, the backend would provide a test endpoint or configuration to generate short-lived tokens or explicitly expired tokens.
    *   **Manual JWT Manipulation**: If using JWTs, one could potentially generate a JWT with a past `exp` (expiration) claim, although this requires knowledge of the signing key or mocking the token validation.
    *   **Mocking**: For integration tests, one could mock the authentication service to return an "expired token" error when a specific token is presented.

## Hands-on Exercise
**Scenario**: You are given an API endpoint `GET /api/v2/products` which requires a valid JWT token in the `Authorization: Bearer <token>` header. There is also a `POST /auth/generate-token` endpoint that accepts `username` and `password` to provide a valid token.

**Task**:
1.  Implement a `setup` method that calls `POST /auth/generate-token` to get a valid JWT.
2.  Write a positive test case to successfully retrieve products using the valid token.
3.  Write a negative test case to attempt to retrieve products without any token and assert a 401 status code and an "Authentication required" error message.
4.  (Advanced) If your API allows, try to obtain a token for a user with limited privileges and verify they cannot access a higher-privileged endpoint.

## Additional Resources
-   **REST Assured Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **JWT (JSON Web Tokens) Introduction**: [https://jwt.io/introduction](https://jwt.io/introduction)
-   **OAuth 2.0 Simplified**: [https://oauth.net/2/](https://oauth.net/2/)
-   **OWASP API Security Top 10**: [https://owasp.org/www-project-api-security/](https://owasp.org/www-project-api-security/)
