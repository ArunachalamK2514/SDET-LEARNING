# Selenium 2.5 AC2: Setting Up Selenium Grid 4

## Overview
Selenium Grid allows tests to be run on different machines against different browsers in parallel. This significantly speeds up test execution and enables cross-browser testing. Selenium Grid 4 introduces a new, more robust architecture built on a distributed model, simplifying setup and scaling. This section will cover how to set up Selenium Grid 4 in both standalone mode (for quick local testing) and hub-node configuration (for distributed testing).

## Detailed Explanation

Selenium Grid 4 is composed of several components that work together:
*   **Router:** The entry point for all external requests. It receives new session requests and forwards them to the Distributor.
*   **Distributor:** Responsible for assigning new session requests to available Nodes. It maintains a list of all active Nodes and their capabilities.
*   **Node:** Where the actual Selenium WebDriver tests run. Each Node registers itself with the Grid and advertises its capabilities (browser types, versions, OS).
*   **Session Map:** Stores information about active sessions, mapping a session ID to the Node where it's running.
*   **Event Bus:** Facilitates communication between all Grid components using a publish-subscribe model, making the architecture highly scalable and resilient.

### Standalone Mode
This is the simplest way to get started with Grid 4. All components (Router, Distributor, Node, Session Map, Event Bus) run within a single process. It's useful for local development and testing, or when you only need to run tests on a single machine but want to leverage Grid features.

### Hub-Node Configuration
This mode is used for distributed testing where Nodes are running on separate machines (or separate processes on the same machine) from the Hub (which comprises Router, Distributor, Session Map, Event Bus). This setup is ideal for scaling, cross-browser testing, and executing a large number of tests in parallel.

## Code Implementation

First, you need the Selenium Server JAR file. You can download it from the official Selenium website: `https://www.selenium.dev/downloads/`.
Let's assume you've downloaded `selenium-server-4.x.x.jar`.

### 1. Standalone Mode Setup

Run the JAR with the `standalone` command:

```bash
# Navigate to the directory where you downloaded the selenium-server-4.x.x.jar
cd /path/to/selenium-server/

# Start Selenium Grid in standalone mode
java -jar selenium-server-4.x.x.jar standalone
```
Upon successful startup, you will see output indicating that the server is running. You can access the Grid UI by opening your browser and navigating to `http://localhost:4444`.

### 2. Hub-Node Configuration Setup

#### Step 2.1: Start the Hub (Router, Distributor, Session Map, Event Bus)

The Hub is started in `hub` mode. This command will start all necessary components for the central management of the Grid.

```bash
# Navigate to the directory where you downloaded the selenium-server-4.x.x.jar
cd /path/to/selenium-server/

# Start the Selenium Grid Hub (Router, Distributor, Session Map, Event Bus)
java -jar selenium-server-4.x.x.jar hub
```
The Hub will start listening on `http://localhost:4444` by default. You can verify its status by navigating to this URL in your browser.

#### Step 2.2: Start the Node(s)

Nodes are where the browsers and tests actually run. Each Node needs to register with the Hub. You can run multiple Nodes, even on the same machine, by specifying different port numbers or by running them on different machines.

**Node 1 (e.g., for Chrome):**

```bash
# Navigate to the directory where you downloaded the selenium-server-4.x.x.jar
cd /path/to/selenium-server/

# Start a Node and register it with the Hub
# The --publish-events and --subscribe-events flags tell the Node how to connect to the Event Bus
# Use the correct IP address or hostname for your Hub machine if it's not localhost
java -jar selenium-server-4.x.x.jar node --detect-drivers true --publish-events tcp://localhost:4442 --subscribe-events tcp://localhost:4443
```
*   `--detect-drivers true`: Automatically detects available browsers (Chrome, Firefox, Edge, etc.) and their drivers installed on the system path. Ensure your browser drivers (e.g., `chromedriver.exe`, `geckodriver.exe`) are in your system's PATH.
*   `--publish-events tcp://localhost:4442`: Specifies the Event Bus address where the Node will publish its events.
*   `--subscribe-events tcp://localhost:4443`: Specifies the Event Bus address from which the Node will subscribe to events.

**Node 2 (e.g., for Firefox, on a different port if on the same machine):**

```bash
# Navigate to the directory where you downloaded the selenium-server-4.x.x.jar
cd /path/to/selenium-server/

# Start another Node, potentially on a different port (e.g., 5555)
# This example explicitly sets the port. If not set, it might pick an available one.
java -jar selenium-server-4.x.x.jar node --detect-drivers true --publish-events tcp://localhost:4442 --subscribe-events tcp://localhost:4443 --port 5555
```

After starting the Nodes, refresh the Grid UI (`http://localhost:4444`) to see the registered Nodes and their capabilities.

### Example Java Test Code to run on Grid

