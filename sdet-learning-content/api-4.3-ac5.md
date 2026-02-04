# API 4.3-ac5: Token Generation and Refresh Logic

## Overview
In modern API testing, especially with secure applications, direct authentication often involves generating a temporary access token. This token, typically a JWT (JSON Web Token) or an OAuth token, is used to authorize subsequent API requests for a limited duration. Once the token expires, further requests will fail with authentication errors (e.g., 401 Unauthorized). To maintain a seamless testing flow without re-authenticating for every single request, a token refresh mechanism is crucial. This feature focuses on implementing robust logic to check for token expiry, automatically refresh the token using a dedicated endpoint, and update the stored token for all subsequent API calls within the test suite.

## Detailed Explanation
Authentication and authorization are fundamental aspects of secure APIs.
-   **Authentication** verifies the identity of a client (e.g., a user or an application).
-   **Authorization** determines what an authenticated client is allowed to do.

Many APIs use token-based authentication (e.g., OAuth 2.0, OpenID Connect, JWTs). The typical flow involves:
1.  **Initial Authentication**: Client sends credentials (username/password) to an authentication endpoint.
2.  **Token Generation**: The server validates credentials and returns an `access token` (for resource access) and often a `refresh token` (for renewing access tokens). Access tokens have a short lifespan for security reasons.
3.  **Resource Access**: Client includes the access token in the `Authorization` header (e.g., `Bearer <access_token>`) for protected resource requests.
4.  **Token Expiry**: After a certain period, the access token becomes invalid.
5.  **Token Refresh**: When an access token expires, the client uses the longer-lived refresh token to obtain a new access token without requiring re-authentication with credentials. This prevents service interruptions.

In an SDET context, managing these tokens automatically is critical for stable and efficient test execution. Our test automation framework should:
-   Store the access and refresh tokens securely.
-   Provide a mechanism to check if the current access token is still valid (e.g., by checking its expiry time if available, or by handling 401 responses).
-   If expired or invalid, use the refresh token to call the refresh endpoint to get a new access token.
-   Update the stored access token and, if provided, the new refresh token.

## Code Implementation
This example demonstrates a basic Java implementation using `RestAssured` for API calls and `JUnit` for testing. We'll use a `TokenManager` class to encapsulate token handling.

