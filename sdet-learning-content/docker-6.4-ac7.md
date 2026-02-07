# Docker Compose for Multi-Container Test Environments

### Overview
Docker Compose is a powerful tool for defining and running multi-container Docker applications. It allows developers and SDETs to define their application's services, networks, and volumes in a single `docker-compose.yml` file, and then spin up or tear down the entire environment with a single command. For test automation, this is invaluable for creating consistent, isolated, and reproducible test environments that mimic production setups, including dependent services like databases, APIs, or mock servers.

### Detailed Explanation
In test automation, it's common for tests to depend on multiple services. For example, UI tests might interact with a frontend application that in turn communicates with a backend API, which then uses a database. Manually setting up and orchestrating these services for each test run can be cumbersome and error-prone. Docker Compose simplifies this by:

1.  **Defining Services**: Each service (e.g., test runner, application under test, database) is defined in `docker-compose.yml` with its image, build context, ports, volumes, and environment variables.
2.  **Networking**: Compose automatically creates a default network for all services, allowing them to communicate with each other using their service names as hostnames.
3.  **Volume Management**: Easily mount local directories as volumes for code changes, test reports, or configuration files.
4.  **Environment Variables**: Manage environment-specific configurations for different services.
5.  **Orchestration**: Commands like `docker-compose up` (start all services), `docker-compose down` (stop and remove all services), and `docker-compose ps` (list running services) provide easy control over the entire environment.

This enables SDETs to package their test suite and its dependencies into a single, portable definition, ensuring that tests run in the same environment everywhere: on a developer's machine, in CI/CD pipelines, or on a dedicated test server.

### Code Implementation

Let's consider a scenario where we have:
*   A simple web application (SUT - System Under Test) built with Node.js that serves a "Hello World" message.
*   A Playwright test suite that hits this web application.

First, let's create a dummy Node.js application (`app/app.js`) and a Dockerfile for it:

**`app/app.js`**:
```javascript
// app/app.js
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello from Dockerized App!');
});

app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
});
```

**`app/package.json`**:
```json
// app/package.json
{
  "name": "docker-test-app",
  "version": "1.0.0",
  "description": "A simple Node.js app for Docker Compose example",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.17.1"
  }
}
```

**`app/Dockerfile`**:
```dockerfile
# app/Dockerfile
# Use an official Node.js runtime as a parent image
FROM node:18-alpine

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (if any)
COPY package*.json ./

# Install app dependencies
RUN npm install

# Copy the application code
COPY . .

# Expose the port the app runs on
EXPOSE 3000

# Define the command to run the app
CMD [ "npm", "start" ]
```

Next, let's create a Playwright test (`tests/example.spec.js`) and its Dockerfile:

**`tests/example.spec.js`**:
```javascript
// tests/example.spec.js
const { test, expect } = require('@playwright/test');

test('should display "Hello from Dockerized App!" on the homepage', async ({ page }) => {
  // Use the service name 'app' as the hostname
  await page.goto('http://app:3000');
  await expect(page.locator('body')).toHaveText('Hello from Dockerized App!');
});
```

**`tests/package.json`**:
```json
// tests/package.json
{
  "name": "docker-test-suite",
  "version": "1.0.0",
  "description": "Playwright tests for Docker Compose example",
  "main": "index.js",
  "scripts": {
    "test": "playwright test"
  },
  "devDependencies": {
    "@playwright/test": "^1.40.0"
  }
}
```

**`tests/Dockerfile`**:
```dockerfile
# tests/Dockerfile
# Use Playwright's official Docker image which includes browsers
FROM mcr.microsoft.com/playwright/python:v1.40.0-jammy

# Set the working directory in the container
WORKDIR /usr/src/app/tests

# Copy package.json and package-lock.json
COPY tests/package*.json ./

# Install Playwright dependencies
RUN npm install

# Copy the test files
COPY tests/. .

# Define the command to run tests (this will be overridden by docker-compose)
CMD [ "npm", "test" ]
```

Finally, the `docker-compose.yml` file to orchestrate both services:

**`docker-compose.yml`**:
```yaml
# docker-compose.yml
version: '3.8'

services:
  # Service for our Node.js application (System Under Test)
  app:
    build:
      context: ./app # Path to the Dockerfile for the app
      dockerfile: Dockerfile
    ports:
      - "3000:3000" # Map host port 3000 to container port 3000
    networks:
      - test_network # Assign to our custom network

  # Service for running Playwright tests
  tests:
    build:
      context: . # Use the current directory as build context
      dockerfile: tests/Dockerfile # Path to the Dockerfile for tests
    # Ensure tests start after the app service is healthy
    depends_on:
      app:
        condition: service_started
    networks:
      - test_network # Assign to the same network as 'app'
    # Override the default command to run tests
    command: npm test
    # Mount local test reports directory
    volumes:
      - ./test-results:/usr/src/app/tests/test-results

# Define custom network
networks:
  test_network:
    driver: bridge
```

**To run this example:**
1.  Save the files in the described directory structure (`app/`, `tests/`, `docker-compose.yml`).
2.  Open your terminal in the root directory where `docker-compose.yml` is located.
3.  Run: `docker-compose up --build --abort-on-container-exit`
    *   `--build`: Builds images before starting containers.
    *   `--abort-on-container-exit`: If any container exits, all containers are stopped. This is useful for test runs where the test container is expected to exit after completing tests.

