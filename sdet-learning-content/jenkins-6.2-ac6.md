# Jenkins 6.2 AC6: Execute TestNG/JUnit Tests from Jenkins

## Overview
Automating the execution of your TestNG or JUnit test suites directly within Jenkins is a critical step towards achieving Continuous Integration (CI) and Continuous Delivery (CD). This ensures that every code change is immediately validated against your test suite, providing rapid feedback on the health of the application and preventing regressions. By integrating test execution, Jenkins acts as the central hub for build, test, and deployment, streamlining the development pipeline and enhancing overall product quality.

## Detailed Explanation

Integrating TestNG/JUnit tests into a Jenkins pipeline primarily involves configuring your Jenkins job to:
1.  **Build your project**: Compile source code and tests.
2.  **Execute tests**: Run the compiled tests, often using a build tool like Maven or Gradle.
3.  **Publish test results**: Generate reports that Jenkins can parse and display.
4.  **Handle build failure**: Mark the Jenkins build as failed if tests fail.

We'll focus on Maven and Gradle as they are the most common build tools in Java ecosystems.

### 1. Ensuring Build Command Runs Specific Suite (XML)

Often, you don't want to run *all* tests in your project, but rather a specific subset or a test suite defined in an XML file (common for TestNG, and also usable with JUnit via Surefire/Failsafe plugins).

#### Using Maven (Surefire/Failsafe Plugin)

Maven's Surefire plugin (for unit tests) and Failsafe plugin (for integration tests) are used to execute tests. You can configure them to run specific `testng.xml` files or include/exclude JUnit test classes.

**Example `pom.xml` configuration for TestNG:**
To run `testng.xml` from Maven, configure the Surefire plugin:

```xml
<project>
    <!-- ... other project configurations ... -->
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.0.0-M5</version> <!-- Use a recent version -->
                <configuration>
                    <suiteXmlFiles>
                        <suiteXmlFile>src/test/resources/testng.xml</suiteXmlFile>
                        <!-- You can specify multiple suite XML files -->
                        <!-- <suiteXmlFile>src/test/resources/regression-suite.xml</suiteXmlFile> -->
                    </suiteXmlFiles>
                    <!-- Or specify specific groups/classes for TestNG -->
                    <!-- <groups>smoke,e2e</groups> -->
                    <!-- Or specify includes/excludes for JUnit -->
                    <!--
                    <includes>
                        <include>**/*Test.java</include>
                    </includes>
                    <excludes>
                        <exclude>**/LongRunningTest.java</exclude>
                    </excludes>
                    -->
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

Your `testng.xml` might look like:

```xml
<!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd" >
<suite name="MyTestSuite" verbose="1">
    <test name="SmokeTests">
        <classes>
            <class name="com.example.tests.LoginTest"/>
            <class name="com.example.tests.HomepageTest"/>
        </classes>
    </test>
    <!-- <test name="RegressionTests"> ... </test> -->
</suite>
```

**Jenkins Build Step for Maven:**
In your Jenkins job configuration (e.g., Freestyle project or Pipeline script):
*   **Build Step**: "Invoke top-level Maven targets"
    *   **Goals**: `clean test` (This will execute tests based on `pom.xml` configuration)
    *   To run a specific profile or pass properties: `clean test -Pmy-profile -DsuiteXmlFile=src/test/resources/another-suite.xml`

#### Using Gradle

Gradle's `test` task automatically discovers and runs JUnit or TestNG tests. You can configure the `test` task in `build.gradle` to run specific suites or filter tests.

**Example `build.gradle` configuration for TestNG:**

```gradle
plugins {
    id 'java'
    // id 'org.springframework.boot' version '2.5.4' // if using Spring Boot
}

repositories {
    mavenCentral()
}

dependencies {
    testImplementation 'org.testng:testng:7.4.0' // Use a recent version
    testImplementation 'org.junit.jupiter:junit-jupiter-api:5.8.1' // for JUnit 5
    testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.8.1'
}

