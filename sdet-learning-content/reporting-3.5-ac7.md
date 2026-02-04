# Test Execution Videos for Failed Tests

## Overview
Automated tests are crucial for ensuring software quality. However, when tests fail, understanding *why* they failed can be challenging, especially in complex UIs or flaky test environments. Integrating test execution videos provides invaluable visual context, allowing developers and QA engineers to precisely pinpoint the root cause of failures by replaying the user's journey and observing the exact state of the application at the time of the error. This significantly reduces debugging time and improves test reliability.

## Detailed Explanation
Adding test execution videos to your automation framework involves several key steps:

1.  **Choosing a Video Recording Library**: For Java-based Selenium frameworks, popular choices include Monte Screen Recorder (pure Java) or leveraging browser-native recording capabilities (if available and integrated via WebDriver extensions). For Playwright, video recording is a built-in feature.
2.  **Integration**: The chosen library needs to be integrated into your test framework. This typically means adding dependencies to your `pom.xml` or `build.gradle` (for Maven/Gradle) or configuring Playwright.
3.  **Start Recording**: Video recording should ideally start right before the test method execution. In TestNG, this can be done using `@BeforeMethod` annotations or listener methods (`onTestStart`). For Playwright, it's configured during browser context creation.
4.  **Stop Recording**: Recording should stop immediately after the test method completes, regardless of its outcome. This can be handled in `@AfterMethod` or `onTestFinish` listener methods.
5.  **Conditional Saving/Deletion**: This is a critical step. Videos should *only* be retained if the test fails. If the test passes, the video file should be deleted to save storage space and focus on problematic areas. TestNG's `ITestResult` object provides information about the test status.
6.  **Linking to Reports**: The path to the saved video file must be included in the test report (e.g., Allure Report, Extent Report). This allows users to easily click and view the video directly from the report interface.

### Example Scenario:
Imagine a test fails because an element was not clickable. Without a video, you might check logs, screenshots, and element locators. With a video, you can see if the element was obscured, if an unexpected popup appeared, or if the page was still loading, providing immediate visual evidence.

## Code Implementation (Java with TestNG/Selenium and Monte Screen Recorder)

This example demonstrates integrating Monte Screen Recorder with a TestNG/Selenium framework.

First, add the Monte Screen Recorder dependency to your `pom.xml`:

```xml
<!-- pom.xml -->
<dependency>
    <groupId>com.github.stephenc.monte</groupId>
    <artifactId>monte-screen-recorder</artifactId>
    <version>0.7.7.0</version>
</dependency>
```

Now, implement a TestNG listener or modify your base test class:

