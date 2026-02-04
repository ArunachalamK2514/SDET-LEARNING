# Custom Test Reports: Execution Summary, Pass/Fail Counts, and System Info

## Overview
Test automation reports are crucial for understanding the health of an application and the effectiveness of the test suite. While standard reporting tools provide basic outcomes, custom reports offer invaluable insights by presenting key metrics tailored to project needs. This feature focuses on creating a custom report that includes a comprehensive test execution summary, detailed pass/fail counts, calculated pass/fail percentages, individual test execution durations, and essential system information like OS and Java version. Such reports empower stakeholders with a clear, concise, and actionable view of test results, facilitating quicker decision-making and efficient debugging.

## Detailed Explanation

Custom reporting typically extends an existing reporting framework (e.g., ExtentReports, Allure, TestNG's built-in reporters) or involves building one from scratch, though extending is far more common and recommended.

For this feature, we will enhance a report to include:

1.  **System Information (OS, Java Version):** This context is vital for debugging environment-specific issues. If a test fails only on a specific OS or Java version, this information immediately highlights the potential root cause.
2.  **Pass/Fail Percentage Calculation:** Beyond raw counts, percentages provide a quick health check and enable easier trend analysis across multiple test runs. A decreasing pass percentage is an immediate red flag.
3.  **Execution Duration for Each Test:** Knowing how long each test takes helps identify performance bottlenecks in the tests themselves or in the application under test. It's also critical for optimizing test suite execution time.

Let's assume we are using **ExtentReports** as our reporting framework, given its popularity and flexibility. ExtentReports allows adding system information, custom statistics, and logging individual test durations.

### Adding System Information

ExtentReports provides `ExtentReports.setSystemInfo()` method to add custom environment details. This should typically be done once at the beginning of the test suite execution.

### Implementing Pass/Fail Percentage Calculation

ExtentReports automatically tracks pass/fail counts for tests. To calculate percentages, we can retrieve these counts from the `ExtentReports` object or `ExtentTest` objects after all tests have run and then perform simple arithmetic. The `onFinish` method of TestNG's `ISuiteListener` or `IReporter` interface is an ideal place for this logic.

### Displaying Execution Duration for Each Test

ExtentReports captures the start and end time of each test automatically. The duration is then displayed as part of the test details. When creating a `ExtentTest` instance, the framework records when the test starts and when its status (pass/fail/skip) is logged, effectively giving us the duration.

## Code Implementation

Below is an example integrating these features using TestNG and ExtentReports.

First, ensure you have the necessary dependencies in your `pom.xml` (for Maven):

```xml
<dependencies>
    <dependency>
        <groupId>org.testng</groupId>
        <artifactId>testng</artifactId>
        <version>7.8.0</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>com.aventstack</groupId>
        <artifactId>extentreports</artifactId>
        <version>5.0.9</version>
    </dependency>
    <!-- Add your Selenium/Appium/REST Assured dependencies here -->
</dependencies>
```

Next, create a custom listener that implements `IReporter` or `ISuiteListener` (for more granular control over report generation and calculations). Here, we'll use `IReporter` to fully customize the report generation process.

**`src/main/java/com/example/listeners/CustomExtentReporter.java`**

```java
package com.example.listeners;

import com.aventstack.extentreports.ExtentReports;
import com.aventstack.extentreports.ExtentTest;
import com.aventstack.extentreports.Status;
import com.aventstack.extentreports.reporter.ExtentSparkReporter;
import org.testng.*;
import org.testng.xml.XmlSuite;

import java.io.File;
import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.text.DecimalFormat;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class CustomExtentReporter implements IReporter {

    private ExtentReports extent;
    private static final DecimalFormat DF = new DecimalFormat("0.00");

    @Override
    public void generateReport(List<XmlSuite> xmlSuites, List<ISuite> suites, String outputDirectory) {
        String reportFileName = "TestReport_" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss")) + ".html";
        String reportPath = outputDirectory + File.separator + reportFileName;

        ExtentSparkReporter sparkReporter = new ExtentSparkReporter(reportPath);
        sparkReporter.config().setReportName("Automation Test Execution Report");
        sparkReporter.config().setDocumentTitle("Test Results");
        
        extent = new ExtentReports();
        extent.attachReporter(sparkReporter);

        // Add System Information
        try {
            extent.setSystemInfo("Host Name", InetAddress.getLocalHost().getHostName());
            extent.setSystemInfo("OS", System.getProperty("os.name"));
            extent.setSystemInfo("Java Version", System.getProperty("java.version"));
            extent.setSystemInfo("User Name", System.getProperty("user.name"));
        } catch (UnknownHostException e) {
            extent.setSystemInfo("Host Name", "Unknown");
        }

        int totalTests = 0;
        int passedTests = 0;
        int failedTests = 0;
        int skippedTests = 0;

        for (ISuite suite : suites) {
            Map<String, ISuiteResult> result = suite.getResults();

            for (ISuiteResult r : result.values()) {
                ITestContext context = r.getTestContext();

                // Get Passed Tests
                Set<ITestResult> passed = context.getPassedTests().getAllResults();
                for (ITestResult testResult : passed) {
                    createTest(testResult, extent);
                    passedTests++;
                }

                // Get Failed Tests
                Set<ITestResult> failed = context.getFailedTests().getAllResults();
                for (ITestResult testResult : failed) {
                    createTest(testResult, extent);
                    failedTests++;
                }

                // Get Skipped Tests
                Set<ITestResult> skipped = context.getSkippedTests().getAllResults();
                for (ITestResult testResult : skipped) {
                    createTest(testResult, extent);
                    skippedTests++;
                }
                
                totalTests += passed.size() + failed.size() + skipped.size();
            }
        }
        
        // Calculate percentages
        double passPercentage = (totalTests == 0) ? 0 : (double) passedTests * 100 / totalTests;
        double failPercentage = (totalTests == 0) ? 0 : (double) failedTests * 100 / totalTests;
        double skipPercentage = (totalTests == 0) ? 0 : (double) skippedTests * 100 / totalTests;

        // Add overall summary to the report (can be customized further)
        // This is a simple log entry; for a dedicated summary section, you might need
        // to customize the Extent HTML template or create a separate summary file.
        extent.createTest("Test Execution Summary")
              .log(Status.INFO, "Total Tests Run: " + totalTests)
              .log(Status.INFO, "Passed Tests: " + passedTests + " (" + DF.format(passPercentage) + "%)")
              .log(Status.INFO, "Failed Tests: " + failedTests + " (" + DF.format(failPercentage) + "%)")
              .log(Status.INFO, "Skipped Tests: " + skippedTests + " (" + DF.format(skipPercentage) + "%)");

        extent.flush(); // Writes the report to the file
    }

    private void createTest(ITestResult testResult, ExtentReports extent) {
        String testName = testResult.getMethod().getMethodName();
        ExtentTest test = extent.createTest(testName);
        
        // Log status and duration
        if (testResult.getStatus() == ITestResult.SUCCESS) {
            test.log(Status.PASS, "Test Passed");
        } else if (testResult.getStatus() == ITestResult.FAILURE) {
            test.log(Status.FAIL, "Test Failed: " + testResult.getThrowable());
        } else if (testResult.getStatus() == ITestResult.SKIP) {
            test.log(Status.SKIP, "Test Skipped");
        }

        long duration = testResult.getEndMillis() - testResult.getStartMillis();
        test.log(Status.INFO, "Execution Duration: " + duration + " ms");
    }
}
```

**`src/test/java/com/example/tests/SampleTest.java`**

```java
package com.example.tests;

import org.testng.Assert;
import org.testng.annotations.Listeners;
import org.testng.annotations.Test;
import com.example.listeners.CustomExtentReporter;

// Link the custom reporter to the test suite or specific test classes
@Listeners(CustomExtentReporter.class)
public class SampleTest {

    @Test
    public void successfulLoginTest() {
        System.out.println("Executing successfulLoginTest");
        Assert.assertTrue(true, "Login should be successful");
    }

    @Test
    public void failedLoginTest() {
        System.out.println("Executing failedLoginTest");
        Assert.fail("Simulating a failed login scenario");
    }

    @Test(dependsOnMethods = "failedLoginTest")
    public void skippedProfileUpdateTest() {
        System.out.println("Executing skippedProfileUpdateTest");
        // This test will be skipped because failedLoginTest failed
        Assert.assertTrue(true, "Profile update should be successful");
    }

    @Test
    public void anotherSuccessfulTest() throws InterruptedException {
        System.out.println("Executing anotherSuccessfulTest");
        Thread.sleep(1500); // Simulate some work
        Assert.assertEquals(1, 1, "Numbers should match");
    }
}
```

To run this with TestNG, you would typically use a `testng.xml` file:

**`testng.xml`**

```xml
<!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd">
<suite name="MyTestSuite">
    <listeners>
        <listener class-name="com.example.listeners.CustomExtentReporter"/>
    </listeners>
    <test name="SampleTestSuite">
        <classes>
            <class name="com.example.tests.SampleTest"/>
        </classes>
    </test>
</suite>
```

Run using `mvn clean test` or directly via TestNG. The report will be generated in `test-output/TestReport_YYYYMMDD_HHMMSS.html`.

## Best Practices
- **Use a Dedicated Reporting Framework:** Don't reinvent the wheel. Leverage powerful frameworks like ExtentReports, Allure, or ReportNG that provide rich features out-of-the-box.
- **Automate Report Generation:** Integrate report generation into your CI/CD pipeline so reports are automatically created after every test run.
- **Keep Reports Concise and Actionable:** Focus on key metrics and information that help in understanding test outcomes and debugging. Avoid excessive verbosity.
- **Visualizations:** Utilize graphical representations (charts, graphs) if your reporting framework supports them, as they convey information much faster than raw numbers.
- **Environment Context:** Always include crucial environment details (OS, browser version, application version, Java version, etc.) in the report.
- **Link to Logs/Screenshots:** Ensure the report links to detailed test logs and screenshots for failed tests.

## Common Pitfalls
- **Over-customization:** Spending too much time building a custom reporting solution from scratch instead of extending an existing one. This can lead to maintenance overhead.
- **Missing Key Information:** Reports lacking essential data like execution duration, system info, or clear pass/fail breakdowns, making them less useful for analysis.
- **Inconsistent Reporting:** Different test suites or modules generating reports in varying formats, making consolidated analysis difficult.
- **Performance Overhead:** Inefficient report generation logic or excessive logging can slow down test execution.
- **Lack of Archiving:** Not archiving historical reports, which prevents trend analysis and comparison over time.

## Interview Questions & Answers

1.  **Q: How do you ensure your test reports are comprehensive and provide actionable insights?**
    A: I focus on including not just basic pass/fail status, but also key metrics like pass/fail percentages, individual test execution times, and critical environmental context (OS, browser, Java version). For failures, linking to screenshots and detailed logs is essential. Utilizing frameworks like ExtentReports allows for rich, interactive reports that can be easily shared with stakeholders. I also advocate for integrating these reports into CI/CD pipelines for automated generation and trend analysis.

2.  **Q: Describe how you would add custom system information (e.g., OS, Java version) to your test reports.**
    A: Using ExtentReports, I would leverage `extent.setSystemInfo("Key", "Value")`. This is typically done once, during the initialization of the `ExtentReports` object, often within a TestNG listener (like `IReporter` or `ISuiteListener`) before any tests begin. I'd retrieve system properties using `System.getProperty("os.name")`, `System.getProperty("java.version")`, etc., and possibly use `InetAddress.getLocalHost().getHostName()` for host information.

3.  **Q: How do you handle tracking execution duration for individual tests in your reports, and why is this important?**
    A: Most robust reporting frameworks, like ExtentReports, automatically capture the start and end times of each test method. They then calculate and display the duration as part of the test details. This is crucial for identifying slow tests, which could indicate performance issues in the application under test or inefficiencies in the test automation code itself. It helps in prioritizing test optimization efforts.

4.  **Q: What are the benefits of calculating and displaying pass/fail percentages in test reports versus just showing raw counts?**
    A: Percentages provide a normalized view of test outcomes, making it much easier to compare results across different test runs or test suites, especially when the total number of tests might vary. A percentage gives an immediate sense of the overall health and stability of the system, acting as a quick indicator of regression or improvement. Raw counts can be misleading without context of the total number of tests.

## Hands-on Exercise

**Objective:** Enhance an existing TestNG/Selenium project to generate a custom ExtentReport that includes:
1.  Current browser version in system info.
2.  A custom category/tag for each test method (e.g., "Smoke", "Regression").
3.  A custom summary section at the top of the report displaying the total number of tests run, passed, failed, and skipped.

**Instructions:**
1.  Set up a basic TestNG project with Selenium WebDriver (or any other automation framework).
2.  Integrate ExtentReports as shown in the example above.
3.  Modify the `CustomExtentReporter` to:
    *   Add the browser version to `setSystemInfo`. You'll need a way to pass this information from your test classes (e.g., via a TestNG `@BeforeSuite` method storing it in a thread-safe manner).
    *   Add categories to `ExtentTest` instances using `test.assignCategory("YourCategory")`.
    *   Find a way to inject a summary section using the `IReporter` interface or by customizing the `ExtentSparkReporter` further.
4.  Run your tests and verify the report contains all the new information.

## Additional Resources
-   **ExtentReports Official Documentation:** [https://www.extentreports.com/docs/versions/5/java/index.html](https://www.extentreports.com/docs/versions/5/java/index.html)
-   **TestNG Listeners:** [https://testng.org/doc/documentation-main.html#testng-listeners](https://testng.org/doc/documentation-main.html#testng-listeners)
-   **Maven Repository for ExtentReports:** [https://mvnrepository.com/artifact/com.aventstack/extentreports](https://mvnrepository.com/artifact/com.aventstack/extentreports)
