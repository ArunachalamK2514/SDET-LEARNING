# api-4.3-ac1.md

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
---
# api-4.3-ac2.md

# OAuth 2.0 Authentication Flow in API Testing

## Overview
OAuth 2.0 (Open Authorization) is an industry-standard protocol for authorization. It allows a third-party application to obtain limited access to an HTTP service, either on behalf of a resource owner by orchestrating an approval interaction between the resource owner and the HTTP service, or by allowing the third-party application to obtain access on its own behalf. For SDETs, understanding and testing OAuth 2.0 secured APIs is crucial as it's the predominant method for securing modern web and mobile application APIs. This document covers how to implement and test an OAuth 2.0 authentication flow, specifically focusing on obtaining and using access tokens.

## Detailed Explanation
OAuth 2.0 defines four roles:
1.  **Resource Owner:** The user who owns the protected resources.
2.  **Client:** The application requesting access to the resource owner's protected resources.
3.  **Authorization Server:** The server that authenticates the resource owner and issues access tokens to the client.
4.  **Resource Server:** The server hosting the protected resources, capable of accepting and responding to protected resource requests using access tokens.

The core idea is that the client application gets an "access token" from an Authorization Server, and then uses this token to access protected resources on a Resource Server without ever needing the user's (Resource Owner's) credentials directly.

There are several "grant types" or "flows" in OAuth 2.0, each designed for different client types and use cases (e.g., Authorization Code, Client Credentials, Implicit, Password, Device Code). For API testing, we often simulate the client's behavior, which typically involves:
1.  **Calling the Token Endpoint:** The client (our test automation script) sends a request to the Authorization Server's token endpoint to obtain an access token. This request usually includes client credentials (client ID, client secret) and specifies the grant type and requested scopes.
2.  **Using the Access Token:** Once an access token is received, the client includes this token in the `Authorization` header of subsequent requests to the Resource Server (usually as a `Bearer` token).
3.  **Verifying Access:** The Resource Server validates the access token and, if valid, grants access to the protected resource. Our test verifies that the protected resource is accessible and that the response is as expected.

## Code Implementation
This example uses **REST Assured** in Java to demonstrate the Client Credentials grant type, which is common for machine-to-machine authentication where a client needs to access its own protected resources or resources it has been granted access to.

```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;

public class OAuth2FlowTest {

    private static final String TOKEN_ENDPOINT = "https://your-oauth2-server.com/oauth/token"; // Replace with actual token endpoint
    private static final String PROTECTED_RESOURCE_URL = "https://your-resource-server.com/api/protected"; // Replace with actual protected resource URL
    private static final String CLIENT_ID = "your-client-id"; // Replace with your client ID
    private static final String CLIENT_SECRET = "your-client-secret"; // Replace with your client secret
    private static final String SCOPE = "read write"; // Replace with required scopes

    private String accessToken;

    @BeforeClass
    public void setup() {
        // Log all requests and responses for debugging
        RestAssured.filters(new io.restassured.filter.log.RequestLoggingFilter(),
                            new io.restassured.filter.log.ResponseLoggingFilter());
    }

    @Test(priority = 1, description = "Obtain Access Token using Client Credentials Grant")
    public void testGetAccessToken() {
        Response response = given()
            .urlEncodingEnabled(true) // Ensures form parameters are URL encoded
            .param("grant_type", "client_credentials")
            .param("client_id", CLIENT_ID)
            .param("client_secret", CLIENT_SECRET)
            .param("scope", SCOPE) // Optional: specify scopes if required by your OAuth server
        .when()
            .post(TOKEN_ENDPOINT);

        response.then()
            .statusCode(200); // Expect a 200 OK for successful token retrieval

        // Extract the access token from the response
        accessToken = response.jsonPath().getString("access_token");
        Assert.assertNotNull(accessToken, "Access token should not be null");
        System.out.println("Obtained Access Token: " + accessToken);
    }

    @Test(priority = 2, description = "Access Protected Resource using Obtained Access Token")
    public void testAccessProtectedResource() {
        // Ensure access token was obtained in the previous step
        Assert.assertNotNull(accessToken, "Access token is null, cannot proceed to protected resource");

        Response response = given()
            .header("Authorization", "Bearer " + accessToken) // Include the access token in the Authorization header
        .when()
            .get(PROTECTED_RESOURCE_URL);

        response.then()
            .statusCode(200) // Expect a 200 OK for successful access to protected resource
            .body("message", org.hamcrest.Matchers.equalTo("You have access to the protected resource!")); // Verify content
        
        System.out.println("Accessed Protected Resource successfully.");
    }

    @Test(priority = 3, description = "Verify unauthorized access without token")
    public void testUnauthorizedAccess() {
        Response response = given()
        .when()
            .get(PROTECTED_RESOURCE_URL);

        response.then()
            .statusCode(401); // Expect 401 Unauthorized without a token
        System.out.println("Verified unauthorized access without token.");
    }

    // Example of using OAuth 2.0 with RestAssured's built-in oauth2 method (simpler for some flows)
    // Note: This method is often used for Authorization Code flow where RestAssured handles redirect.
    // For Client Credentials, direct POST to token endpoint is typically clearer as shown above.
    @Test(enabled = false, description = "Alternative: Use RestAssured's built-in oauth2 method (for certain flows)")
    public void testAccessProtectedResourceUsingRestAssuredOAuth2() {
        // This is a simplified usage and might not fit all OAuth 2.0 grant types directly.
        // It's more suited for flows where RestAssured can manage redirects and token refresh.
        // For Client Credentials, the direct token endpoint call is more explicit.
        given()
            .auth().oauth2(accessToken) // Directly uses the access token
        .when()
            .get(PROTECTED_RESOURCE_URL)
        .then()
            .statusCode(200)
            .body("message", org.hamcrest.Matchers.equalTo("You have access to the protected resource!"));
    }
}
```

**Note:** For this code to be runnable, you would need to:
1.  **Replace Placeholders:** Update `TOKEN_ENDPOINT`, `PROTECTED_RESOURCE_URL`, `CLIENT_ID`, `CLIENT_SECRET`, and `SCOPE` with actual values from your OAuth 2.0 provider.
2.  **Add Dependencies:** Include `rest-assured`, `testng`, and `hamcrest-all` dependencies in your `pom.xml` (Maven) or `build.gradle` (Gradle).

## Best Practices
-   **Environment Variables:** Never hardcode sensitive information like client IDs or secrets directly in your test code. Use environment variables or a secure configuration management system.
-   **Token Expiration & Refresh:** Be aware of token expiration. For longer test runs or specific scenarios, consider implementing logic to refresh tokens if the OAuth provider supports refresh tokens.
-   **Scope Validation:** Always request and validate the minimum necessary scopes required for the operations your client performs.
-   **Error Handling:** Implement robust error handling for token acquisition and resource access, differentiating between network issues, invalid credentials, expired tokens, and insufficient permissions.
-   **Parallel Execution:** If running tests in parallel, ensure that token acquisition is handled safely (e.g., each test thread gets its own token or a shared token is managed concurrently).
-   **Clean Up:** If your tests create or modify resources, ensure proper cleanup after tests complete.