```java
// src/test/java/com/example/listeners/VideoRecorderListener.java
package com.example.listeners;

import org.monte.media.Format;
import org.monte.media.FormatKeys.MediaType;
import org.monte.media.math.Rational;
import org.monte.screenrecorder.ScreenRecorder;
import org.openqa.selenium.WebDriver;
import org.testng.ITestContext;
import org.testng.ITestListener;
import org.testng.ITestResult;

import java.awt.*;
import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import static org.monte.media.AudioFormatKeys.*;
import static org.monte.media.FormatKeys.*;
import static org.monte.media.VideoFormatKeys.*;

public class VideoRecorderListener implements ITestListener {

    private ScreenRecorder screenRecorder;
    private File videoFile;
    private static Map<Long, ScreenRecorder> recorderMap = new HashMap<>(); // To handle parallel execution

    // Method to get the current WebDriver instance (adjust based on your framework)
    private WebDriver getDriver(ITestResult result) {
        // Assuming WebDriver is stored in a ThreadLocal or passed via dependency injection
        // This is a placeholder; you'll need to adapt this to your actual WebDriver management
        Object currentClass = result.getInstance();
        try {
            return (WebDriver) currentClass.getClass().getMethod("getDriver").invoke(currentClass);
        } catch (Exception e) {
            System.err.println("Could not get WebDriver instance from test class: " + e.getMessage());
            return null;
        }
    }

    @Override
    public void onTestStart(ITestResult result) {
        try {
            // Define the folder to save videos
            File videosFolder = new File("test-videos");
            if (!videosFolder.exists()) {
                videosFolder.mkdirs();
            }

            // Get screen size
            GraphicsConfiguration gc = GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice().getDefaultConfiguration();

            this.screenRecorder = new ScreenRecorder(gc,
                    gc.getBounds(), // Capture the entire screen
                    new Format(MediaTypeKey, MediaType.FILE, MimeTypeKey, MIME_AVI), // AVI format
                    new Format(MediaTypeKey, MediaType.VIDEO, EncodingKey, ENCODING_AVI_TECHSMITH_MJPG,
                            CompressorNameKey, ENCODING_AVI_TECHSMITH_MJPG, DepthKey, 24, FrameRateKey, Rational.valueOf(15),
                            QualityKey, 1.0f, KeyFrameIntervalKey, 15 * 60), // Video format
                    new Format(MediaTypeKey, MediaType.VIDEO, EncodingKey, "black", FrameRateKey, Rational.valueOf(30)), // Mouse format
                    null, // Audio format (no audio)
                    videosFolder);

            // Generate a unique file name for the video
            String methodName = result.getMethod().getMethodName();
            String timestamp = new SimpleDateFormat("yyyyMMdd-HHmmss").format(new Date());
            this.videoFile = new File(videosFolder, methodName + "_" + timestamp + ".avi");
            // Store the recorder for the current thread
            recorderMap.put(Thread.currentThread().getId(), this.screenRecorder);

            this.screenRecorder.start();
            System.out.println("Video recording started for: " + methodName);

        } catch (IOException | AWTException e) {
            System.err.println("Failed to start video recording: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @Override
    public void onTestSuccess(ITestResult result) {
        ScreenRecorder currentRecorder = recorderMap.get(Thread.currentThread().getId());
        if (currentRecorder != null) {
            try {
                currentRecorder.stop();
                System.out.println("Video recording stopped for successful test: " + result.getMethod().getMethodName());
                // Delete video if test passed
                if (videoFile != null && videoFile.exists()) {
                    if (videoFile.delete()) {
                        System.out.println("Deleted video for passed test: " + videoFile.getName());
                    } else {
                        System.err.println("Failed to delete video for passed test: " + videoFile.getName());
                    }
                }
            } catch (IOException e) {
                System.err.println("Failed to stop or delete video for successful test: " + e.getMessage());
                e.printStackTrace();
            } finally {
                recorderMap.remove(Thread.currentThread().getId());
            }
        }
    }

    @Override
    public void onTestFailure(ITestResult result) {
        ScreenRecorder currentRecorder = recorderMap.get(Thread.currentThread().getId());
        if (currentRecorder != null) {
            try {
                currentRecorder.stop();
                System.out.println("Video recording stopped for failed test: " + result.getMethod().getMethodName());
                // Attach video to Allure report (if Allure is integrated)
                if (videoFile != null && videoFile.exists()) {
                    System.out.println("Video saved for failed test: " + videoFile.getAbsolutePath());
                    // If using Allure, you can attach the video like this:
                    // Allure.addAttachment("Test Video", "video/avi", new FileInputStream(videoFile), "avi");
                    // Ensure you have `allure-attachments` dependency if using Allure
                }
            } catch (IOException e) {
                System.err.println("Failed to stop video for failed test: " + e.getMessage());
                e.printStackTrace();
            } finally {
                recorderMap.remove(Thread.currentThread().getId());
            }
        }
    }

    @Override
    public void onTestSkipped(ITestResult result) {
        // Optional: Handle skipped tests. Usually, no video needed.
        onTestSuccess(result); // Treat skipped as successful for video deletion purposes
    }

    @Override
    public void onTestFailedButWithinSuccessPercentage(ITestResult result) {
        // Same as failure
        onTestFailure(result);
    }

    @Override
    public void onStart(ITestContext context) {
        // Not used for per-test video recording
    }

    @Override
    public void onFinish(ITestContext context) {
        // Not used for per-test video recording
    }
}
```

### How to use the Listener:
Add the listener to your `testng.xml` file:

```xml
<!-- testng.xml -->
<!DOCTYPE suite SYSTEM "https://testng.org/testng-1.0.dtd">
<suite name="TestSuite">
    <listeners>
        <listener class-name="com.example.listeners.VideoRecorderListener"/>
    </listeners>
    <test name="VideoRecordingTests">
        <classes>
            <class name="com.example.tests.MySeleniumTest"/>
        </classes>
    </test>
</suite>
```

Or programmatically in your BaseTest:

```java
// In your BaseTest class or equivalent
// This is a placeholder for how you might manage WebDriver
public class BaseTest {
    protected WebDriver driver;

    // ... your WebDriver setup and teardown methods ...

    public WebDriver getDriver() {
        return driver;
    }
}
```

## Best Practices
- **Conditional Recording**: Only record videos for specific test suites or environments where visual debugging is most critical (e.g., UI tests, critical user flows). Avoid recording all tests if not necessary to save resources.
- **Efficient Storage**: Implement a strategy for video storage. For CI/CD, consider archiving videos to cloud storage or a network drive, and regularly purge old videos.
- **Reporting Integration**: Ensure video links are directly accessible from your test reports (e.g., Allure, ExtentReports) for easy access.
- **Performance Impact**: Be aware that video recording can consume CPU and disk I/O, potentially increasing test execution time. Profile and optimize if performance becomes an issue.
- **Resolution and Frame Rate**: Choose appropriate video resolution and frame rate. Higher values mean larger files and more resource consumption. 15-20 FPS is often sufficient for UI tests.
- **Parallel Execution**: If running tests in parallel, ensure your video recording mechanism can handle multiple recordings simultaneously without conflicts (e.g., using `ThreadLocal` for `ScreenRecorder` instances as shown in the example).
- **Error Handling**: Robust error handling around recording start/stop operations is crucial to prevent test failures due to recording issues.

