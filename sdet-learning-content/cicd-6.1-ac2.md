# The Test Pyramid and Appropriate Test Distribution

## Overview
The Test Pyramid is a widely adopted concept in software development, particularly within the SDET and quality assurance domains. It's a heuristic that suggests grouping software tests into different categories based on their granularity, cost, and execution speed, and then advocating for a specific distribution of these tests. The primary goal is to achieve comprehensive test coverage efficiently, ensuring high quality without slowing down development cycles. Understanding and correctly implementing the test pyramid is crucial for building robust, maintainable, and continuously deliverable software systems.

## Detailed Explanation

The test pyramid typically consists of three main layers: Unit Tests, Integration Tests, and End-to-End (E2E) Tests. Some models include a fourth layer, UI Tests, often considered a subset or specific type of E2E test. The pyramid shape illustrates that the majority of tests should be at the lowest layer (Unit), with progressively fewer tests at higher layers (Integration, E2E).

### Layers of the Test Pyramid

1.  **Unit Tests (Base of the Pyramid)**
    *   **What they are:** These are the smallest, most isolated tests. They verify the correct functioning of individual units or components of code, such as a single method, function, or class, in isolation from external dependencies (databases, file systems, network calls, UI). Dependencies are typically mocked or stubbed.
    *   **Speed & Cost:** Extremely fast to execute (milliseconds) and cheap to write and maintain.
    *   **Coverage:** Provide fine-grained feedback on specific logic. A high number of unit tests contributes to high code coverage.
    *   **Examples:** Testing a utility function that calculates tax, a method that processes a single data object, or a validator class.

2.  **Integration Tests (Middle of the Pyramid)**
    *   **What they are:** These tests verify the interactions between different units or components, or between components and external systems (like databases, APIs, file systems). They ensure that different parts of the system work correctly when put together. They might test a specific service layer, a database repository, or an API endpoint's interaction with its business logic.
    *   **Speed & Cost:** Slower than unit tests (seconds) and more expensive to write and maintain due to setup and teardown of dependencies.
    *   **Coverage:** Provide confidence in the connections and contracts between components.
    *   **Examples:** Testing if a service correctly saves data to a real database, verifying that an API endpoint returns the expected response after calling a downstream service, or ensuring a message queue integration works.

3.  **End-to-End (E2E) Tests (Top of the Pyramid)**
    *   **What they are:** These tests simulate real user scenarios and interactions with the complete system, from the user interface (UI) down to the database and external services. They verify that the entire application flow works as expected from a user's perspective.
    *   **Speed & Cost:** The slowest (minutes to hours) and most expensive to write, maintain, and execute. They often require a fully deployed environment.
    *   **Coverage:** Provide the highest confidence that the system as a whole meets business requirements, but offer less specific feedback on failure points.
    *   **Examples:** Testing a user's journey from logging in, adding an item to a cart, proceeding to checkout, and receiving a confirmation, all through the actual UI.

### The Pyramid Shape with Relative Volume

```
          +-----------------+
          |  E2E Tests (Few)|  <-- Slowest, Most Expensive, Highest Fidelity
          +-----------------+
           /             
          / Integration   
         /  Tests (More)   \ <-- Moderate Speed/Cost, Interaction Fidelity
        /-------------------
       /      Unit Tests     
      /       (Many)          \ <-- Fastest, Cheapest, Lowest Fidelity, Max Coverage
     /-------------------------
```

**Relative Volume:**
*   **Unit Tests:** Occupy the largest volume at the base, meaning the vast majority of tests should be unit tests. They provide quick feedback and pinpoint issues precisely.
*   **Integration Tests:** Occupy a smaller volume than unit tests, but still a significant portion. They bridge the gap between isolated units and the full system.
*   **E2E Tests:** Occupy the smallest volume at the top, representing the fewest tests. These are critical for final validation but should be used sparingly due to their cost and slowness.

### Cost/Speed Trade-offs of Each Layer