You will see the app starting, then the test container launching, running the Playwright tests, and finally, all services shutting down.

### Best Practices
-   **Isolation**: Ensure each service is isolated, meaning it runs only what's necessary and doesn't share unnecessary resources with other services.
-   **Reproducibility**: Use specific image versions (e.g., `node:18-alpine` instead of `node:latest`) to guarantee the environment remains consistent over time.
-   **Service Health Checks**: For more complex scenarios, implement `healthcheck` in `docker-compose.yml` to ensure a service is truly ready before dependent services start, preventing "connection refused" errors.
-   **Separate Concerns**: Keep application code, test code, and Docker configurations in logical, separate directories.
-   **Resource Limits**: Define `resources` (CPU, memory) in `docker-compose.yml` to prevent tests from consuming too many host resources, especially in CI environments.
-   **Ephemeral Containers**: Design test containers to be ephemeral; they should be able to be built, run, and destroyed without leaving behind any persistent state.

### Common Pitfalls
-   **Dependencies Not Ready**: Starting tests before dependent services (like a database or API) are fully initialized can lead to flaky tests. Use `depends_on` with `condition: service_started` or `condition: service_healthy` (if health checks are defined) to mitigate this.
-   **Networking Issues**: Incorrectly configured networks can prevent services from communicating. Always ensure services that need to talk to each other are on the same Docker network. Remember to use service names as hostnames within the Docker Compose network.
-   **Port Conflicts**: If you map container ports to host ports, ensure the host ports are not already in use. For test environments, often mapping ports isn't strictly necessary unless you need to access the services from outside the Docker Compose network (e.g., for debugging).
-   **Large Images**: Using bloated base images can significantly increase build times and resource consumption. Opt for slim or alpine versions of images when possible.
-   **Ignoring Logs**: Not capturing or reviewing logs from test runs can make debugging difficult. Ensure your `docker-compose up` command outputs logs and that they are accessible.

### Interview Questions & Answers
1.  **Q: What problem does Docker Compose solve for SDETs in test automation?**
    **A:** Docker Compose addresses the challenge of setting up and managing complex, multi-service test environments. It allows SDETs to define all services (e.g., application under test, database, mock servers, test runner) and their interconnections in a single YAML file, ensuring consistent, isolated, and reproducible environments across development, testing, and CI/CD. This eliminates "it works on my machine" issues and streamlines environment provisioning.

2.  **Q: How do services communicate with each other within a Docker Compose setup?**
    **A:** Docker Compose automatically creates a default network (or allows custom networks) for all defined services. Within this network, services can communicate with each other using their service names as hostnames. For example, if you have a service named `api` and another named `tests`, the `tests` service can reach the `api` service at `http://api:8080` (assuming the API runs on port 8080).

3.  **Q: Explain the `depends_on` directive in `docker-compose.yml` and its importance for test automation.**
    **A:** The `depends_on` directive expresses dependency between services, specifically that one service should start before another. For test automation, it's crucial because tests often rely on the application under test (SUT) or other backend services being fully up and ready. Using `depends_on` with `condition: service_started` (or `service_healthy` if health checks are defined) ensures that the test runner container won't attempt to connect to services that are still initializing, preventing connection errors and flakiness.

4.  **Q: How would you persist test reports or logs generated inside a Docker Compose test container?**
    **A:** To persist data generated inside a container, you would use Docker volumes. In `docker-compose.yml`, you can define a `volumes` entry for your test service, mapping a directory inside the container (e.g., `/app/test-reports`) to a directory on the host machine (e.g., `./local-test-reports`). This ensures that even after the container is removed, the reports remain accessible on the host.

### Hands-on Exercise
1.  **Objective**: Extend the previous example by adding a PostgreSQL database to the `docker-compose.yml` and modify the Node.js application to connect to it. Then, update the Playwright test to verify data interaction with the database (e.g., add a new endpoint to the Node.js app that reads from the database and update the test to hit that endpoint).
2.  **Steps**:
    *   Add a `db` service to `docker-compose.yml` using the `postgres` image, defining necessary environment variables (e.g., `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`).
    *   Update `app/app.js` to connect to the `db` service (using `db` as the hostname) and implement a simple route (e.g., `/data`) that inserts and retrieves data from the database.
    *   Add `depends_on: db` to the `app` service in `docker-compose.yml` to ensure the database starts before the application.
    *   Create a new Playwright test or modify `example.spec.js` to hit the new `/data` endpoint and assert the expected database interaction.
    *   Run `docker-compose up --build --abort-on-container-exit` to verify the setup.

### Additional Resources
-   **Docker Compose Documentation**: [https://docs.docker.com/compose/](https://docs.docker.com/compose/)
-   **Playwright Docker Guide**: [https://playwright.dev/docs/docker](https://playwright.dev/docs/docker)
-   **Awesome Docker Compose**: [https://github.com/vinhphuc/awesome-docker-compose](https://github.com/vinhphuc/awesome-docker-compose)