## Common Pitfalls
- **Missing Dependencies**: Forgetting to add the video recording library to your project's build file.
- **Storage Issues**: Running out of disk space on the CI server due to retaining all video files, even for passed tests.
- **Incorrect Driver Management**: If WebDriver instances are not properly managed (e.g., not thread-safe in parallel execution), the video recorder might capture the wrong screen or fail to get the correct context.
- **Poor Reporting Links**: Video links in reports are broken or point to inaccessible locations (e.g., local paths that don't exist on the machine viewing the report).
- **Overhead**: Significant performance degradation if recording is not optimized (e.g., too high resolution, frame rate, or recording for all tests unnecessarily).
- **Headless Mode**: Video recording might not work as expected in headless browser modes without proper configuration or if the recording library relies on a graphical display. Playwright handles this gracefully, but other tools might struggle.

## Interview Questions & Answers
1.  **Q: Why is adding test execution videos to your automation framework important?**
    **A:** Test execution videos provide crucial visual context for debugging failed automated tests. They allow QA engineers and developers to see exactly what happened on the screen during a test run, observing UI states, unexpected pop-ups, element interactions, and timing issues that are often difficult to diagnose solely from logs and screenshots. This drastically reduces the time spent on root cause analysis and improves the overall efficiency of the debugging process.

2.  **Q: What considerations should be made when choosing a video recording library for test automation?**
    **A:** Key considerations include:
    *   **Language and Framework Compatibility**: Ensure the library integrates well with your existing automation stack (e.g., Java/Selenium, JavaScript/Playwright).
    *   **Ease of Integration**: How complex is it to set up and use?
    *   **Features**: Does it support configurable resolution, frame rates, audio (if needed), and various output formats?
    *   **Performance Impact**: How much overhead does it add to test execution?
    *   **Parallel Execution Support**: Can it handle concurrent test runs without conflicts?
    *   **Reporting Integration**: How easily can video links be embedded into your test reports?
    *   **Maintenance and Community Support**: Is the library actively maintained, and does it have a community for support?

3.  **Q: How do you manage video files to avoid excessive storage consumption in a CI/CD pipeline?**
    **A:** To manage storage:
    *   **Conditional Saving**: Only retain videos for failed tests. Delete videos for passed tests immediately after completion.
    *   **Retention Policies**: Implement automated cleanup jobs to delete old video files after a certain period (e.g., 7 days) or based on project importance.
    *   **Compression**: Use efficient video codecs and settings (lower resolution, frame rate) to reduce file size.
    *   **Archiving**: For long-term retention of critical failure videos, consider archiving them to cheaper cloud storage solutions (e.g., AWS S3 Glacier, Azure Blob Storage).
    *   **Centralized Storage**: Store videos on a centralized server or cloud storage accessible to all team members rather than on individual build agents.

## Hands-on Exercise
**Objective**: Implement video recording for a simple Selenium test that intentionally fails.

1.  **Setup**:
    *   Create a new Maven or Gradle project.
    *   Add Selenium WebDriver and TestNG dependencies.
    *   Add Monte Screen Recorder dependency (as shown in the `pom.xml` example).
    *   Set up a basic Selenium test (e.g., navigate to a website).

2.  **Task**:
    *   Modify the test to include the `VideoRecorderListener` (or integrate the recording logic directly).
    *   **Intentionally make the test fail**: For example, try to find an element with a wrong locator (`driver.findElement(By.id("nonExistentElement")).click();`).
    *   Run the test.
    *   Verify that a video file is created in the `test-videos` folder for the failed test.
    *   Run a passing test (e.g., just navigate to google.com and assert title), and verify that no video file is retained.

3.  **Bonus**: If you have Allure reporting integrated, try to attach the video to the Allure report using `Allure.addAttachment()`.

## Additional Resources
-   **Monte Screen Recorder GitHub**: [https://github.com/stephenc/monte-screen-recorder](https://github.com/stephenc/monte-screen-recorder)
-   **Selenium WebDriver**: [https://www.selenium.dev/documentation/](https://www.selenium.dev/documentation/)
-   **TestNG Official Documentation**: [https://testng.org/doc/index.html](https://testng.org/doc/index.html)
-   **Allure Framework Documentation (for reporting integration)**: [https://docs.qameta.io/allure/](https://docs.qameta.io/allure/)
-   **Playwright Video Recording**: [https://playwright.dev/docs/videos](https://playwright.dev/docs/videos) (If considering Playwright for future automation)