| Test Type      | Speed           | Cost to Write/Maintain | Feedback Fidelity         | Isolation     | Use Case                                  |
| :------------- | :-------------- | :--------------------- | :------------------------ | :------------ | :---------------------------------------- |
| **Unit Tests** | Very Fast (ms)  | Low                    | High (specific component) | High          | Validating business logic, algorithms     |
| **Integration**| Moderate (secs) | Medium                 | Medium (component interaction) | Moderate      | Validating service contracts, data flow   |
| **E2E Tests**  | Slow (mins/hrs) | High                   | Low (entire system)       | Low           | Validating critical user journeys, system health |

**Trade-offs Explained:**

*   **Speed:** Faster tests run more frequently, enabling quick feedback loops crucial for Continuous Integration. Unit tests, being the fastest, fit perfectly here. E2E tests, being slow, can create bottlenecks if overused.
*   **Cost (Development & Maintenance):** More isolated tests (unit) are generally simpler to write, their failures are easier to diagnose, and they are less brittle (less likely to break due to changes in unrelated parts of the system). E2E tests, involving many layers, are complex to set up, their failures can be ambiguous, and they are more prone to breaking due to UI or environmental changes.
*   **Feedback Fidelity:** Unit tests tell you *exactly* which small piece of code is broken. E2E tests tell you *something* is broken in a user flow, but you then need to investigate across multiple layers to find the root cause, making debugging harder.
*   **Isolation:** Unit tests are highly isolated, testing one thing at a time. E2E tests have very low isolation as they test everything together.

The test pyramid advocates for this distribution to maximize feedback speed, minimize maintenance costs, and ensure high quality. Relying too heavily on E2E tests (an "Ice Cream Cone" anti-pattern) leads to slow, brittle, and expensive test suites that hinder agility.

## Code Implementation (Conceptual Examples)

While there isn't "code" for the test pyramid itself, here are conceptual code examples demonstrating the different test types.

### Java Example (JUnit 5, Mockito)