```java
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.remote.DesiredCapabilities;
import org.openqa.selenium.remote.RemoteWebDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.firefox.FirefoxOptions;

import java.net.MalformedURLException;
import java.net.URL;

public class GridTest {

    public static void main(String[] args) throws MalformedURLException {
        // Define the URL of your Selenium Grid Hub
        String gridUrl = "http://localhost:4444/wd/hub";

        WebDriver driver = null;

        // --- Example 1: Run on Chrome ---
        ChromeOptions chromeOptions = new ChromeOptions();
        // You can add more options here, e.g., chromeOptions.addArguments("--headless");
        
        // Pass the ChromeOptions directly
        driver = new RemoteWebDriver(new URL(gridUrl), chromeOptions);
        System.out.println("Running Chrome test...");
        driver.get("https://www.selenium.dev/");
        System.out.println("Chrome Title: " + driver.getTitle());
        driver.quit();

        // --- Example 2: Run on Firefox ---
        FirefoxOptions firefoxOptions = new FirefoxOptions();
        // You can add more options here, e.g., firefoxOptions.addArguments("-headless");
        
        // Pass the FirefoxOptions directly
        driver = new RemoteWebDriver(new URL(gridUrl), firefoxOptions);
        System.out.println("Running Firefox test...");
        driver.get("https://www.google.com/");
        System.out.println("Firefox Title: " + driver.getTitle());
        driver.quit();
    }
}
```

**Note:** For the above Java code to work, ensure you have the `selenium-java` and `selenium-http-okhttp` (or `selenium-http-client`) dependencies in your `pom.xml` (Maven) or `build.gradle` (Gradle).

```xml
<!-- Maven dependencies -->
<dependency>
    <groupId>org.seleniumhq.selenium</groupId>
    <artifactId>selenium-java</artifactId>
    <version>4.1.2</version> <!-- Use your Selenium version -->
</dependency>
<dependency>
    <groupId>org.seleniumhq.selenium</groupId>
    <artifactId>selenium-http-okhttp</artifactId>
    <version>4.1.2</version> <!-- Use your Selenium version -->
</dependency>
```

## Best Practices
-   **Centralized Driver Management:** Use `--detect-drivers true` on Nodes to automatically pick up installed browsers and drivers. Ensure `chromedriver`, `geckodriver`, `msedgedriver` are in the system PATH on Node machines.
-   **Dedicated Machines:** For production-grade parallel execution, run Hub and Nodes on dedicated machines to avoid resource contention.
-   **Resource Allocation:** Monitor CPU, memory, and network usage on your Node machines. Adjust the number of browser instances a Node can host by using `--max-sessions` and `--session-timeout` flags.
-   **Containerization:** For highly scalable and reproducible setups, consider running Selenium Grid with Docker or Kubernetes. This allows for easy provisioning and scaling of Nodes.
-   **Security:** If exposing your Grid to a network, ensure proper firewall rules and authentication mechanisms are in place.

## Common Pitfalls
-   **Incorrect Hub URL:** Tests failing with connection errors often point to an incorrect `gridUrl` in the test code. Double-check the IP address and port.
-   **Driver Not Found:** If `--detect-drivers true` is not working, ensure the browser drivers are correctly installed and available in the system's PATH variable on the Node machine.
-   **Firewall Issues:** If Nodes cannot connect to the Hub, check firewall settings on both Hub and Node machines to ensure the necessary ports (default 4444 for HTTP, 4442/4443 for Event Bus TCP) are open.
-   **Version Mismatches:** Ensure your Selenium client library version (in your test project) is compatible with the Selenium Server Grid version.
-   **Resource Exhaustion:** Running too many browser instances on a single Node without adequate hardware resources will lead to flaky tests and crashes. Monitor resource usage and adjust `--max-sessions` accordingly.

## Interview Questions & Answers

1.  **Q: What is the primary benefit of using Selenium Grid?**
    **A:** The primary benefit is to enable parallel test execution across multiple machines and different browser-OS combinations. This dramatically reduces overall test execution time and facilitates comprehensive cross-browser testing.

2.  **Q: Explain the key components of Selenium Grid 4.**
    **A:** Selenium Grid 4 consists of a Router (entry point), Distributor (assigns sessions), Node (runs tests and browsers), Session Map (tracks active sessions), and Event Bus (enables communication). This distributed architecture offers better scalability and resilience compared to Grid 3.

3.  **Q: How do you configure a Node to automatically detect browsers?**
    **A:** When starting a Node, use the `--detect-drivers true` flag. For this to work, the respective browser drivers (e.g., `chromedriver`, `geckodriver`) must be installed on the Node machine and be accessible via the system's PATH environment variable.

## Hands-on Exercise
1.  Download the latest `selenium-server-4.x.x.jar` from `selenium.dev/downloads`.
2.  Set up a Selenium Grid in `standalone` mode on your local machine.
3.  Verify the Grid UI is accessible at `http://localhost:4444`.
4.  Modify the provided Java example code to run a simple test (e.g., navigate to `google.com` and print the title) on your standalone Grid.
5.  Shut down the standalone Grid.
6.  Start the Grid in `hub` mode.
7.  Start at least two `node` instances, one for Chrome and one for Firefox (ensuring their respective drivers are in your system PATH).
8.  Verify both Nodes are registered on the Grid UI.
9.  Run the provided Java example code again, observing how it distributes tests to the different browser Nodes.

## Additional Resources
*   **Selenium Grid 4 Documentation:** [https://www.selenium.dev/documentation/grid/](https://www.selenium.dev/documentation/grid/)
*   **Selenium Downloads (for server JAR):** [https://www.selenium.dev/downloads/](https://www.selenium.dev/downloads/)
*   **Browser Driver Downloads:**
    *   ChromeDriver: [https://chromedriver.chromium.org/downloads](https://chromedriver.chromium.org/downloads)
    *   GeckoDriver (Firefox): [https://github.com/mozilla/geckodriver/releases](https://github.com/mozilla/geckodriver/releases)
    *   MSEdgeDriver: [https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/](https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/)
