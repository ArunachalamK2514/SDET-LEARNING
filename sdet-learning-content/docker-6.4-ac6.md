# Run Tests Inside Docker Container

## Overview
Running tests inside Docker containers provides a consistent, isolated, and reproducible environment for test execution. This approach eliminates "it works on my machine" issues, simplifies dependency management, and facilitates seamless integration into CI/CD pipelines. For SDETs, mastering Docker for test execution is crucial for building robust and scalable automation frameworks.

## Detailed Explanation
When you run tests directly on your local machine, you're subject to its specific operating system, installed libraries, and configurations. Docker encapsulates your application and its dependencies into a container, ensuring that your test environment is identical everywhere—from your local development machine to staging and production CI/CD servers.

Key aspects of running tests in Docker include:

1.  **Building a Test Image**: First, you need a Docker image that contains your test framework, necessary dependencies (e.g., JDK for Java, Node.js for Playwright/Cypress), and your test code. This is typically achieved via a `Dockerfile`.
2.  **Running the Container**: Using `docker run`, you can instantiate a container from your test image.
3.  **Environment Variables**: Tests often require configuration, such as API endpoints, browser versions, or credentials. Docker allows you to pass these as environment variables (`-e KEY=VALUE`) directly into the container, keeping sensitive information out of the image itself.
4.  **Volume Mounting**: Test reports, logs, and screenshots are crucial outputs. By mounting a local directory into the container (`-v /local/path:/container/path`), you can persist these artifacts outside the ephemeral container, making them accessible after the test run.
5.  **Network Configuration**: If your tests interact with services running on the host machine or other containers, proper network configuration (e.g., `--network host`, user-defined networks) is essential.

## Code Implementation

Let's consider a simple Java project using Maven and TestNG for our tests.

**1. Project Structure (Example):**
```
my-test-project/
├── src/main/java/
├── src/test/java/
│   └── com/example/tests/
│       └── SimpleTest.java
├── pom.xml
└── Dockerfile
```