```java
// --- Unit Test Example ---
// Scenario: Test a simple calculator service

// src/main/java/com/example/CalculatorService.java
package com.example;

public class CalculatorService {
    public int add(int a, int b) {
        return a + b;
    }

    public int subtract(int a, int b) {
        return a - b;
    }

    // Imagine a dependency here, e.g., to a complex external logger
    public String performComplexCalculationAndLog(int a, int b, LoggerService logger) {
        int result = a * b + (a - b); // Some complex logic
        logger.log("Performed calculation: " + a + ", " + b + " -> " + result);
        return "Result: " + result;
    }
}

// src/main/java/com/example/LoggerService.java (Interface for dependency)
package com.example;

public interface LoggerService {
    void log(String message);
}

// src/test/java/com/example/CalculatorServiceTest.java
package com.example;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class) // Enable Mockito for JUnit 5
public class CalculatorServiceTest {

    @InjectMocks // Inject mocks into CalculatorService
    private CalculatorService calculatorService;

    @Mock // Create a mock instance of LoggerService
    private LoggerService mockLoggerService;

    @Test
    void testAdd() {
        assertEquals(5, calculatorService.add(2, 3), "2 + 3 should be 5");
    }

    @Test
    void testSubtract() {
        assertEquals(1, calculatorService.subtract(3, 2), "3 - 2 should be 1");
    }

    @Test
    void testPerformComplexCalculationAndLog() {
        // Arrange
        int num1 = 5;
        int num2 = 3;
        String expectedResultString = "Result: 17"; // 5 * 3 + (5 - 3) = 15 + 2 = 17

        // Act
        String actualResult = calculatorService.performComplexCalculationAndLog(num1, num2, mockLoggerService);

        // Assert
        assertEquals(expectedResultString, actualResult);
        // Verify that the mock logger's log method was called exactly once with the expected message
        verify(mockLoggerService).log("Performed calculation: 5, 3 -> 17");
    }
}

// --- Integration Test Example ---
// Scenario: Test a user repository that interacts with a real (in-memory) H2 database

// src/main/java/com/example/UserRepository.java
package com.example;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UserRepository {
    private final String jdbcUrl;

    public UserRepository(String jdbcUrl) {
        this.jdbcUrl = jdbcUrl;
    }

    public void createUserTable() throws SQLException {
        try (Connection conn = DriverManager.getConnection(jdbcUrl);
             Statement stmt = conn.createStatement()) {
            stmt.execute("CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255))");
        }
    }

    public void saveUser(User user) throws SQLException {
        String sql = "INSERT INTO users (name) VALUES (?)";
        try (Connection conn = DriverManager.getConnection(jdbcUrl);
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            pstmt.setString(1, user.getName());
            pstmt.executeUpdate();

            try (ResultSet generatedKeys = pstmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    user.setId(generatedKeys.getInt(1));
                }
            }
        }
    }

    public User findUserById(int id) throws SQLException {
        String sql = "SELECT id, name FROM users WHERE id = ?";
        try (Connection conn = DriverManager.getConnection(jdbcUrl);
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, id);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return new User(rs.getInt("id"), rs.getString("name"));
                }
            }
        }
        return null;
    }

    public List<User> findAllUsers() throws SQLException {
        List<User> users = new ArrayList<>();
        String sql = "SELECT id, name FROM users";
        try (Connection conn = DriverManager.getConnection(jdbcUrl);
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                users.add(new User(rs.getInt("id"), rs.getString("name")));
            }
        }
        return users;
    }

    public void cleanUp() throws SQLException {
        try (Connection conn = DriverManager.getConnection(jdbcUrl);
             Statement stmt = conn.createStatement()) {
            stmt.execute("DROP TABLE IF EXISTS users");
        }
    }
}

// src/main/java/com/example/User.java
package com.example;

public class User {
    private int id;
    private String name;

    public User(String name) {
        this.name = name;
    }

    public User(int id, String name) {
        this.id = id;
        this.name = name;
    }

    // Getters and Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        User user = (User) o;
        return id == user.id && name.equals(user.name);
    }

    @Override
    public int hashCode() {
        int result = id;
        result = 31 * result + name.hashCode();
        return result;
    }

    @Override
    public String toString() {
        return "User{" + "id=" + id + ", name='" + name + ''' + '}';
    }
}

// src/test/java/com/example/UserRepositoryIntegrationTest.java
package com.example;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import java.sql.SQLException;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class UserRepositoryIntegrationTest {

    private static final String JDBC_URL = "jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1"; // In-memory H2 database
    private UserRepository userRepository;

    @BeforeEach
    void setUp() throws SQLException {
        userRepository = new UserRepository(JDBC_URL);
        userRepository.createUserTable(); // Ensure table exists before each test
    }

    @AfterEach
    void tearDown() throws SQLException {
        userRepository.cleanUp(); // Clean up table after each test
    }

    @Test
    void testSaveAndFindUser() throws SQLException {
        User newUser = new User("Alice");
        userRepository.saveUser(newUser);

        assertNotNull(newUser.getId(), "User ID should be generated after saving");

        User foundUser = userRepository.findUserById(newUser.getId());
        assertNotNull(foundUser, "User should be found by ID");
        assertEquals("Alice", foundUser.getName());
        assertEquals(newUser.getId(), foundUser.getId());
    }

    @Test
    void testFindAllUsers() throws SQLException {
        userRepository.saveUser(new User("Bob"));
        userRepository.saveUser(new User("Charlie"));

        List<User> users = userRepository.findAllUsers();
        assertEquals(2, users.size(), "Should find two users");
        assertTrue(users.stream().anyMatch(u -> "Bob".equals(u.getName())));
        assertTrue(users.stream().anyMatch(u -> "Charlie".equals(u.getName())));
    }

    @Test
    void testFindNonExistentUser() throws SQLException {
        User foundUser = userRepository.findUserById(999);
        assertNull(foundUser, "Should not find a non-existent user");
    }
}

// --- E2E Test Example (Conceptual - using Playwright in TypeScript for a web app) ---
// Scenario: Test a user registration flow in a web application.
// This would typically involve a running frontend (e.g., React app) and a running backend API.

// Assuming a web application with a registration page at /register

// src/test/e2e/registration.spec.ts (using Playwright, TypeScript)
/*
import { test, expect } from '@playwright/test';

test.describe('User Registration Flow', () => {

    test('should allow a new user to register successfully', async ({ page }) => {
        // 1. Navigate to the registration page
        await page.goto('http://localhost:3000/register'); // Replace with your app's URL

        // 2. Fill in the registration form
        await page.fill('input[name="username"]', 'e2e_test_user_' + Date.now()); // Unique username
        await page.fill('input[name="email"]', `e2e_${Date.now()}@example.com`); // Unique email
        await page.fill('input[name="password"]', 'Password123!');
        await page.fill('input[name="confirmPassword"]', 'Password123!');

        // 3. Click the registration button
        await page.click('button[type="submit"]');

        // 4. Assert navigation to a success page or dashboard
        // Wait for URL to change or for a specific element to appear
        await page.waitForURL('http://localhost:3000/dashboard'); // Or '/registration-success'
        await expect(page.locator('h1')).toHaveText('Welcome to the Dashboard!'); // Or a success message

        // 5. (Optional but recommended) Verify user creation in the database via API or direct DB query
        // This step might involve making an API call to a test endpoint or directly querying the test database.
        // For simplicity, this is omitted from the browser-based Playwright example.
        // In a real scenario, you'd likely clean up the created user after the test.
    });

    test('should show error for existing username', async ({ page }) => {
        // Pre-condition: a user with 'existing_user' already exists in the system (might be set up in a `beforeEach` hook)
        // For this example, let's assume it's pre-populated or another test run created it.

        await page.goto('http://localhost:3000/register');
        await page.fill('input[name="username"]', 'existing_user');
        await page.fill('input[name="email"]', `another_${Date.now()}@example.com`);
        await page.fill('input[name="password"]', 'Password123!');
        await page.fill('input[name="confirmPassword"]', 'Password123!');
        await page.click('button[type="submit"]');

        // Assert error message
        await expect(page.locator('.error-message')).toHaveText('Username already taken.');
        await expect(page.url()).toContain('/register'); // Should stay on the registration page
    });

});
*/
```