```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.given;
import static org.junit.jupiter.api.Assertions.*;

import java.time.Instant;
import java.util.concurrent.TimeUnit;

public class ApiTokenRefreshTest {

    // Ideally, these would come from a configuration file (e.g., application.properties)
    private static final String BASE_URI = "http://localhost:8080"; // Example API base URI
    private static final String AUTH_ENDPOINT = "/auth/login";
    private static final String REFRESH_ENDPOINT = "/auth/refresh";
    private static final String PROTECTED_RESOURCE_ENDPOINT = "/api/v1/protected";

    // Simulate user credentials
    private static final String USERNAME = "testuser";
    private static final String PASSWORD = "password";

    // TokenManager to handle token lifecycle
    private static TokenManager tokenManager;

    @BeforeAll
    static void setup() {
        RestAssured.baseURI = BASE_URI;
        tokenManager = new TokenManager();
        // Perform initial login to get the first set of tokens
        tokenManager.authenticate(USERNAME, PASSWORD);
        assertNotNull(tokenManager.getAccessToken(), "Access token should not be null after initial login.");
        assertNotNull(tokenManager.getRefreshToken(), "Refresh token should not be null after initial login.");
    }

    @Test
    @DisplayName("Access protected resource with valid token")
    void testProtectedResourceAccess() {
        // Ensure token is valid before making the call
        tokenManager.ensureTokenIsValid();

        Response response = given()
                .header("Authorization", "Bearer " + tokenManager.getAccessToken())
                .when()
                .get(PROTECTED_RESOURCE_ENDPOINT)
                .then()
                .extract().response();

        assertEquals(200, response.statusCode(), "Should access protected resource successfully.");
        assertTrue(response.body().asString().contains("Welcome, authorized user"), "Response should indicate successful access.");
    }

    @Test
    @DisplayName("Verify token refresh mechanism after expiry simulation")
    void testTokenRefreshMechanism() {
        // Simulate token expiry by setting expiry time in the past
        tokenManager.simulateTokenExpiry();

        // Attempt to access a protected resource, which should trigger refresh
        tokenManager.ensureTokenIsValid(); // This call should trigger the refresh logic

        // Verify that a new access token has been obtained
        assertNotNull(tokenManager.getAccessToken(), "Access token should not be null after refresh attempt.");
        assertFalse(tokenManager.isAccessTokenExpired(), "New access token should not be expired.");

        // Make a call with the refreshed token
        Response response = given()
                .header("Authorization", "Bearer " + tokenManager.getAccessToken())
                .when()
                .get(PROTECTED_RESOURCE_ENDPOINT)
                .then()
                .extract().response();

        assertEquals(200, response.statusCode(), "Should access protected resource successfully with refreshed token.");
        assertTrue(response.body().asString().contains("Welcome, authorized user"), "Response should indicate successful access.");
    }

    // --- TokenManager Class ---
    private static class TokenManager {
        private String accessToken;
        private String refreshToken;
        private Instant accessTokenExpiryTime; // Store when the access token expires

        // Method to perform initial authentication
        public void authenticate(String username, String password) {
            Response authResponse = given()
                    .contentType("application/json")
                    .body(String.format("{"username": "%s", "password": "%s"}", username, password))
                    .when()
                    .post(AUTH_ENDPOINT)
                    .then()
                    .statusCode(200)
                    .extract().response();

            this.accessToken = authResponse.jsonPath().getString("accessToken");
            this.refreshToken = authResponse.jsonPath().getString("refreshToken");
            // Assuming accessTokenExpiresIn is in seconds from the current time
            long expiresInSeconds = authResponse.jsonPath().getLong("accessTokenExpiresIn");
            this.accessTokenExpiryTime = Instant.now().plusSeconds(expiresInSeconds - 60); // 60 seconds buffer
            System.out.println("Authenticated. Access Token: " + accessToken.substring(0,10) + "..., Expires: " + accessTokenExpiryTime);
        }

        // Method to refresh the access token using the refresh token
        private void refreshAccessToken() {
            if (refreshToken == null) {
                throw new IllegalStateException("Refresh token is not available. Cannot refresh.");
            }

            System.out.println("Access token expired, attempting to refresh...");
            Response refreshResponse = given()
                    .contentType("application/json")
                    .body(String.format("{"refreshToken": "%s"}", refreshToken))
                    .when()
                    .post(REFRESH_ENDPOINT)
                    .then()
                    .statusCode(200)
                    .extract().response();

            this.accessToken = refreshResponse.jsonPath().getString("newAccessToken");
            // Refresh token might also be refreshed, update if provided in response
            String newRefreshToken = refreshResponse.jsonPath().getString("newRefreshToken");
            if (newRefreshToken != null && !newRefreshToken.isEmpty()) {
                this.refreshToken = newRefreshToken;
            }
            long expiresInSeconds = refreshResponse.jsonPath().getLong("newAccessTokenExpiresIn");
            this.accessTokenExpiryTime = Instant.now().plusSeconds(expiresInSeconds - 60); // 60 seconds buffer
            System.out.println("Token refreshed. New Access Token: " + accessToken.substring(0,10) + "..., Expires: " + accessTokenExpiryTime);
        }

        // Checks if the current access token is expired
        public boolean isAccessTokenExpired() {
            // Add a small buffer to avoid using a token that's about to expire
            return accessTokenExpiryTime == null || Instant.now().isAfter(accessTokenExpiryTime);
        }

        // Ensures the token is valid, refreshing if necessary
        public void ensureTokenIsValid() {
            if (isAccessTokenExpired()) {
                refreshAccessToken();
            }
            if (accessToken == null) {
                throw new IllegalStateException("Access token is null after refresh attempt. Re-authentication might be needed.");
            }
        }

        public String getAccessToken() {
            return accessToken;
        }

        public String getRefreshToken() {
            return refreshToken;
        }

        // Utility for testing purposes: simulates immediate token expiry
        public void simulateTokenExpiry() {
            this.accessTokenExpiryTime = Instant.now().minusSeconds(1);
            System.out.println("Simulated token expiry. Current token now expired.");
        }
    }
}
```

**Note**: The above code assumes a hypothetical API with `/auth/login`, `/auth/refresh`, and `/api/v1/protected` endpoints. You would need to replace these with your actual API endpoints and modify the JSON parsing based on your API's response structure. The `accessTokenExpiresIn` from the API response is crucial for `accessTokenExpiryTime` calculation. For JWTs, you can also decode the token to get the `exp` (expiration time) claim.

## Best Practices
-   **Centralize Token Management**: Create a dedicated class (like `TokenManager`) to handle all token-related operations (generation, storage, refresh, validation). This promotes reusability and maintainability.
-   **Automate Refresh**: Implement automatic token refresh logic to avoid manual re-authentication during test execution, especially for long-running test suites.
-   **Handle Expired Tokens Gracefully**: Your framework should catch 401 Unauthorized errors and attempt to refresh the token. If refresh fails, it should then attempt a full re-authentication, or mark the test as failed.
-   **Secure Token Storage**: In a real application, tokens should be stored securely (e.g., in memory, encrypted, or in secure storage mechanisms). For test automation, keeping them in memory for the duration of the test run is generally acceptable but be mindful of logging tokens.
-   **Short Access Token Lifespan**: Access tokens should have a short expiry (e.g., 5-15 minutes) for security. Refresh tokens can have a longer lifespan.
-   **Refresh Token Rotation**: Implement refresh token rotation where each refresh request returns a *new* refresh token. This enhances security by making replay attacks harder.
-   **Error Handling**: Implement robust error handling for authentication and refresh failures (e.g., invalid credentials, expired refresh token, network issues).
-   **Idempotency for Initial Login**: Ensure that calling the initial login method multiple times doesn't cause issues; it should either return existing valid tokens or re-authenticate.
-   **Configuration**: Externalize API endpoints, credentials, and token expiry buffers into configuration files.

