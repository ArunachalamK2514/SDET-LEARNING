# Automated Data Refresh and Cleanup in SDET

## Overview
Automated data refresh and cleanup are crucial components of a robust Test Data Management (TDM) strategy for SDETs. They ensure that tests run in a consistent, predictable environment, preventing flaky tests due to data inconsistencies and enabling efficient parallel execution. This practice accelerates feedback cycles, reduces debugging time, and maintains the integrity of test suites. By automating these processes, we eliminate manual errors and significantly scale our testing efforts across various environments (development, QA, staging).

## Detailed Explanation

Automated data refresh and cleanup can be broken down into several key strategies:

### 1. Restoring Database to Baseline State
This involves bringing your test database back to a known, clean state before a test run or suite. This "baseline" state typically contains a minimal set of necessary data for tests to execute, ensuring reproducibility.

**Methods for Database Baseline Restoration:**
*   **SQL Scripts:** Executing a series of SQL `TRUNCATE`, `DELETE`, and `INSERT` statements to clear and then load predefined data.
*   **Database Migration Tools (e.g., Flyway, Liquibase):** These tools manage database schema and data versions, allowing for programmatic rollback to a specific state or re-application of a baseline script.
*   **Database Snapshots/Backups:** For more complex databases, restoring from a pre-saved snapshot or backup can be the fastest way to reset. This is common in containerized environments (Docker).
*   **ORM/Data Seeding:** Using an Object-Relational Mapper (ORM) like Hibernate or custom data seeding logic within the test framework to populate data.

### 2. Implementing 'AfterMethod' Data Teardown via API
For tests that create or modify data, it's essential to clean up that specific data *after* the test execution. This ensures that subsequent tests are not affected by the data created by previous ones. Performing this teardown via API is preferable as it tests the API's delete/cleanup functionality and is faster than direct database manipulation for individual test cases.

**Test Framework Hooks:** Most testing frameworks (TestNG, JUnit) provide annotations or hooks to execute code before/after test methods, classes, or suites. `AfterMethod` (TestNG) or `AfterEach` (JUnit 5) are ideal for targeted data cleanup.

### 3. Configuring Cron Job for Nightly Environment Reset
For shared test environments, a complete reset at regular intervals (e.g., nightly) is often necessary. This ensures that the environment is fresh each morning, ready for a new day of testing, especially for longer-running test suites or manual testing. Cron jobs (on Linux/Unix) or Task Scheduler (on Windows) are used to schedule these operations.

**Typical Nightly Reset Tasks:**
*   Stopping application services.
*   Dropping and re-creating databases, or restoring from a golden backup.
*   Clearing caches, logs, and temporary files.
*   Starting application services.
*   Running health checks.

## Code Implementation

Here’s a Java example using TestNG and REST Assured to demonstrate API-based data teardown and a conceptual database baseline script.