## Best Practices
-   **Automate Everything:** All layers of the test pyramid should be automated and integrated into your CI/CD pipeline.
-   **Shift Left:** Write tests as early as possible in the development cycle. Unit tests should be written concurrently with feature development.
-   **Fast Feedback First:** Prioritize running faster, more isolated tests first. Your CI pipeline should run unit tests on every commit, integration tests on every pull request, and E2E tests perhaps on nightly builds or before major deployments.
-   **Deterministic Tests:** Ensure tests are reliable and produce the same result every time they run with the same input. Avoid reliance on external factors that can make tests flaky.
-   **Meaningful Naming:** Give tests clear, descriptive names that indicate what they are testing and under what conditions.
-   **Small and Focused Tests:** Each test should ideally assert one specific behavior or outcome.
-   **Clean Code for Tests:** Treat test code with the same respect as production code. Refactor, keep it clean, and maintainable.
-   **Balance is Key:** While the pyramid suggests ratios, the exact distribution depends on your project's complexity, architecture, and risk tolerance. Don't blindly follow ratios; adapt them to your context.

## Common Pitfalls
-   **The Ice Cream Cone Anti-Pattern:** This is when the pyramid is inverted, with too many E2E tests and very few unit tests. This leads to slow feedback, high maintenance costs, brittle tests, and difficult debugging.
-   **Over-Reliance on Mocks:** While essential for unit testing, excessive mocking in integration tests can lead to false positives if the mocks don't accurately reflect the behavior of real dependencies.
-   **Flaky E2E Tests:** E2E tests are inherently more prone to flakiness due to network latency, UI rendering issues, and environmental instability. Poorly written E2E tests can destroy confidence in the test suite.
-   **Lack of Test Data Management:** Inadequate strategies for creating, managing, and cleaning up test data can lead to tests interfering with each other or failing due to dirty environments.
-   **Ignoring Performance Tests:** The test pyramid focuses on functional testing. Remember that other types of testing (performance, security, usability) are also crucial.
-   **No Clear Boundaries:** Fuzzy definitions between unit, integration, and E2E tests can lead to confusion and inefficient testing strategies.

