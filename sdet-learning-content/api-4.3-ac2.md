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