**2. `pom.xml` (Example - relevant parts):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>my-test-project</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <testng.version>7.8.0</testng.version>
        <maven-surefire-plugin.version>3.2.5</maven-surefire-plugin.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.testng</groupId>
            <artifactId>testng</artifactId>
            <version>${testng.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>${maven-surefire-plugin.version}</version>
                <configuration>
                    <!-- Configure test reports output directory -->
                    <reportsDirectory>${project.build.directory}/surefire-reports</reportsDirectory>
                    <suiteXmlFiles>
                        <suiteXmlFile>src/test/resources/testng.xml</suiteXmlFile>
                    </suiteXmlFiles>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

**3. `src/test/java/com/example/tests/SimpleTest.java` (Example Test):**
```java
package com.example.tests;

import org.testng.Assert;
import org.testng.annotations.Test;

public class SimpleTest {

    @Test
    public void exampleTestSuccess() {
        System.out.println("Running exampleTestSuccess in Docker!");
        String envVar = System.getenv("TEST_ENV");
        System.out.println("TEST_ENV environment variable: " + envVar);
        Assert.assertEquals(envVar, "docker-qa", "TEST_ENV should be 'docker-qa'");
    }

    @Test
    public void anotherTest() {
        System.out.println("Running anotherTest in Docker!");
        Assert.assertTrue(true);
    }
}
```

**4. `Dockerfile`:**
```dockerfile
# Use a base image with Java and Maven
FROM maven:3.9.6-sapmachine-17-slim AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the pom.xml and download dependencies to leverage Docker layer caching
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy the rest of the application code
COPY src ./src

# Compile the tests
RUN mvn test-compile

# --- Runtime stage ---
# Use a smaller base image for running the tests if possible, though maven image works fine too.
# For simplicity, we'll continue with the build image, but for production, a dedicated runtime is better.
FROM build AS run

# Command to run the tests
# When running with 'docker run', Maven will re-download dependencies if not cached in the image,
# and then execute the tests.
# Ensure the surefire reports directory is created by Maven.
CMD ["mvn", "test"]
```

**5. Building the Docker Image:**
```bash
# Navigate to the my-test-project directory
cd my-test-project
docker build -t my-test-image .
```

**6. Running Tests Inside the Docker Container:**
```bash
# Create a local reports directory
mkdir -p reports

# Run the container, pass an environment variable, and mount the reports volume
docker run 
  -e TEST_ENV=docker-qa 
  -v "$(pwd)/reports:/app/target/surefire-reports" 
  my-test-image
```
*Explanation:*
*   `-e TEST_ENV=docker-qa`: Passes an environment variable `TEST_ENV` with value `docker-qa` into the container.
*   `-v "$(pwd)/reports:/app/target/surefire-reports"`: Mounts your local `reports` directory (created by `mkdir -p reports`) to the `/app/target/surefire-reports` directory inside the container. This is where Maven Surefire Plugin typically writes test reports. `$(pwd)` ensures the correct absolute path on Linux/macOS. On Windows, you might need to use `%cd%` or the full path.

**7. Verifying Reports:**
After the `docker run` command completes, you should find the TestNG/Surefire XML reports (e.g., `TEST-com.example.tests.SimpleTest.xml`) in your local `my-test-project/reports` directory.

```bash
# Example verification
ls -l reports
cat reports/TEST-com.example.tests.SimpleTest.xml
```

## Best Practices
-   **Small Base Images**: Use minimal base images (e.g., `alpine`, `slim` variants) to reduce image size and attack surface.
-   **Multi-stage Builds**: Separate build-time dependencies from runtime dependencies to create smaller, more efficient final images.
-   **Leverage Layer Caching**: Order `Dockerfile` instructions from least to most frequently changing to maximize Docker's layer caching benefits, speeding up builds. Copy `pom.xml` (or `package.json`, etc.) and install dependencies *before* copying source code.
-   **Environment Variables for Configuration**: Externalize configuration using environment variables rather than hardcoding values in the image.
-   **Volume Mounts for Outputs**: Always mount volumes for test reports, logs, and other artifacts that need to be persisted.
-   **Resource Limits**: Use `--memory` and `--cpus` with `docker run` to limit resources consumed by test containers, preventing them from starving the host or other containers.
-   **Container Orchestration (Docker Compose/Kubernetes)**: For complex test setups involving multiple services (e.g., database, application under test), use Docker Compose or Kubernetes to manage and orchestrate your test environment.

## Common Pitfalls
-   **Large Image Sizes**: Not using multi-stage builds or including unnecessary tools/dependencies can lead to bloated images, slowing down builds and deployments.
-   **Hardcoding Configuration**: Embedding secrets or environment-specific values directly into the image makes it less flexible and harder to manage.
-   **Ignoring Reports**: Forgetting to mount volumes for reports means losing test results once the container exits, hindering debugging and analysis.
-   **Timeouts**: Tests might time out due to container resource constraints or network latency. Ensure containers have sufficient resources and network access.
-   **Differences in OS/Filesystem**: Be aware of path separators (`/` vs ``) and filesystem case sensitivity when running tests developed on one OS in a Docker container with a different base OS.
-   **Forgetting to clean up**: Leaving stale containers or images can consume disk space. Regularly prune Docker resources.

## Interview Questions & Answers
1.  **Q: Why would you run your automated tests in Docker containers?**
    A: The primary reasons are environment consistency, isolation, and reproducibility. Docker ensures that tests run in the exact same environment every time, regardless of the host machine, eliminating "works on my machine" issues. It simplifies dependency management, making onboarding easier and CI/CD pipelines more reliable.

2.  **Q: How do you handle test reports and artifacts when running tests in Docker?**
    A: We use Docker's volume mounting feature (`-v /host/path:/container/path`). This allows us to map a directory on the host machine to a directory inside the container. Test runners are configured to output reports and artifacts to the mounted path within the container, making them accessible on the host machine after the container finishes execution.

3.  **Q: You need to pass different API endpoints to your tests running in Docker for different environments (dev, staging, prod). How would you achieve this securely and efficiently?**
    A: I would use environment variables. When running the Docker container, I would pass the specific API endpoint using the `-e` flag (e.g., `docker run -e API_URL=https://dev.api.example.com my-test-image`). For sensitive data like API keys, I'd leverage Docker Secrets or a secrets management solution in a production CI/CD setup, passing them as environment variables or mounting them as files.

4.  **Q: Describe a common problem you've faced running tests in Docker and how you resolved it.**
    A: A common issue is tests failing due to resource constraints or network issues. For example, tests might time out when trying to connect to a UI application under test. I'd resolve this by first checking container logs for errors. If it's a resource issue, I'd allocate more memory (`--memory`) or CPU (`--cpus`) to the container. If it's network-related, I'd verify network configurations (e.g., using `--network host` if the AUT is on the host, or ensuring containers are on the same user-defined network if they need to communicate). I'd also ensure the AUT is fully ready before tests start by implementing proper waiting mechanisms.

## Hands-on Exercise
1.  **Objective**: Dockerize a simple Playwright test project and run tests with mounted reports.
2.  **Setup**:
    *   Create a new directory for your project.
    *   Initialize a Playwright project (e.g., `npm init playwright@latest`).
    *   Add a simple test that opens `https://www.google.com` and asserts the title.
    *   Create a `Dockerfile` that:
        *   Uses a Node.js base image.
        *   Installs Playwright dependencies (`npx playwright install`).
        *   Copies your `package.json`, `package-lock.json`, and test files.
        *   Installs project dependencies (`npm install`).
        *   Sets the default command to run Playwright tests (`npx playwright test`).
3.  **Execution**:
    *   Build your Docker image.
    *   Create a local `test-results` directory.
    *   Run your Docker container, mounting the local `test-results` directory to where Playwright saves its reports inside the container (usually `test-results/`).
    *   Pass an environment variable, e.g., `BROWSER=chromium` if you want to override the default Playwright config.
4.  **Verification**: Confirm that the Playwright HTML reports and any screenshots are available in your local `test-results` directory after the container finishes.

## Additional Resources
-   **Docker Official Documentation**: [https://docs.docker.com/](https://docs.docker.com/)
-   **Maven Surefire Plugin Documentation**: [https://maven.apache.org/surefire/maven-surefire-plugin/](https://maven.apache.org/surefire/maven-surefire-plugin/)
-   **Playwright Docker Guide**: [https://playwright.dev/docs/docker](https://playwright.dev/docs/docker)
-   **Test Automation in Docker by TestContainers**: [https://testcontainers.org/](https://testcontainers.org/) (Advanced topic for managing services for integration tests)