```java
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeSuite;
import org.testng.annotations.Test;
import io.restassured.RestAssured;
import io.restassured.response.Response;
import io.restassured.http.ContentType;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

public class TestDataManagementExample {

    private static final String BASE_URL = "http://localhost:8080/api"; // Your API base URL
    private static final String DB_URL = "jdbc:postgresql://localhost:5432/testdb"; // Your DB URL
    private static final String DB_USER = "testuser";
    private static final String DB_PASSWORD = "testpassword";

    // Store created resource IDs for cleanup
    private ThreadLocal<String> createdResourceId = new ThreadLocal<>();

    @BeforeSuite
    public void setupSuite() {
        System.out.println("--- Executing @BeforeSuite: Database Baseline Restoration ---");
        restoreDatabaseBaseline();
        System.out.println("--- Database baseline restored successfully ---");
    }

    @Test(priority = 1)
    public void testCreateUserAndVerify() {
        System.out.println("
--- Executing testCreateUserAndVerify ---");
        String requestBody = "{ "username": "testuser_123", "email": "test@example.com" }";

        Response response = RestAssured.given()
                .contentType(ContentType.JSON)
                .body(requestBody)
                .post(BASE_URL + "/users");

        response.then().statusCode(201); // Assuming 201 Created

        String userId = response.jsonPath().getString("id");
        createdResourceId.set(userId); // Store user ID for AfterMethod cleanup
        System.out.println("Created User with ID: " + userId);

        // Further assertions to verify user creation
        RestAssured.given()
                .get(BASE_URL + "/users/" + userId)
                .then()
                .statusCode(200)
                .body("username", org.hamcrest.Matchers.equalTo("testuser_123"));
    }

    @Test(priority = 2)
    public void testUpdateUser() {
        System.out.println("
--- Executing testUpdateUser ---");
        // Pre-requisite: create a user that this test will update
        String createUserBody = "{ "username": "user_to_update", "email": "update@example.com" }";
        Response createResponse = RestAssured.given()
                .contentType(ContentType.JSON)
                .body(createUserBody)
                .post(BASE_URL + "/users");
        String userIdToUpdate = createResponse.jsonPath().getString("id");
        createdResourceId.set(userIdToUpdate); // This will overwrite the previous one if not careful in real scenarios

        String updateBody = "{ "email": "updated@example.com" }";
        RestAssured.given()
                .contentType(ContentType.JSON)
                .body(updateBody)
                .patch(BASE_URL + "/users/" + userIdToUpdate)
                .then()
                .statusCode(200)
                .body("email", org.hamcrest.Matchers.equalTo("updated@example.com"));
        System.out.println("Updated User with ID: " + userIdToUpdate);
    }

    @AfterMethod
    public void cleanupTestData() {
        String resourceId = createdResourceId.get();
        if (resourceId != null) {
            System.out.println("--- Executing @AfterMethod: Cleaning up data for resource ID: " + resourceId + " ---");
            RestAssured.given()
                    .delete(BASE_URL + "/users/" + resourceId)
                    .then()
                    .statusCode(204); // Assuming 204 No Content for successful deletion
            System.out.println("Cleaned up resource with ID: " + resourceId);
            createdResourceId.remove(); // Clear the thread local for the next test
        } else {
            System.out.println("--- No specific resource ID to clean up in @AfterMethod ---");
        }
    }

    // --- Helper Methods ---

    /**
     * Conceptual method to restore the database to a baseline state.
     * In a real scenario, this would execute SQL scripts, use Flyway/Liquibase,
     * or restore a Docker volume.
     */
    private void restoreDatabaseBaseline() {
        Connection conn = null;
        Statement stmt = null;
        try {
            // Establish connection
            Properties props = new Properties();
            props.setProperty("user", DB_USER);
            props.setProperty("password", DB_PASSWORD);
            conn = DriverManager.getConnection(DB_URL, props);
            conn.setAutoCommit(false); // Start transaction

            stmt = conn.createStatement();

            // Example: Drop and recreate a table or truncate data
            System.out.println("Dropping 'users' table if exists...");
            stmt.executeUpdate("DROP TABLE IF EXISTS users CASCADE;");

            System.out.println("Creating 'users' table...");
            stmt.executeUpdate("CREATE TABLE users (id VARCHAR(255) PRIMARY KEY, username VARCHAR(255) UNIQUE, email VARCHAR(255));");

            System.out.println("Inserting baseline data (e.g., admin user)...");
            stmt.executeUpdate("INSERT INTO users (id, username, email) VALUES ('admin1', 'admin', 'admin@example.com');");

            conn.commit(); // Commit transaction
            System.out.println("Database baseline restoration complete.");

        } catch (SQLException e) {
            System.err.println("Error restoring database baseline: " + e.getMessage());
            if (conn != null) {
                try {
                    conn.rollback(); // Rollback on error
                } catch (SQLException ex) {
                    System.err.println("Rollback failed: " + ex.getMessage());
                }
            }
            throw new RuntimeException("Failed to restore database baseline", e);
        } finally {
            try {
                if (stmt != null) stmt.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                System.err.println("Error closing DB resources: " + e.getMessage());
            }
        }
    }

    /**
     * Placeholder for a cron job script.
     * This script would be executed by the cron scheduler on the environment host.
     * On a Linux system, this could be a shell script (e.g., reset_env.sh).
     */
    // Example: reset_env.sh (to be scheduled via cron)
    /*
    #!/bin/bash
    echo "Starting nightly environment reset at $(date)"

    # Stop services
    sudo systemctl stop my-app-service
    sudo systemctl stop my-db-service

    # Restore database (e.g., using docker-compose or direct DB commands)
    # If using Docker:
    # docker-compose stop db
    # docker-compose rm -f db
    # docker volume rm myproject_db_data
    # docker-compose up -d db

    # Or direct DB commands:
    # psql -U testuser -d testdb -c "DROP DATABASE testdb;"
    # psql -U testuser -c "CREATE DATABASE testdb OWNER testuser;"
    # psql -U testuser -d testdb -f /path/to/baseline_script.sql

    # Clear caches/logs
    rm -rf /var/log/my-app/*.log
    redis-cli FLUSHALL

    # Start services
    sudo systemctl start my-app-service
    sudo systemctl start my-db-service

    echo "Nightly environment reset completed at $(date)"
    */
    // To schedule the above script using cron (e.g., at 2 AM daily):
    // 0 2 * * * /path/to/reset_env.sh >> /var/log/reset_env.log 2>&1

}