## Common Pitfalls
-   **Hardcoding Tokens**: Never hardcode access or refresh tokens directly in your test code. They are dynamic and sensitive.
-   **Ignoring Token Expiry**: Not handling token expiry leads to flaky tests that randomly fail with 401 errors.
-   **Using Refresh Token as Access Token**: Misunderstanding the role of each token and incorrectly using a refresh token for resource access.
-   **Exposing Tokens in Logs**: Accidentally logging sensitive tokens in plain text. Ensure your logging configuration is secure.
-   **No Refresh Token Strategy**: Only generating an access token without a refresh mechanism, forcing a full re-login for each test scenario.
-   **Thread Safety Issues**: If tests run in parallel and share a single `TokenManager` instance, ensure it's thread-safe or use a thread-local approach.
-   **Ignoring Token Revocation**: Not accounting for scenarios where tokens (especially refresh tokens) might be revoked by the server, requiring a full re-authentication.

## Interview Questions & Answers
1.  **Q: Explain the difference between an access token and a refresh token. Why do we need both?**
    **A:** An **access token** is a credential that grants access to specific resources. It has a short lifespan for security reasons. A **refresh token** is a long-lived credential used to obtain a new access token once the current one expires, without requiring the user to re-enter their credentials. We need both to balance security (short-lived access tokens reduce the window for compromise) and user experience (long-lived refresh tokens avoid frequent re-authentication).

2.  **Q: How would you design an automated test suite to handle API authentication with expiring tokens?**
    **A:** I would implement a dedicated `AuthenticationService` or `TokenManager` class responsible for:
    -   Initial login and obtaining both access and refresh tokens.
    -   Storing these tokens (e.g., in a static variable, a shared context, or a thread-local storage for parallel tests).
    -   A method to check the validity/expiry of the current access token. This could involve decoding a JWT's `exp` claim or checking a stored expiry timestamp.
    -   A `refreshToken()` method that uses the refresh token to call the API's refresh endpoint and update the stored access token (and refresh token if it rotates).
    -   A wrapper around API calls that first calls `ensureTokenIsValid()` (which triggers refresh if needed) before adding the access token to the `Authorization` header.

3.  **Q: What are the security considerations when handling API tokens in test automation?**
    **A:**
    -   **Avoid hardcoding**: Credentials and tokens should never be hardcoded.
    -   **Secure storage**: Tokens should be kept in memory for the shortest possible duration. Avoid writing them to disk unless encrypted.
    -   **Logging**: Be careful not to log tokens in plain text, especially in CI/CD environments. Use secure logging practices.
    -   **Scope of tokens**: Ensure test tokens have only the necessary permissions.
    -   **Rotation**: Implement refresh token rotation if the API supports it.
    -   **Cleanup**: Ensure tokens are not left lingering or exposed after test execution.

## Hands-on Exercise
**Scenario**: You are testing an e-commerce API. The API requires a `Bearer` token for all protected endpoints. The login endpoint `/auth/login` returns an `accessToken` and `refreshToken` along with `expiresInSeconds`. The `/auth/refresh` endpoint takes the `refreshToken` and returns a `newAccessToken` and `newRefreshToken`.

**Task**:
1.  Set up a dummy API server (e.g., using `json-server`, `MockServer`, or a simple Spring Boot app) that mimics the login and refresh endpoints.
    -   `/auth/login`: Accepts `username` and `password`, returns `accessToken`, `refreshToken`, `accessTokenExpiresIn` (e.g., 300 seconds).
    -   `/auth/refresh`: Accepts `refreshToken`, returns `newAccessToken`, `newRefreshToken`, `newAccessTokenExpiresIn`.
    -   `/api/products`: A protected endpoint that returns a list of products if a valid `Bearer` token is provided.
2.  Extend the provided `ApiTokenRefreshTest` and `TokenManager` to:
    -   Introduce a helper method that waits until the token is *actually* expired (e.g., using `Thread.sleep` based on `accessTokenExpiryTime`).
    -   After simulating expiry and before calling `ensureTokenIsValid()`, make an *intentional* call to a protected endpoint and assert that it returns `401 Unauthorized`.
    -   Then, call `ensureTokenIsValid()` and assert that the subsequent call to the protected endpoint is successful (200 OK) with the newly refreshed token.

## Additional Resources
-   **OAuth 2.0 Simplified**: [https://oauth.net/2/](https://oauth.net/2/)
-   **JWT Introduction**: [https://jwt.io/introduction](https://jwt.io/introduction)
-   **Rest Assured Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Okta Developer - OAuth 2.0 and OpenID Connect**: [https://developer.okta.com/blog/2019/10/21/what-is-oauth2-and-openid-connect](https://developer.okta.com/blog/2019/10/21/what-is-oauth2-and-openid-connect)