test {
    useTestNG() {
        // Specify the TestNG XML suite file
        suites 'src/test/resources/testng.xml'
        // Or include/exclude specific groups
        // includeGroups 'smoke'
        // excludeGroups 'e2e'
    }
    // For JUnit, you can use filters
    // useJUnitPlatform()
    // include 'com/example/tests/LoginTest.java'
    // exclude 'com/example/tests/LongRunningTest.java'
    // testLogging {
    //     events "passed", "skipped", "failed", "standardOut", "standardError"
    // }
}
```

**Jenkins Build Step for Gradle:**
*   **Build Step**: "Invoke Gradle script"
    *   **Tasks**: `clean test` (This will execute tests based on `build.gradle` configuration)
    *   To pass properties: `clean test -Dtestng.suite.path=src/test/resources/another-suite.xml`

### 2. Verifying Console Output Shows Test Runner Logs

After configuring test execution, it's crucial to verify that Jenkins' console output clearly shows the test runner logs. This includes:
*   Which tests are being run.
*   The status of each test (passed, failed, skipped).
*   Any error messages or stack traces for failed tests.
*   Summaries of test execution (e.g., total tests, failures, skips).

Jenkins automatically captures the standard output and standard error of any build step. For Maven and Gradle, their default test outputs are usually descriptive enough.

**Example Console Output (Maven Surefire):**

```
-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running com.example.tests.LoginTest
Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.015 s - in com.example.tests.LoginTest
Running com.example.tests.HomepageTest
Tests run: 3, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 0.020 s <<< FAILURE! - in com.example.tests.HomepageTest
...
Results :
Tests run: 5, Failures: 1, Errors: 0, Skipped: 0
```

You can enhance the verbosity of test logs if needed:
*   **Maven**: Add `-Dsurefire.printSummary=true -Dsurefire.useFile=false` to goals for more console output.
*   **Gradle**: Configure `testLogging` in `build.gradle` as shown in the example above.

### 3. Handling Build Failure Status Correctly Based on Test Results

This is perhaps the most critical part of CI test integration. If tests fail, the Jenkins build *must* fail. This signals to developers immediately that there's a problem that needs attention.

Both Maven Surefire/Failsafe and Gradle's `test` task are designed to return a non-zero exit code if tests fail, which Jenkins interprets as a build failure by default.

#### Publishing Test Reports

To make test results visible and easily digestible in Jenkins, you need to publish them. This involves using Jenkins' "Post-build Actions" or pipeline steps.

**Jenkins Freestyle Project:**
Add a "Post-build Action":
*   **"Publish JUnit test result report"**:
    *   **Test report XMLs**:
        *   For Maven: `**/target/surefire-reports/*.xml, **/target/failsafe-reports/*.xml`
        *   For Gradle: `**/build/test-results/test/*.xml` (The exact path might vary depending on your Gradle configuration and test task name).

**Jenkins Pipeline Project (Declarative Pipeline):**

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                // For Maven
                sh 'mvn clean install -DskipTests' // Build project, skip tests for now
                // For Gradle
                // sh 'gradle clean assemble'
            }
        }
        stage('Test') {
            steps {
                // For Maven: Execute tests
                sh 'mvn test'
                // For Gradle: Execute tests
                // sh 'gradle test'
            }
            post {
                always {
                    // Publish JUnit test results
                    // For Maven:
                    junit '**/target/surefire-reports/*.xml, **/target/failsafe-reports/*.xml'
                    // For Gradle:
                    // junit '**/build/test-results/test/*.xml'
                    
                    // You can add logic to email reports or notify teams here
                    // mail to: 'devs@example.com', subject: "Build ${currentBuild.fullDisplayName} status: ${currentBuild.result}"
                }
            }
        }
    }
    post {
        failure {
            echo "Build failed due to test failures!"
            // Additional actions on failure, e.g., send notifications
        }
        success {
            echo "Build successful, all tests passed!"
        }
    }
}
```

By publishing these reports, Jenkins will:
*   Parse the XML files to show a trend graph of test results over time.
*   Provide a detailed breakdown of test passes, failures, and skips for each build.
*   Allow easy navigation to stack traces and failure messages.
*   Automatically mark the build as "UNSTABLE" if there are test failures but the build itself completed successfully (e.g., compilation passed). If the `test` command itself returns a non-zero exit code, Jenkins will mark the build as "FAILED".

## Code Implementation

Below is a complete, runnable example using Maven and TestNG.

### 1. Project Structure

```
my-automation-project/
├── pom.xml
├── src/
│   └── test/
│       └── java/
│           └── com/
│               └── example/
│                   └── tests/
│                       ├── LoginTest.java
│                       └── HomepageTest.java
│       └── resources/
│           └── testng.xml
```

### 2. `pom.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>my-automation-project</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>8</maven.compiler.source>
        <maven.compiler.target>8</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <testng.version>7.4.0</testng.version>
        <surefire.plugin.version>3.0.0-M5</surefire.plugin.version>
    </properties>

    <dependencies>
        <!-- TestNG Dependency -->
        <dependency>
            <groupId>org.testng</groupId>
            <artifactId>testng</artifactId>
            <version>${testng.version}</version>
            <scope>test</scope>
        </dependency>
        <!-- Optional: Selenium for web tests -->
        <dependency>
            <groupId>org.seleniumhq.selenium</groupId>
            <artifactId>selenium-java</artifactId>
            <version>3.141.59</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <!-- Maven Surefire Plugin for Test Execution -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>${surefire.plugin.version}</version>
                <configuration>
                    <!-- Specify the TestNG suite XML file to run -->
                    <suiteXmlFiles>
                        <suiteXmlFile>src/test/resources/testng.xml</suiteXmlFile>
                    </suiteXmlFiles>
                    <!-- Optional: Print test summary to console -->
                    <printSummary>true</printSummary>
                    <!-- Optional: Don't use a separate file for output, print directly to console -->
                    <useFile>false</useFile>
                    <!-- Optional: Rerun failed tests -->
                    <rerunFailingTestsCount>1</rerunFailingTestsCount>
                </configuration>
            </plugin>
            <!-- Maven Compiler Plugin -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <source>${maven.compiler.source}</source>
                    <target>${maven.compiler.target}</target>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

### 3. `src/test/java/com/example/tests/LoginTest.java`

```java
package com.example.tests;

import org.testng.Assert;
import org.testng.annotations.Test;

public class LoginTest {

    @Test(priority = 1, description = "Verify successful login with valid credentials")
    public void testSuccessfulLogin() {
        System.out.println("Running testSuccessfulLogin...");
        // Simulate login logic
        boolean loginResult = performLogin("validUser", "validPass");
        Assert.assertTrue(loginResult, "Login should be successful");
        System.out.println("testSuccessfulLogin PASSED");
    }

    @Test(priority = 2, description = "Verify login failure with invalid credentials")
    public void testInvalidLogin() {
        System.out.println("Running testInvalidLogin...");
        // Simulate login logic with invalid credentials
        boolean loginResult = performLogin("invalidUser", "wrongPass");
        Assert.assertFalse(loginResult, "Login should fail with invalid credentials");
        System.out.println("testInvalidLogin PASSED");
    }

    private boolean performLogin(String username, String password) {
        // In a real scenario, this would interact with a UI or API
        // For this example, we simulate success for validUser/validPass
        // and failure otherwise.
        return username.equals("validUser") && password.equals("validPass");
    }
}
```

### 4. `src/test/java/com/example/tests/HomepageTest.java`

```java
package com.example.tests;

import org.testng.Assert;
import org.testng.annotations.Test;

public class HomepageTest {

    @Test(description = "Verify homepage title")
    public void testHomepageTitle() {
        System.out.println("Running testHomepageTitle...");
        String expectedTitle = "Welcome to Our Application";
        String actualTitle = getPageTitle(); // Simulate getting title
        Assert.assertEquals(actualTitle, expectedTitle, "Homepage title mismatch");
        System.out.println("testHomepageTitle PASSED");
    }

    @Test(description = "Verify navigation to a specific section (intentional failure example)")
    public void testNavigationToAboutUs() {
        System.out.println("Running testNavigationToAboutUs (EXPECTED TO FAIL)...");
        // Simulate a navigation failure or a bug
        boolean navigationSuccess = navigateToSection("About Us");
        Assert.assertTrue(navigationSuccess, "Navigation to About Us section should be successful"); // This will fail
        System.out.println("testNavigationToAboutUs PASSED (THIS SHOULD NOT PRINT)");
    }

    private String getPageTitle() {
        // Simulate fetching a page title
        return "Welcome to Our Application";
    }

    private boolean navigateToSection(String sectionName) {
        // Simulate navigation logic
        // Let's make it fail for "About Us" to demonstrate build failure
        return !sectionName.equals("About Us");
    }
}
```

### 5. `src/test/resources/testng.xml`

```xml
<!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd" >
<suite name="RegressionSuite" verbose="1">
    <listeners>
        <!-- Optional: Add TestNG listeners for reporting or logging -->
        <!-- <listener class-name="org.testng.reporters.EmailableReporter"/> -->
    </listeners>
    <test name="ApplicationTests">
        <classes>
            <class name="com.example.tests.LoginTest"/>
            <class name="com.example.tests.HomepageTest"/>
        </classes>
    </test>
</suite>
```

### Jenkins Configuration (Pipeline Script Example)

```groovy
// Jenkinsfile (Declarative Pipeline)
pipeline {
    agent any // Or specify a specific agent/node if needed

    tools {
        // Specify Maven tool if configured in Jenkins Global Tool Configuration
        maven 'M3' // 'M3' is the name of the Maven installation in Jenkins
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/your-org/my-automation-project.git' // Replace with your repo URL
            }
        }
        stage('Build and Test') {
            steps {
                echo 'Building and running tests with Maven...'
                // Clean compile and run tests based on pom.xml (which uses testng.xml)
                sh 'mvn clean test'
            }
            post {
                always {
                    // Publish JUnit test results. Jenkins will parse Surefire's XML reports.
                    // This will show test trends and individual test results in Jenkins UI.
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }
    }
    post {
        // Actions to perform after the entire pipeline finishes
        failure {
            echo 'Pipeline failed! Check console output for test failures.'
            // Send email notification on failure
            // mail to: 'qa_team@example.com',
            //      subject: "Jenkins Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            //      body: "Build URL: ${env.BUILD_URL}
Check logs for details."
        }
        success {
            echo 'Pipeline successful! All tests passed.'
        }
        unstable {
            // Build is unstable if tests failed but the build step itself didn't crash
            echo 'Pipeline unstable! Some tests failed.'
        }
    }
}
```

## Best Practices
-   **Parameterize Test Suites**: Use Jenkins parameters to allow users to select which `testng.xml` suite or JUnit tag/category to run, enabling flexible execution (e.g., smoke, regression, sanity).
-   **Clean Workspace**: Always perform a `clean` build (`mvn clean test` or `gradle clean test`) to ensure tests are run against fresh code and no stale artifacts interfere.
-   **Isolate Test Data**: Ensure tests are independent and don't rely on the state left by previous tests. Use setup/teardown methods (`@BeforeMethod`/`@AfterMethod` in TestNG, `@BeforeEach`/`@AfterEach` in JUnit 5) to prepare and clean test data.
-   **Fast Feedback**: Strive for fast-running test suites in CI. Long-running integration or E2E tests might be better placed in a separate, scheduled job or a later stage of the pipeline.
-   **Detailed Reporting**: Leverage Jenkins' built-in test result publishing to get rich reports. Consider external reporting tools (e.g., ExtentReports, Allure) for even more detailed and visually appealing reports, integrated as a post-build step.
-   **Source Control Management**: Always run tests on code checked out from your SCM (Git, SVN) to ensure consistency and traceability.

## Common Pitfalls
-   **Tests Not Being Run**: Forgetting to configure the Surefire/Failsafe plugin or the Gradle `test` task correctly, leading to Jenkins reporting a successful build even if tests exist but weren't executed. Always check the console output.
-   **Missing Test Reports**: Not configuring the "Publish JUnit test result report" post-build action or using an incorrect path for XML reports, resulting in no test result trends or details in Jenkins.
-   **Incorrect Failure Handling**: If tests fail but the build still shows "SUCCESS" or "UNSTABLE" when it should be "FAILED," check if the test command itself (e.g., `mvn test`) is returning a non-zero exit code on failure, and if not, adjust the build step or pipeline logic. The `junit` step in pipelines usually handles marking `UNSTABLE` automatically if there are failures.
-   **Environment Differences**: Tests passing locally but failing in Jenkins due to environmental discrepancies (e.g., different Java versions, missing dependencies, firewall issues). Ensure the Jenkins agent environment mirrors the local development environment as much as possible.
-   **Flaky Tests**: Tests that intermittently pass or fail can cause CI instability. Identify and fix flaky tests promptly to maintain confidence in your pipeline.

## Interview Questions & Answers

1.  **Q: How do you ensure Jenkins runs a specific subset of your tests, not all of them?**
    **A:** For Maven, I'd configure the `maven-surefire-plugin` (or `maven-failsafe-plugin` for integration tests) in the `pom.xml` to specify `suiteXmlFiles` for TestNG, or `includes`/`excludes` for JUnit classes. In the Jenkins build step, I'd simply invoke `mvn clean test`. For Gradle, I'd configure the `test` task in `build.gradle` using `useTestNG { suites 'path/to/suite.xml' }` or JUnit filters, then invoke `gradle clean test` in Jenkins.
2.  **Q: What steps would you take to make sure failed tests correctly mark a Jenkins build as a failure?**
    **A:** The primary mechanism is that build tools like Maven (`mvn test`) and Gradle (`gradle test`) return a non-zero exit code if tests fail, which Jenkins interprets as a build failure. Additionally, I would configure the "Publish JUnit test result report" post-build action (or `junit` step in Pipeline) to parse the test result XMLs (e.g., `**/target/surefire-reports/*.xml`). This ensures Jenkins displays test trends and marks the build as "UNSTABLE" (if tests fail but the build command itself didn't crash) or "FAILED" (if the test command exits with an error code).
3.  **Q: How do you get detailed test reports and historical trends in Jenkins after test execution?**
    **A:** After test execution, I use the "Publish JUnit test result report" post-build action in a Freestyle job, or the `junit` step in a Declarative Pipeline. I configure it to point to the test report XML files generated by my build tool (e.g., `**/target/surefire-reports/*.xml` for Maven or `**/build/test-results/test/*.xml` for Gradle). Jenkins then parses these files, displays a summary, individual test results with stack traces, and generates historical trend graphs.

## Hands-on Exercise

**Objective**: Set up a simple Java project with TestNG (or JUnit), configure it to run a specific test suite via Maven (or Gradle), and then simulate its execution in a Jenkins-like environment.

1.  **Prerequisites**:
    *   Java Development Kit (JDK) installed.
    *   Maven (or Gradle) installed.
    *   Familiarity with creating a project structure.
2.  **Steps**:
    *   Create a new Maven (or Gradle) project.
    *   Add TestNG (or JUnit) and Selenium (optional, but good for web tests) dependencies to your `pom.xml` (or `build.gradle`).
    *   Create two sample test classes (e.g., `LoginTest`, `ProductSearchTest`), with at least one test method designed to fail intentionally.
    *   Create a `testng.xml` file (or configure Gradle to filter JUnit tests) to include these two test classes.
    *   Configure your `pom.xml`'s Surefire plugin (or `build.gradle`'s `test` task) to use this `testng.xml` file.
    *   Open your terminal in the project root and run `mvn clean test` (or `gradle clean test`).
    *   Observe the console output:
        *   Does it show all tests being run?
        *   Does it correctly report the passed and failed tests?
        *   Does Maven/Gradle exit with a non-zero status code (indicating failure) if your intentional failure occurred?
    *   (Optional, but highly recommended): If you have a local Jenkins instance, create a new Freestyle or Pipeline job, configure it to checkout your project, execute the `mvn clean test` command, and publish the JUnit test results. Observe how Jenkins displays the test results and build status.

## Additional Resources
-   **Maven Surefire Plugin Documentation**: [https://maven.apache.org/surefire/maven-surefire-plugin/](https://maven.apache.org/surefire/maven-surefire-plugin/)
-   **TestNG Documentation**: [https://testng.org/doc/index.html](https://testng.org/doc/index.html)
-   **JUnit 5 User Guide**: [https://junit.org/junit5/docs/current/user-guide/](https://junit.org/junit5/docs/current/user-guide/)
-   **Gradle Test Task Documentation**: [https://docs.gradle.org/current/userguide/java_testing.html](https://docs.gradle.org/current/userguide/java_testing.html)
-   **Jenkins Pipeline Syntax**: [https://www.jenkins.io/doc/book/pipeline/syntax/](https://www.jenkins.io/doc/book/pipeline/syntax/)