## Common Pitfalls
-   **Hardcoding Credentials:** Storing `CLIENT_ID` and `CLIENT_SECRET` directly in code, leading to security vulnerabilities.
-   **Ignoring Token Expiration:** Using an expired token without a refresh mechanism, leading to `401 Unauthorized` errors.
-   **Over-Scoping:** Requesting more permissions than necessary, increasing the attack surface if the token is compromised.
-   **Improper `Authorization` Header:** Incorrectly formatting the `Authorization` header (e.g., missing "Bearer " prefix), causing authentication failures.
-   **Testing against Production:** Using live production environments for extensive OAuth testing, which can lead to rate limiting, account lockouts, or unintended data modifications. Use dedicated test environments.
-   **Client vs. User Authentication:** Confusing OAuth 2.0 (authorization) with OpenID Connect (authentication). OAuth 2.0 grants access, OpenID Connect verifies identity.

## Interview Questions & Answers
1.  **Q: What is OAuth 2.0 and why is it important in API security?**
    **A:** OAuth 2.0 is an authorization framework that allows third-party applications to obtain limited access to a user's resources on an HTTP service without exposing the user's credentials. It's crucial for API security because it decouples authentication from authorization, enabling secure delegation of access and protecting user data by using tokens instead of passwords.

2.  **Q: Explain the difference between OAuth 2.0 and OpenID Connect.**
    **A:** OAuth 2.0 is an authorization framework, meaning it's about *granting access* to protected resources. It answers the question, "Can this application access this resource on behalf of the user?" OpenID Connect (OIDC) is an authentication layer built *on top* of OAuth 2.0. It's about *verifying identity*. It answers the question, "Who is this user?" OIDC provides an ID token that contains information about the authenticated user.

3.  **Q: How would you test an API secured with OAuth 2.0 using an automation framework?**
    **A:** I would typically follow these steps:
    *   **Obtain Client Credentials:** Securely retrieve `client_id` and `client_secret` (and potentially username/password for certain flows) from environment variables or a configuration store.
    *   **Request Access Token:** Make an HTTP POST request to the Authorization Server's token endpoint, providing the necessary grant type parameters and client credentials.
    *   **Extract Token:** Parse the response to extract the `access_token` (and potentially `refresh_token` and `expires_in`).
    *   **Use Access Token:** Include the `access_token` in the `Authorization` header (e.g., `Authorization: Bearer <access_token>`) for all subsequent requests to protected resources on the Resource Server.
    *   **Verify Access:** Assert the HTTP status code (e.g., 200 OK) and the response body to confirm successful access and data integrity.
    *   **Test Edge Cases:** Verify unauthorized access (no token, invalid token), expired token handling, and insufficient scope scenarios.

4.  **Q: What are different "grant types" in OAuth 2.0 and when would you use them?**
    **A:** Grant types (or flows) define how a client obtains an access token. Common ones include:
    *   **Authorization Code Grant:** Most secure and widely used for confidential clients (e.g., web applications). It involves redirects through the user's browser.
    *   **Client Credentials Grant:** Used when the client is acting on its own behalf, not a user's. Ideal for machine-to-machine communication or daemon services.
    *   **Implicit Grant:** Previously used for public clients (e.g., single-page apps), but largely deprecated due to security concerns in favor of Authorization Code with PKCE.
    *   **Resource Owner Password Credentials Grant:** Used rarely and only when there's a high degree of trust between the client and the resource owner (e.g., first-party applications). Direct submission of user credentials.

## Hands-on Exercise
**Scenario:**
You are tasked with automating the testing of a banking API that uses OAuth 2.0 Client Credentials flow for internal services. The API has a token endpoint and a protected `account-details` endpoint.

**Details:**
*   **Token Endpoint:** `POST https://mock-bank-oauth.com/token`
    *   **Request Body (Form Params):**
        *   `grant_type`: `client_credentials`
        *   `client_id`: `bank_service_client`
        *   `client_secret`: `superSecretBankKey`
        *   `scope`: `read:accounts`
    *   **Successful Response (200 OK):**
        ```json
        {
            "access_token": "eyJhbGciOiJIUzI1Ni...",
            "token_type": "Bearer",
            "expires_in": 3600
        }
        ```
*   **Protected Resource Endpoint:** `GET https://mock-bank-api.com/v1/accounts/123`
    *   **Request Headers:**
        *   `Authorization`: `Bearer <access_token_from_above>`
    *   **Successful Response (200 OK):**
        ```json
        {
            "account_id": "123",
            "balance": 1500.75,
            "currency": "USD",
            "status": "active"
        }
        ```
    *   **Unauthorized Response (401 Unauthorized):** If no token or invalid token.

**Task:**
1.  Set up a new TestNG class (`BankOAuthTest.java`).
2.  Implement a test method `testGetBankAccessToken()` that calls the token endpoint and extracts the `access_token`.
3.  Implement a test method `testAccessProtectedAccountDetails()` that uses the obtained token to call the protected resource and verifies the response (status code and a key field like `account_id`).
4.  Implement a negative test `testProtectedAccountDetailsUnauthorized()` that tries to access the protected resource *without* an access token and asserts a 401 status code.