## Interview Questions & Answers

1.  **Q: Explain the Test Pyramid and why it's important for an SDET.**
    **A:** The Test Pyramid is a testing strategy that organizes automated tests into three main layers: Unit, Integration, and End-to-End (E2E), with the majority of tests being unit tests at the base, followed by integration tests, and a small number of E2E tests at the top. It's important for an SDET because it guides us to create an efficient and effective testing suite. By having many fast, cheap unit tests, we get quick feedback on code changes. Integration tests ensure components work together, and a few E2E tests provide confidence in the full system from a user's perspective. This balance prevents slow, expensive, and brittle test suites (the "ice cream cone" anti-pattern) and allows for rapid, confident deployments in a CI/CD pipeline.

2.  **Q: What are the key differences in cost and speed between Unit, Integration, and E2E tests?**
    **A:**
    *   **Unit Tests:** Very fast (milliseconds), low cost to write and maintain. They are isolated and only test a single piece of code.
    *   **Integration Tests:** Moderate speed (seconds), medium cost. They test interactions between components or with external dependencies (e.g., database, API) and require some setup.
    *   **E2E Tests:** Slowest (minutes to hours), highest cost. They test the entire system from the user's perspective, requiring a fully deployed environment and complex setup/teardown. Their brittleness also contributes to high maintenance.

3.  **Q: Describe a scenario where you would prioritize writing an Integration Test over an E2E Test, and why.**
    **A:** I would prioritize an Integration Test over an E2E test when verifying the contract and interaction between two microservices, or between a service and its database. For example, if I'm developing a new API endpoint that saves user data to a database, an integration test would cover whether the data is correctly mapped and persisted, and if the API responds as expected when interacting with the database. An E2E test for this specific flow would be overkill, slower, more complex to set up, and harder to debug if it fails. The integration test provides faster, more focused feedback on that specific interaction without involving the entire UI and other services.

4.  **Q: How does the Test Pyramid influence a CI/CD pipeline?**
    **A:** The Test Pyramid directly influences a CI/CD pipeline by dictating the order and frequency of test execution. In an optimized pipeline:
    *   **Unit Tests:** Run first and most frequently, typically on every commit or push to a feature branch. Their speed allows for immediate feedback.
    *   **Integration Tests:** Run after unit tests, often on pull request merges to the main branch or in a dedicated build stage. They confirm component compatibility before wider deployment.
    *   **E2E Tests:** Run least frequently, usually in a later stage of the pipeline (e.g., before deployment to staging/production, or nightly builds). Their slowness means they shouldn't block early feedback.
    This structured approach ensures that defects are caught early and cheaply, reducing the overall time and cost of delivery.

## Hands-on Exercise
**Exercise: Apply the Test Pyramid to a simple REST API**

Imagine you are developing a simple Java Spring Boot REST API for managing a list of products. The API has endpoints to:
*   `POST /products`: Create a new product.
*   `GET /products/{id}`: Retrieve a product by its ID.
*   `GET /products`: Retrieve all products.

The API uses an in-memory H2 database for persistence.

**Task:**
For the `POST /products` endpoint (create a new product), describe how you would apply the Test Pyramid by outlining the following tests:

1.  **Unit Test(s):** What specific classes/methods would you unit test, and what dependencies would you mock? Provide a conceptual Java/JUnit example.
2.  **Integration Test(s):** What interactions would you test, and what dependencies would be real vs. mocked? Provide a conceptual Java/JUnit example using an in-memory database.
3.  **E2E Test(s):** What full user flow would you test, and what tools/frameworks would you use? Describe the steps.

**Solution Approach (Do not provide actual code, but a detailed description):**