## Additional Resources
-   **The OAuth 2.0 Authorization Framework:** [https://datatracker.ietf.org/doc/html/rfc6749](https://datatracker.ietf.org/doc/html/rfc6749)
-   **OpenID Connect Core 1.0:** [https://openid.net/specs/openid-connect-core-1_0.html](https://openid.net/specs/openid-connect-core-1_0.html)
-   **REST Assured GitHub Wiki (Authentication):** [https://github.com/rest-assured/rest-assured/wiki/Usage#authentication](https://github.com/rest-assured/rest-assured/wiki/Usage#authentication)
-   **Client Credentials Grant:** [https://oauth.net/2/grant-types/client-credentials/](https://oauth.net/2/grant-types/client-credentials/)
---
# api-4.3-ac3.md

# Bearer Token Authentication in API Testing

## Overview
Bearer token authentication is a widely used security mechanism in API testing where a security token, called a "bearer token," is sent in the Authorization header of an HTTP request. The term "bearer" signifies that the token grants access to the bearer, meaning anyone in possession of the token can access the protected resources without further identification. Understanding how to implement and test APIs secured with Bearer tokens is crucial for any SDET, as it's a foundational concept in modern API security. This section will cover manual header addition, its comparison with OAuth2 helper methods, and when to use each approach.

## Detailed Explanation

Bearer tokens are typically issued by an authorization server (e.g., an OAuth 2.0 provider) after a user successfully authenticates. The client then includes this token in the `Authorization` header of subsequent requests to access protected resources on the API.

The format of the `Authorization` header is `Authorization: Bearer <token>`, where `<token>` is the actual security token (usually a JWT - JSON Web Token, but can be opaque strings).

**Steps for Bearer Token Authentication:**

1.  **Obtain Token**: First, an application or test script needs to acquire a Bearer token. This usually involves making an initial request to an authentication endpoint (e.g., `/oauth/token`) with credentials (username/password, client ID/secret) to get the token.
2.  **Include Token in Headers**: Once obtained, the token is then included in the `Authorization` header of all subsequent requests to protected API endpoints.
3.  **Server Validation**: The API server receives the request, extracts the Bearer token, validates it (e.g., checks its signature, expiration, and issuer), and if valid, grants access to the requested resource.

**Manual Header Addition vs. OAuth2 Helper Methods:**

*   **Manual Header Addition**: This involves explicitly setting the `Authorization` header with the `Bearer <token>` value in your API client or testing framework. It offers maximum flexibility and control, allowing you to handle tokens obtained from various sources or custom authentication flows.
    *   **When needed**:
        *   When your authentication flow is custom or non-standard.
        *   When you are directly provided with a token (e.g., from a backend process or a previous test step) and just need to use it.
        *   When testing specific scenarios like token expiration, invalid tokens, or missing tokens, where you need precise control over the header's content.
        *   When using tools or libraries that don't have built-in OAuth2 helper methods, or when these helpers don't fit your specific use case.

*   **OAuth2 Helper Methods**: Many API testing frameworks (like Postman, Swagger UI, or even libraries like REST Assured for Java) provide built-in helpers for OAuth 2.0. These methods automate the process of obtaining and refreshing tokens, often abstracting away the complexity of the OAuth 2.0 grant types.
    *   **When to use**:
        *   When adhering to standard OAuth 2.0 flows (e.g., Client Credentials, Authorization Code, Password Grant).
        *   To streamline test setup and reduce boilerplate code, as the framework handles token management.
        *   For integration tests where you want to simulate a full user authentication flow without manually managing tokens.

While helper methods simplify the process, understanding manual header addition is fundamental, as it's the underlying mechanism.

## Code Implementation

Here's an example using Java with Rest Assured to demonstrate manual Bearer token authentication.

```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

public class BearerTokenAuthTest {

    // Ideally, this token would be obtained from an authentication endpoint
    // or loaded from a secure configuration. For demonstration, it's hardcoded.
    // REPLACE WITH A VALID, NON-EXPIRED TOKEN FOR YOUR API
    private String bearerToken = "your_actual_bearer_token_here"; 
    private String baseUrl = "https://api.example.com"; // Replace with your API base URL

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = baseUrl;
    }

    @Test(description = "Verify access to a protected resource with a valid Bearer token")
    public void testProtectedResourceWithValidToken() {
        System.out.println("Attempting to access protected resource with valid token...");
        Response response = RestAssured.given()
                .header("Authorization", "Bearer " + bearerToken) // Manually add Bearer token header
                .when()
                .get("/protected/resource") // Replace with your protected endpoint
                .then()
                .log().body() // Log the response body for debugging
                .extract().response();

        Assert.assertEquals(response.getStatusCode(), 200, "Expected status code 200 for valid token access");
        // Further assertions based on the expected response body
        Assert.assertTrue(response.getBody().asString().contains("expected_content"), 
                          "Response body should contain expected content");
    }

    @Test(description = "Verify access to a protected resource without a Bearer token (expect 401 Unauthorized)")
    public void testProtectedResourceWithoutToken() {
        System.out.println("Attempting to access protected resource without token...");
        Response response = RestAssured.given()
                .when()
                .get("/protected/resource") // Replace with your protected endpoint
                .then()
                .log().body()
                .extract().response();

        Assert.assertEquals(response.getStatusCode(), 401, "Expected status code 401 for missing token");
    }

    @Test(description = "Verify access to a protected resource with an invalid Bearer token (expect 401 Unauthorized or 403 Forbidden)")
    public void testProtectedResourceWithInvalidToken() {
        String invalidToken = "invalid_or_expired_token";
        System.out.println("Attempting to access protected resource with invalid token...");
        Response response = RestAssured.given()
                .header("Authorization", "Bearer " + invalidToken) // Manually add an invalid token
                .when()
                .get("/protected/resource") // Replace with your protected endpoint
                .then()
                .log().body()
                .extract().response();

        // Depending on the API implementation, it could be 401 (Unauthorized) or 403 (Forbidden)
        // for an invalid token. 401 is more common for authentication failures.
        Assert.assertTrue(response.getStatusCode() == 401 || response.getStatusCode() == 403, 
                          "Expected status code 401 or 403 for invalid token");
    }
    
    // Example of using an OAuth2 helper if available (Rest Assured has specific OAuth methods)
    // This is for comparison and would typically involve a separate authentication step first
    // @Test(description = "Illustrate OAuth2 helper usage (conceptual, requires token retrieval)")
    // public void testProtectedResourceWithOAuth2Helper() {
    //     // Rest Assured has specific methods like .oauth2(token) for convenience
    //     // This still assumes 'token' is already retrieved
    //     System.out.println("Illustrating OAuth2 helper usage...");
    //     Response response = RestAssured.given()
    //             .oauth2(bearerToken) // Using RestAssured's OAuth2 helper
    //             .when()
    //             .get("/protected/resource")
    //             .then()
    //             .extract().response();
    //
    //     Assert.assertEquals(response.getStatusCode(), 200, "Expected status code 200 with OAuth2 helper");
    // }
}
```

## Best Practices
-   **Token Management**: Do not hardcode tokens in your tests. Store them in environment variables, configuration files, or better yet, dynamically obtain them from an authentication endpoint before each test run (or suite).
-   **Secure Handling**: Treat Bearer tokens as sensitive information. Avoid logging them unnecessarily or exposing them in test reports.
-   **Test Edge Cases**: Always test with valid, invalid, expired, and missing tokens to ensure robust error handling on the API side.
-   **Avoid Mixing Auth Methods**: Once you've established an authentication method (e.g., Bearer token), stick to it for the requests. Don't mix it with other methods like basic auth in the same request unless specifically required by the API design.
-   **Clear Error Messages**: Ensure your API returns meaningful error messages (e.g., "Invalid Token," "Token Expired") when authentication fails.

## Common Pitfalls
-   **Expired Tokens**: Forgetting that tokens have a limited lifespan. Tests might pass initially but fail later when the token expires. Implement token refresh mechanisms or re-obtain tokens.
-   **Incorrect Header Format**: Typos in "Bearer" or missing the space between "Bearer" and the token.
-   **Token Leakage**: Accidentally exposing tokens in logs, version control, or insecure communication.
-   **Over-reliance on UI for Token Retrieval**: In an automated testing context, always aim to get tokens via API calls, not by scraping a UI login flow, which is brittle.
-   **Not Testing Negative Scenarios**: Only testing with valid tokens. It's crucial to verify how the API handles invalid or missing tokens.

## Interview Questions & Answers
1.  **Q: What is a Bearer token and how is it used in API authentication?**
    *   **A:** A Bearer token is a credential that grants access to the bearer. It's used in API authentication by including it in the `Authorization` header of an HTTP request, typically in the format `Authorization: Bearer <token>`. The server then validates this token to grant or deny access to protected resources. It's commonly associated with OAuth 2.0.

2.  **Q: When would you choose to manually add an `Authorization` header with a Bearer token versus using an OAuth2 helper method in a testing framework?**
    *   **A:** Manual addition is preferred for custom authentication flows, when a token is directly provided, or for testing specific error scenarios (e.g., expired/invalid tokens) that require granular control over the header's content. OAuth2 helper methods are beneficial for standard OAuth 2.0 flows, offering automation and reducing boilerplate for token management in typical integration tests.

3.  **Q: How do you handle Bearer token expiration in your automated API tests?**
    *   **A:** We would typically implement a mechanism to dynamically obtain a new Bearer token before each test suite run or before a series of tests that might exceed the token's lifetime. This could involve making an API call to the authentication endpoint to get a fresh token. For longer-running tests, a token refresh mechanism might be integrated.

4.  **Q: What are the security considerations when working with Bearer tokens in an automated testing environment?**
    *   **A:** Key considerations include: never hardcoding tokens; storing them securely (e.g., environment variables, secret management tools); avoiding accidental logging or exposure in reports; and ensuring secure transmission over HTTPS. It's also important to revoke tokens if they are compromised.

## Hands-on Exercise
**Scenario**: You are testing a simple API that has a `/status` endpoint (public) and a `/profile` endpoint (protected).
**Task**:
1.  Set up a local mock API using a tool like WireMock or MockServer, or use a public test API if available (e.g., `https://postman-echo.com/headers` can show you the headers sent).
2.  Configure two endpoints:
    *   `/auth/token` (POST): This endpoint should simulate returning a JSON response containing a `bearer_token`.
    *   `/protected/profile` (GET): This endpoint should return a 200 OK with some user data if the `Authorization: Bearer <valid_token>` header is present and valid. Otherwise, it should return a 401 Unauthorized.
3.  Write an automated test using Java and Rest Assured that:
    *   Makes a POST request to `/auth/token` to obtain a Bearer token.
    *   Uses the obtained token to successfully call `/protected/profile` and asserts a 200 OK status and expected profile data.
    *   Attempts to call `/protected/profile` without any `Authorization` header and asserts a 401 Unauthorized status.
    *   Attempts to call `/protected/profile` with an invalid Bearer token and asserts a 401 Unauthorized or 403 Forbidden status.

## Additional Resources
-   **OAuth 2.0 Simplified**: [https://oauth.net/2/](https://oauth.net/2/)
-   **JWT Introduction**: [https://jwt.io/introduction](https://jwt.io/introduction)
-   **Rest Assured Documentation**: [https://rest-assured.io/](https://rest-assured.io/)
-   **Postman on Bearer Token**: [https://learning.postman.com/docs/sending-requests/authorization/bearer-token/](https://learning.postman.com/docs/sending-requests/authorization/bearer-token/)
---
# api-4.3-ac4.md

# API Key Authentication in API Testing

## Overview
API Key authentication is a simple and widely used method to secure access to APIs. It involves generating a unique alphanumeric string (the API Key) and sending it with each request to identify the client and grant access. This feature explores how to implement and test API Key authentication, focusing on common patterns where the key is sent either in the request header or as a query parameter. Understanding API Key mechanics is crucial for SDETs as it's a fundamental aspect of securing and interacting with many web services.

## Detailed Explanation
API Keys are typically generated by the API provider and assigned to a specific user or application. When a client makes a request, this key acts as a token to verify the client's identity.

There are two primary ways an API Key is commonly transmitted:

1.  **In the Request Header:** This is often preferred for security reasons. The API Key is sent within a custom header (e.g., `X-API-Key`, `Authorization`, or a custom name specified by the API documentation).
2.  **As a Query Parameter:** The API Key is appended to the URL as part of the query string (e.g., `?apiKey=YOUR_API_KEY`). While simpler to implement, it's generally less secure than headers because URLs can be logged, stored in browser history, or exposed in server logs.

Regardless of the transmission method, the API server receives the key, validates it against its stored keys, and if valid, grants access based on the permissions associated with that key.

### Identifying API Key Location (Header vs. Query Param)
To determine where to send the API Key, always refer to the API documentation. The documentation will explicitly state the parameter name (e.g., `apiKey`, `key`), its expected value format, and whether it should be in a header or query parameter.

## Code Implementation
Here are examples using Rest Assured in Java for both header and query parameter API Key authentication.

```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

public class ApiKeyAuthenticationTest {

    // --- Configuration for API Key ---
    // IMPORTANT: Replace with your actual API endpoint and API Key.
    // For demonstration, we'll use a mock API or a public API that uses API keys.
    // Example: The OpenWeatherMap API uses API keys, often as a query parameter.
    // For header-based, imagine a service like GitHub (though it uses OAuth/PATs more commonly).

    private static final String BASE_URL = "https://api.example.com"; // Replace with actual API base URL
    private static final String API_KEY_HEADER_NAME = "X-API-Key"; // Common header name
    private static final String API_KEY_QUERY_PARAM_NAME = "apiKey"; // Common query parameter name
    private static final String VALID_API_KEY = "your_valid_api_key_here"; // Replace with your actual valid API key
    private static final String INVALID_API_KEY = "invalid_api_key";
    private static final String SECURE_ENDPOINT = "/secured/data"; // An endpoint requiring authentication
    private static final String PUBLIC_ENDPOINT = "/public/info"; // An endpoint not requiring authentication

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = BASE_URL;
    }

    // --- Scenario 1: API Key in Header ---

    @Test(description = "Verify access with a valid API Key in header")
    public void testApiKeyInHeader_ValidKey() {
        given()
            .header(API_KEY_HEADER_NAME, VALID_API_KEY) // Pass the API Key in the header
        .when()
            .get(SECURE_ENDPOINT)
        .then()
            .statusCode(200) // Expect 200 OK for successful authentication and access
            .body("message", equalTo("Access granted for user")); // Example assertion
    }

    @Test(description = "Verify access denied with a missing API Key in header")
    public void testApiKeyInHeader_MissingKey() {
        given()
        // No API Key header is sent
        .when()
            .get(SECURE_ENDPOINT)
        .then()
            .statusCode(401) // Expect 401 Unauthorized or 403 Forbidden
            .body("error", equalTo("Unauthorized: API Key missing")); // Example assertion
    }

    @Test(description = "Verify access denied with an invalid API Key in header")
    public void testApiKeyInHeader_InvalidKey() {
        given()
            .header(API_KEY_HEADER_NAME, INVALID_API_KEY) // Pass an invalid API Key
        .when()
            .get(SECURE_ENDPOINT)
        .then()
            .statusCode(401) // Expect 401 Unauthorized or 403 Forbidden
            .body("error", equalTo("Unauthorized: Invalid API Key")); // Example assertion
    }

    // --- Scenario 2: API Key as Query Parameter ---

    // Example using a real public API: OpenWeatherMap (replace with your actual API key)
    // Note: OpenWeatherMap usually requires a city name as well. This is a simplified example.
    private static final String OPENWEATHER_BASE_URL = "https://api.openweathermap.org/data/2.5";
    private static final String OPENWEATHER_CURRENT_WEATHER_ENDPOINT = "/weather";
    private static final String OPENWEATHER_VALID_API_KEY = "YOUR_OPENWEATHER_API_KEY"; // Get from openweathermap.org

    @Test(description = "Verify access with a valid API Key as query parameter (OpenWeatherMap example)")
    public void testApiKeyAsQueryParam_ValidKey() {
        // Temporarily change base URI for this specific test if needed
        RestAssured.baseURI = OPENWEATHER_BASE_URL;

        given()
            .queryParam("q", "London") // Additional required query param for OpenWeatherMap
            .queryParam(API_KEY_QUERY_PARAM_NAME, OPENWEATHER_VALID_API_KEY) // Pass API Key as query parameter
        .when()
            .get(OPENWEATHER_CURRENT_WEATHER_ENDPOINT)
        .then()
            .statusCode(200)
            .body("name", equalTo("London")); // Assert on a specific part of the response
        
        // Reset base URI if necessary
        RestAssured.baseURI = BASE_URL;
    }

    @Test(description = "Verify access denied with a missing API Key as query parameter")
    public void testApiKeyAsQueryParam_MissingKey() {
        // Use the original BASE_URL and SECURE_ENDPOINT for this general test case
        given()
            .queryParam("param1", "value1") // Other legitimate query params, but no API Key
        .when()
            .get(SECURE_ENDPOINT)
        .then()
            .statusCode(401) // Expect 401 Unauthorized or 403 Forbidden
            .body("error", equalTo("Unauthorized: API Key missing"));
    }

    @Test(description = "Verify access denied with an invalid API Key as query parameter")
    public void testApiKeyAsQueryParam_InvalidKey() {
        // Use the original BASE_URL and SECURE_ENDPOINT for this general test case
        given()
            .queryParam(API_KEY_QUERY_PARAM_NAME, INVALID_API_KEY) // Pass an invalid API Key
        .when()
            .get(SECURE_ENDPOINT)
        .then()
            .statusCode(401) // Expect 401 Unauthorized or 403 Forbidden
            .body("error", equalTo("Unauthorized: Invalid API Key"));
    }

    // --- Verification of public endpoints (no API key needed) ---

    @Test(description = "Verify access to public endpoint without API Key")
    public void testPublicEndpoint_NoAuthRequired() {
        given()
        .when()
            .get(PUBLIC_ENDPOINT)
        .then()
            .statusCode(200)
            .body("status", equalTo("public access ok")); // Example assertion for public endpoint
    }
}
```

## Best Practices
-   **Treat API Keys as Sensitive Information:** Never hardcode API Keys directly into your source code. Use environment variables, configuration files (e.g., `application.properties`, `.env`), or secure secrets management systems (e.g., HashiCorp Vault, AWS Secrets Manager).
-   **Use Headers Over Query Parameters:** When possible, transmit API Keys in request headers (`X-API-Key`, `Authorization`) rather than as query parameters to reduce exposure in logs, browser history, and referer headers.
-   **Least Privilege Principle:** Generate API Keys with the minimum necessary permissions. If a key only needs read access to a specific resource, it should not have write or delete permissions.
-   **Regular Rotation:** Periodically rotate API Keys to minimize the window of exposure if a key is compromised.
-   **Rate Limiting:** Implement rate limiting on the server side to prevent abuse, even with valid API Keys.
-   **IP Whitelisting:** If your API allows it, restrict API Key usage to specific IP addresses to add an extra layer of security.
-   **Error Handling:** Ensure your API provides clear, but not overly descriptive, error messages for authentication failures (e.g., "Unauthorized", "Invalid API Key") without revealing too much information to potential attackers.

## Common Pitfalls
-   **Hardcoding API Keys:** Leads to security vulnerabilities if the code is committed to a public repository or shared inadvertently.
-   **Logging API Keys:** Accidentally logging requests that contain API Keys (especially in query parameters) can expose them in server logs. Configure logging carefully.
-   **Reusing API Keys:** Using a single API Key for multiple applications or environments increases the blast radius if that key is compromised.
-   **Not Validating on Server-Side:** Relying solely on client-side security for API Keys is a critical server-side vulnerability. Always validate keys on the backend.
-   **Using Weak API Key Generation:** Generating predictable or easily guessable API Keys makes them susceptible to brute-force attacks. Use strong, random, and sufficiently long keys.

## Interview Questions & Answers
1.  **Q: What is API Key authentication and when would you use it?**
    **A:** API Key authentication is a simple token-based mechanism where a unique key is sent with each API request to identify the client. It's suitable for situations requiring basic client identification and access control, often for public APIs, machine-to-machine communication, or when a full OAuth flow is overkill. It's less secure than OAuth for user authentication but provides a straightforward way to manage access for applications.

2.  **Q: What are the security considerations when using API Keys?**
    **A:** API Keys should be treated like passwords. Key considerations include: not hardcoding them, storing them securely (e.g., environment variables, secrets management), transmitting them via headers (not query parameters) to prevent logging exposure, rotating them regularly, and applying the principle of least privilege. Rate limiting and IP whitelisting can further enhance security.

3.  **Q: How do you handle a compromised API Key?**
    **A:** If an API Key is suspected to be compromised, the first step is to immediately revoke it on the API provider's side. Then, investigate the source of the compromise, update any affected systems with a new, securely managed key, and review security practices to prevent future incidents.

4.  **Q: Differentiate between sending an API Key in a header versus a query parameter.**
    **A:** When sent in a header (e.g., `X-API-Key`), the key is part of the HTTP request headers and is generally more secure as it's less likely to be logged by intermediaries or appear in URLs. When sent as a query parameter (e.g., `?apiKey=abc`), it's appended to the URL. This is less secure because URLs are often logged, can appear in browser history, and might be exposed in referrer headers. Headers are the preferred method for sensitive data like API Keys.

## Hands-on Exercise
1.  **Obtain an API Key:** Sign up for a free OpenWeatherMap API key (or similar public API that uses keys).
2.  **Modify the Example Code:**
    *   Update `OPENWEATHER_VALID_API_KEY` in the provided Java code with your actual OpenWeatherMap API key.
    *   Modify the `testApiKeyAsQueryParam_ValidKey` method to fetch weather data for your favorite city.
3.  **Create a Mock API (Optional but Recommended):** Use a tool like Postman Mock Servers, Mockoon, or WireMock to set up a simple mock API that expects an API Key in a header (e.g., `X-API-Key`).
    *   Configure one endpoint to return 200 OK with a valid key.
    *   Configure another endpoint to return 401 Unauthorized without a key or with an invalid key.
4.  **Write Tests for Mock API:** Extend the `ApiKeyAuthenticationTest` class to include tests that interact with your mock API, verifying both successful authentication and authentication failures for header-based API Keys.

## Additional Resources
-   **OWASP API Security Top 10:** [https://owasp.org/www-project-api-security/](https://owasp.org/www-project-api-security/) (Provides broader API security context, including authentication)
-   **Rest Assured Documentation:** [https://rest-assured.io/](https://rest-assured.io/) (Official documentation for the Java HTTP client used in examples)
-   **OpenWeatherMap API:** [https://openweathermap.org/api](https://openweathermap.org/api) (A public API you can use for hands-on practice with API keys)
-   **Baeldung Tutorial on Rest Assured Authentication:** [https://www.baeldung.com/rest-assured-authentication](https://www.baeldung.com/rest-assured-authentication) (Covers various authentication methods with Rest Assured)
---
# api-4.3-ac5.md

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
---
# api-4.3-ac6.md

# API Testing - Authentication Token Management

## Overview
In API test automation, efficiently managing authentication tokens is crucial for writing robust, maintainable, and fast tests. Repeatedly logging in or generating new tokens for every test can significantly slow down test execution and introduce unnecessary complexity. This document outlines strategies for storing and reusing authentication tokens across multiple tests, ensuring test efficiency and better resource utilization.

## Detailed Explanation
Authentication tokens (like JWTs, OAuth tokens, or session IDs) are credentials that verify a client's identity to an API. Once obtained, these tokens typically have a limited lifespan and need to be included in subsequent API requests. For test automation, the goal is to acquire a token once per test suite or a logical group of tests and then reuse it until it expires or the test run completes.

The core idea is to generate the token in a setup phase that runs infrequently (e.g., once before the entire test suite) and then make this token accessible to all test methods.

### Implementation Strategy:
1.  **Token Generation**: This should occur in a method annotated with `@BeforeSuite` (TestNG) or `@BeforeAll` (JUnit 5). This ensures the token is generated only once for the entire test run, minimizing overhead.
2.  **Token Storage**: The generated token needs to be stored in a way that is accessible statically or via a Singleton pattern. A `static` variable is a straightforward approach for sharing data across different test classes within the same JVM process. A Singleton pattern provides more control and can encapsulate token refresh logic.
3.  **Token Reuse**: All `@Test` methods requiring authentication will retrieve this stored token and include it in their API requests (e.g., in an `Authorization` header).

## Code Implementation
Here's an example using TestNG and `RestAssured` for API calls, demonstrating how to generate and reuse an authentication token.

```java
import io.restassured.RestAssured;
import io.restassured.response.Response;
import org.testng.annotations.BeforeSuite;
import org.testng.annotations.Test;
import org.testng.Assert;

public class AuthTokenManager {

    // A static variable to hold the authentication token
    private static String authToken;

    // --- Singleton Pattern for Token Management (Optional, but good practice) ---
    // In a more complex scenario, you might want a dedicated manager:
    /*
    public static class TokenSingleton {
        private static TokenSingleton instance;
        private String token;

        private TokenSingleton() {
            // Private constructor to prevent instantiation
        }

        public static synchronized TokenSingleton getInstance() {
            if (instance == null) {
                instance = new TokenSingleton();
            }
            return instance;
        }

        public String getToken() {
            // Add logic here to refresh token if expired
            if (token == null || isTokenExpired(token)) { // isTokenExpired needs implementation
                this.token = generateNewToken();
            }
            return token;
        }

        private String generateNewToken() {
            System.out.println("Generating new token via Singleton...");
            // Simulate API call to get token
            Response authResponse = RestAssured.given()
                    .contentType("application/json")
                    .body("{ "username": "testuser", "password": "password123" }")
                    .post("https://api.example.com/auth/login"); // Replace with your auth endpoint
            return authResponse.jsonPath().getString("token");
        }

        // Dummy method for demonstration - real implementation would parse JWT or check expiry
        private boolean isTokenExpired(String token) {
            // Implement actual token expiry check here (e.g., decode JWT and check exp claim)
            return false; // For now, assume it never expires
        }
    }
    */
    // -------------------------------------------------------------------------


    /**
     * This method runs once before the entire test suite.
     * It's responsible for generating and storing the authentication token.
     */
    @BeforeSuite
    public void setupAuthToken() {
        System.out.println("Running @BeforeSuite: Generating authentication token...");
        // This should be your actual API endpoint for authentication
        Response authResponse = RestAssured.given()
                .contentType("application/json")
                .body("{ "username": "testuser", "password": "password123" }") // Replace with actual credentials
                .post("https://api.example.com/auth/login"); // Replace with your authentication endpoint

        // Assert that the authentication was successful
        authResponse.then().statusCode(200);
        authToken = authResponse.jsonPath().getString("token"); // Extract the token

        Assert.assertNotNull(authToken, "Authentication token should not be null after generation.");
        System.out.println("Authentication token generated: " + authToken.substring(0, 20) + "..."); // Print first 20 chars
    }

    /**
     * Example test method that reuses the authentication token.
     */
    @Test
    public void testGetUserDetails() {
        System.out.println("Running testGetUserDetails: Reusing token...");
        Assert.assertNotNull(authToken, "Token should be available for test methods.");

        Response userDetailsResponse = RestAssured.given()
                .header("Authorization", "Bearer " + authToken) // Add the token to the Authorization header
                .get("https://api.example.com/users/123"); // Replace with your user details endpoint

        userDetailsResponse.then().statusCode(200);
        Assert.assertEquals(userDetailsResponse.jsonPath().getString("id"), "123");
        System.out.println("testGetUserDetails passed. Response: " + userDetailsResponse.asString());
    }

    /**
     * Another example test method reusing the same token.
     */
    @Test
    public void testGetProductList() {
        System.out.println("Running testGetProductList: Reusing token...");
        Assert.assertNotNull(authToken, "Token should be available for test methods.");

        Response productListResponse = RestAssured.given()
                .header("Authorization", "Bearer " + authToken)
                .get("https://api.example.com/products"); // Replace with your product list endpoint

        productListResponse.then().statusCode(200);
        Assert.assertTrue(productListResponse.jsonPath().getList("products").size() > 0);
        System.out.println("testGetProductList passed. Response: " + productListResponse.asString());
    }

    // You can add more test methods that utilize the 'authToken'
}
```

## Best Practices
-   **Use `@BeforeSuite` (TestNG) or `@BeforeAll` (JUnit 5)**: This ensures the token generation happens only once for the entire test run, significantly improving performance.
-   **Centralized Token Storage**: Use a `static` variable or a Singleton class to store the token, making it easily accessible across all test classes and methods.
-   **Token Refresh Logic**: For long-running test suites or tokens with short expiry, implement logic within your token manager to refresh the token before it expires. This can be integrated into the `getToken()` method of a Singleton.
-   **Secure Credentials**: Never hardcode sensitive credentials directly in your code. Use environment variables, secure configuration files, or a secrets management system.
-   **Error Handling**: Implement robust error handling for token generation failures. If token generation fails, subsequent tests will also fail, and it's important to have clear error messages.
-   **Concurrency Considerations**: If tests run in parallel, ensure your token management mechanism is thread-safe (e.g., using `synchronized` blocks in a Singleton or `ThreadLocal` if each thread needs its own token).

## Common Pitfalls
-   **Generating Token Per Test Method**: A common mistake is to generate a new token in `@BeforeMethod` or directly within each `@Test`. This is inefficient and defeats the purpose of token reuse.
-   **Hardcoding Tokens**: Using a static, hardcoded token for tests is a security vulnerability and will fail when the token expires or is revoked.
-   **Ignoring Token Expiry**: Not handling token expiry gracefully can lead to intermittent test failures, especially in long-running suites.
-   **Lack of Thread Safety**: In parallel test execution, a shared static token without proper synchronization can lead to race conditions or incorrect token usage.
-   **Poor Error Reporting**: If token generation fails, tests that depend on it will also fail. Ensure the root cause (token generation failure) is clearly reported.

## Interview Questions & Answers
1.  **Q: Why is token reuse important in API test automation?**
    **A:** Token reuse is critical for efficiency and maintainability. It reduces the overhead of repeatedly performing authentication requests, which can be time-consuming. This speeds up test execution and makes tests less flaky by centralizing the authentication mechanism.

2.  **Q: How would you implement token reuse in a Java-based API automation framework using TestNG?**
    **A:** I would use TestNG's `@BeforeSuite` annotation to generate the authentication token once at the beginning of the entire test run. The token would then be stored in a `static` variable or within a Singleton class. All subsequent `@Test` methods requiring authentication would retrieve this stored token and include it in their request headers.

3.  **Q: What are the considerations for handling token expiry when reusing tokens?**
    **A:** For tokens with a limited lifespan, a robust solution involves implementing a token refresh mechanism. This can be done by checking the token's expiry time before use (e.g., by decoding a JWT) and, if it's expired or about to expire, generating a new token. This logic can be encapsulated within a `getToken()` method of a Singleton, ensuring that a valid token is always returned.

4.  **Q: How do you ensure test stability and performance when dealing with authentication in API tests?**
    **A:** To ensure stability and performance, I would:
    *   Generate tokens once per test suite using `@BeforeSuite`.
    *   Store tokens securely and make them accessible to all tests.
    *   Implement token refresh logic for expiring tokens.
    *   Use robust error handling for authentication failures.
    *   Avoid hardcoding credentials.
    *   Ensure thread safety if tests are run in parallel.

## Hands-on Exercise
1.  Set up a new TestNG project (or integrate into an existing one).
2.  Replace the placeholder `https://api.example.com/auth/login`, `https://api.example.com/users/123`, and `https://api.example.com/products` with actual authentication and protected endpoints from a public API (e.g., a mock API or a free public API that requires authentication).
3.  Implement the `AuthTokenManager` class as shown in the `Code Implementation` section.
4.  Run the tests and observe the console output. Verify that the authentication token is generated only once (`@BeforeSuite`) and reused by multiple test methods.
5.  (Optional) Extend the `TokenSingleton` pattern and implement a dummy `isTokenExpired` method to simulate token expiry and refresh logic.

## Additional Resources
-   **TestNG Annotations**: [https://testng.org/doc/documentation-main.html#annotations](https://testng.org/doc/documentation-main.html#annotations)
-   **RestAssured Getting Started**: [https://github.com/rest-assured/rest-assured/wiki/Usage](https://github.com/rest-assured/rest-assured/wiki/Usage)
-   **Singleton Design Pattern**: [https://www.geeksforgeeks.org/singleton-class-java/](https://www.geeksforgeeks.org/singleton-class-java/)
-   **JWT Introduction**: [https://jwt.io/introduction](https://jwt.io/introduction)
---
# api-4.3-ac7.md

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
---
# api-4.3-ac8.md

# Validating 401 Unauthorized and 403 Forbidden Responses

## Overview
In the realm of API testing, validating proper error handling is as crucial as verifying successful operations. Specifically, ensuring that an API correctly returns `401 Unauthorized` and `403 Forbidden` responses for invalid or insufficient authentication/authorization attempts is fundamental for API security and robustness. A `401 Unauthorized` status indicates that the request has not been applied because it lacks valid authentication credentials for the target resource. A `403 Forbidden` status means the server understood the request but refuses to authorize it, typically due to insufficient permissions even if authentication is provided. This document delves into how to effectively test these scenarios using production-grade code, best practices, and common pitfalls.

## Detailed Explanation
Authentication is about *who you are*, and authorization is about *what you can do*.

**401 Unauthorized**:
This response should be triggered when a client attempts to access a protected resource without providing any authentication credentials, or with invalid/expired credentials. The server essentially says, "I don't know who you are, please authenticate yourself." It often includes a `WWW-Authenticate` header indicating how to authenticate.

**403 Forbidden**:
This response occurs when the client *has* authenticated (the server knows who they are), but that authenticated user does not have the necessary permissions to access the requested resource. The server says, "I know who you are, but you're not allowed to do that." This is common when a regular user tries to access an administrator-only endpoint, or when attempting an action they lack privileges for.

Testing these responses involves:
1.  **Crafting requests** that intentionally violate authentication (e.g., no token, invalid token).
2.  **Crafting requests** that intentionally violate authorization (e.g., authenticated as a standard user, but attempting to access an admin-only resource).
3.  **Asserting** that the HTTP status code returned is precisely `401` or `403` respectively.
4.  **Asserting** that the response body contains expected error messages or structures as defined in the API specification. This ensures a consistent error reporting mechanism for clients.

## Code Implementation
This example uses Java with the REST Assured library, a popular choice for API testing.

```java
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.assertEquals; // Using JUnit 5 assertion for clarity, can be TestNG's Assert.assertEquals

public class AuthErrorValidationTests {

    // Base URI for the API. In a real project, this would be loaded from configuration.
    private static final String BASE_URI = "https://api.example.com"; 
    // Example endpoints - replace with your actual API endpoints
    private static final String PROTECTED_RESOURCE_ENDPOINT = "/api/v1/protected";
    private static final String ADMIN_RESOURCE_ENDPOINT = "/api/v1/admin/users";

    // Valid credentials (for authorization tests) - NEVER hardcode in production
    private static final String VALID_USER_TOKEN = "validUserJwtToken123"; 
    private static final String INVALID_TOKEN = "invalidJwtTokenXYZ";
    private static final String EXPIRED_TOKEN = "expiredJwtTokenABC";

    @BeforeClass
    public void setup() {
        RestAssured.baseURI = BASE_URI;
        // Optionally, configure other RestAssured properties like logging
        // RestAssured.filters(new RequestLoggingFilter(), new ResponseLoggingFilter()); 
    }

    /**
     * Test case to validate 401 Unauthorized response for missing credentials.
     * Expects the API to return 401 when no authorization token is provided.
     */
    @Test
    public void testProtectedResource_NoCredentials_Returns401() {
        Response response = given()
            .contentType(ContentType.JSON)
        .when()
            .get(PROTECTED_RESOURCE_ENDPOINT)
        .then()
            .statusCode(401) // Assert HTTP 401 status code
            .extract()
            .response();

        // Further assertions on the response body, assuming a JSON error format
        response.then().body("error", equalTo("Unauthorized"));
        response.then().body("message", containsString("Authentication required"));
        System.out.println("401 Unauthorized (Missing Credentials) Response: " + response.asString());
    }

    /**
     * Test case to validate 401 Unauthorized response for invalid credentials.
     * Expects the API to return 401 when an invalid authorization token is provided.
     */
    @Test
    public void testProtectedResource_InvalidToken_Returns401() {
        Response response = given()
            .header("Authorization", "Bearer " + INVALID_TOKEN) // Provide an invalid token
            .contentType(ContentType.JSON)
        .when()
            .get(PROTECTED_RESOURCE_ENDPOINT)
        .then()
            .statusCode(401) // Assert HTTP 401 status code
            .extract()
            .response();

        response.then().body("error", equalTo("Unauthorized"));
        response.then().body("message", containsString("Invalid token"));
        System.out.println("401 Unauthorized (Invalid Token) Response: " + response.asString());
    }

    /**
     * Test case to validate 401 Unauthorized response for expired credentials.
     * Expects the API to return 401 when an expired authorization token is provided.
     */
    @Test
    public void testProtectedResource_ExpiredToken_Returns401() {
        Response response = given()
            .header("Authorization", "Bearer " + EXPIRED_TOKEN) // Provide an expired token
            .contentType(ContentType.JSON)
        .when()
            .get(PROTECTED_RESOURCE_ENDPOINT)
        .then()
            .statusCode(401) // Assert HTTP 401 status code
            .extract()
            .response();

        response.then().body("error", equalTo("Unauthorized"));
        response.then().body("message", containsString("Token expired"));
        System.out.println("401 Unauthorized (Expired Token) Response: " + response.asString());
    }

    /**
     * Test case to validate 403 Forbidden response when a regular user tries to access an admin resource.
     * Assumes 'VALID_USER_TOKEN' is for a non-admin user.
     */
    @Test
    public void testAdminResource_RegularUser_Returns403() {
        Response response = given()
            .header("Authorization", "Bearer " + VALID_USER_TOKEN) // Authenticated as a regular user
            .contentType(ContentType.JSON)
        .when()
            .get(ADMIN_RESOURCE_ENDPOINT) // Attempt to access an admin-only resource
        .then()
            .statusCode(403) // Assert HTTP 403 status code
            .extract()
            .response();

        response.then().body("error", equalTo("Forbidden"));
        response.then().body("message", containsString("Insufficient permissions"));
        System.out.println("403 Forbidden Response: " + response.asString());
    }
}
```

## Best Practices
-   **Parameterize Credentials**: Never hardcode tokens or sensitive credentials directly in tests. Use configuration files (e.g., `application.properties`, `config.json`), environment variables, or a secure vault to manage them.
-   **Clear Error Messages**: Ensure the API returns clear, developer-friendly error messages in the response body, even for authentication/authorization failures. These messages should be consistent across the API.
-   **API Specification Adherence**: Always refer to the API documentation (e.g., OpenAPI/Swagger spec) for expected error codes and response body structures. Tests should validate strict adherence to this contract.
-   **Automate Credential Generation**: For complex scenarios, integrate with identity providers or authentication services to programmatically generate valid, invalid, or expired tokens for testing.
-   **Security Context Isolation**: For every test, ensure a clean and isolated security context. Avoid tests that might interfere with each other's authentication state.
-   **Use Dedicated Test Users**: Create specific test users with various roles (e.g., regular user, admin, inactive user) to thoroughly test authorization scenarios.

## Common Pitfalls
-   **Confusing 401 and 403**: A common mistake is using `401 Unauthorized` when `403 Forbidden` is more appropriate, or vice-versa. Remember: 401 is for *unauthenticated* access, 403 is for *unauthorized* access by an authenticated entity.
-   **Revealing Too Much Information**: Error messages should be informative enough for clients but should *not* expose sensitive details about the server's internal workings or security mechanisms.
-   **Inconsistent Error Formats**: Different error responses having different JSON structures makes client-side error handling cumbersome. Standardize your API's error response format.
-   **Not Testing Edge Cases**: What happens with a malformed token? A token from a different issuer? An expired token? These edge cases are crucial for robust security.
-   **Client-Side Redirections**: Some authentication systems might redirect to a login page instead of returning a 401/403 directly. Ensure your API tests follow these redirects or assert against the initial response if redirects are not expected.
-   **Over-reliance on Status Codes**: While status codes are important, the response body often contains critical details (e.g., "invalid credentials", "permission denied") that also need validation.

## Interview Questions & Answers
1.  **Q: What is the difference between HTTP 401 Unauthorized and 403 Forbidden responses?**
    **A:** A `401 Unauthorized` response indicates that the client has not authenticated itself and lacks valid authentication credentials for the target resource. The server doesn't know who the client is. It often suggests how to authenticate. In contrast, a `403 Forbidden` response means the client *has* authenticated, but the server understands the request and refuses to fulfill it because the authenticated user lacks the necessary authorization or permissions for that specific resource or action. The server knows who the client is, but they're not allowed.

2.  **Q: How would you test an API to ensure it correctly handles authorization for different user roles?**
    **A:** I would create test accounts for each relevant user role (e.g., `admin`, `standard user`, `guest`). Then, for each protected endpoint, I would:
    *   Attempt to access it as a `guest` (unauthenticated) user, expecting a `401 Unauthorized`.
    *   Attempt to access it as a `standard user` for resources they *should* have access to (expecting `200 OK` or `20x` success) and for resources they *should not* have access to (expecting `403 Forbidden`).
    *   Attempt to access it as an `admin` user for all resources, expecting `200 OK` or `20x` success, especially for admin-only resources.
    I would also validate the content of the error messages to ensure they are consistent and informative.

3.  **Q: You've implemented tests for 401 and 403. What are some common security vulnerabilities these tests help prevent?**
    **A:** These tests help prevent:
    *   **Broken Access Control**: Ensuring users cannot access resources or perform actions they are not authorized for (e.g., a regular user deleting another user's account or accessing admin panels).
    *   **Authentication Bypass**: Verifying that without proper authentication (or with invalid credentials), protected resources remain inaccessible.
    *   **Information Disclosure**: Preventing the API from revealing sensitive data in error messages for authentication/authorization failures, which could be exploited by attackers.
    *   **Insecure Direct Object References (IDOR)**: While 403 specifically, by ensuring one user cannot access another user's data by simply changing an ID in the URL.

## Hands-on Exercise
**Scenario**: You are testing a simple blogging platform API.

**Endpoints**:
*   `GET /posts`: Publicly accessible (no authentication required).
*   `GET /posts/{id}`: Publicly accessible.
*   `POST /posts`: Requires `USER` role.
*   `PUT /posts/{id}`: Requires `USER` role and ownership of the post.
*   `DELETE /posts/{id}`: Requires `ADMIN` role.
*   `GET /admin/dashboard`: Requires `ADMIN` role.

**Tasks**:
1.  Write a test that attempts to `POST /posts` without any authentication token and asserts a `401 Unauthorized` response.
2.  Write a test that attempts to `DELETE /posts/{id}` (use a dummy ID like `123`) with a `USER` role token and asserts a `403 Forbidden` response.
3.  Modify the provided `AuthErrorValidationTests` class to include these two new test cases.
4.  Assume the `401` response body for missing/invalid token is `{ "status": 401, "message": "Authentication token missing or invalid" }`.
5.  Assume the `403` response body for insufficient permissions is `{ "status": 403, "message": "You do not have permission to perform this action" }`.

## Additional Resources
-   **MDN Web Docs - HTTP response status codes**: [https://developer.mozilla.org/en-US/docs/Web/HTTP/Status](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
-   **OWASP Top 10 - Broken Access Control**: [https://owasp.org/www-project-top-ten/2017/A5_2017-Broken_Access_Control](https://owasp.org/www-project-top-ten/2017/A5_2017-Broken_Access_Control)
-   **REST Assured Official Documentation**: [http://rest-assured.io/](http://rest-assured.io/)
-   **JWT.io (for understanding JWTs)**: [https://jwt.io/](https://jwt.io/)