1.  **Unit Test for `POST /products`:**
    *   **Target:** `ProductService.createProduct(Product product)` method and `ProductValidator.validate(Product product)` method.
    *   **Mocks:** `ProductRepository` (for `ProductService`), `Logger` (if used).
    *   **Conceptual Example:**
        ```java
        // ProductServiceTest
        @Test
        void testCreateProduct_success() {
            Product newProduct = new Product("Laptop", 1200.0);
            when(mockProductRepository.save(any(Product.class))).thenReturn(new Product(1, "Laptop", 1200.0));
            Product createdProduct = productService.createProduct(newProduct);
            assertNotNull(createdProduct.getId());
            verify(mockProductRepository).save(any(Product.class));
        }

        // ProductValidatorTest
        @Test
        void testValidateProduct_valid() {
            Product validProduct = new Product("Monitor", 300.0);
            assertDoesNotThrow(() -> productValidator.validate(validProduct));
        }
        @Test
        void testValidateProduct_invalidPrice() {
            Product invalidProduct = new Product("Keyboard", -50.0);
            assertThrows(ValidationException.class, () -> productValidator.validate(invalidProduct));
        }
        ```

2.  **Integration Test for `POST /products`:**
    *   **Target:** `ProductController.createProduct(@RequestBody Product product)` and its interaction with `ProductService` and `ProductRepository`.
    *   **Real Dependencies:** `ProductService`, `ProductRepository`, `H2 In-Memory Database`.
    *   **Mocked Dependencies (Optional):** External payment gateway (if product creation triggers one).
    *   **Conceptual Example (Spring Boot with `@SpringBootTest`, `TestRestTemplate` or `MockMvc`):**
        ```java
        // ProductControllerIntegrationTest
        @Test
        void testCreateProductIntegration_success() {
            ProductRequestDTO request = new ProductRequestDTO("Mouse", 25.0);
            // Send POST request to /products endpoint
            ResponseEntity<Product> response = testRestTemplate.postForEntity("/products", request, Product.class);
            assertEquals(HttpStatus.CREATED, response.getStatusCode());
            assertNotNull(response.getBody().getId());
            // Verify product exists in the actual (in-memory) database
            Product savedProduct = productRepository.findById(response.getBody().getId()).orElse(null);
            assertNotNull(savedProduct);
            assertEquals("Mouse", savedProduct.getName());
        }
        ```

3.  **E2E Test for `POST /products` (as part of a larger flow):**
    *   **Full User Flow:** Admin logs into the system, navigates to the product management page, fills out the "add new product" form, submits it, and verifies the product appears in the product listing.
    *   **Tools:** Playwright, Selenium, Cypress (or similar UI automation framework).
    *   **Steps:**
        1.  Launch browser, navigate to login page.
        2.  Enter admin credentials, click login.
        3.  Navigate to `/admin/products` page.
        4.  Click "Add New Product" button.
        5.  Fill in product name, description, price in the form.
        6.  Click "Save Product" button.
        7.  Verify a success message is displayed.
        8.  Verify the newly added product appears in the product list table on the page.
        9.  (Optional cleanup) Delete the created product via UI or direct API call.

## Additional Resources
-   **Martin Fowler - TestPyramid:** [https://martinfowler.com/articles/practical-test-pyramid.html](https://martinfowler.com/articles/practical-test-pyramid.html) (Classic and highly influential article)
-   **Google Testing Blog - The Software Testing Anti-Patterns:** [https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html](https://testing.googleblog.com/2015/04/just-say-no-to-more-end-to-end-tests.html) (Focuses on avoiding the "ice cream cone")
-   **The Practical Test Pyramid - By Ham Vocke:** [https://www.hamvocke.com/blog/the-practical-test-pyramid/](https://www.hamvocke.com/blog/the-practical-test-pyramid/) (A more modern take on the concept)
-   **BDD and the Testing Pyramid - By Cucumber:** [https://cucumber.io/blog/bdd/bdd-and-the-testing-pyramid/](https://cucumber.io/blog/bdd/bdd-and-the-testing-pyramid/) (Connecting BDD to the test pyramid)
