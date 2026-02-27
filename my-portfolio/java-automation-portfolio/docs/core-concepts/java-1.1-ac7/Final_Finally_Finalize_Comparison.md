# Java Keywords: final, finally, and finalize

## Technical Comparison Table

| Feature | final | finally | finalize() |
| :--- | :--- | :--- | :--- |
| **Type** | Keyword | Block | Method |
| **Primary Purpose** | To restrict modification (create constants, prevent overriding/inheritance). | To guarantee execution of code for cleanup, regardless of exceptions. | To perform last-minute cleanup before an object is garbage collected. |
| **Execution Timing** | Enforced at compile-time. | Executes immediately after a `try` or `try-catch` block. | Executes at an unknown time, just before the object is reclaimed by the GC. |
| **Reliability** | Completely reliable (compile-time guarantee). | Very reliable; always runs except for JVM shutdown (`System.exit()`). | Unreliable; execution is not guaranteed. Deprecated since Java 9. |

## SDET Perspective: Resource Management

### Why use `finally` for `driver.quit()`?
In test automation, it is critical to ensure that the `WebDriver` instance is closed at the end of a test run. A test can fail for many reasons—an element not found, an assertion error, etc.—which often throws an exception.

If `driver.quit()` is placed at the end of a test method without a `finally` block, it will be skipped whenever an exception occurs. This leaves the browser process running in the background, consuming system resources (memory, CPU). Running multiple tests like this can quickly slow down or crash the execution machine.

By placing `driver.quit()` inside a `finally` block, we **guarantee** that the browser will be closed and the session will be terminated, whether the test passes or fails. This is essential for stable and reliable test execution environments.

### Why is `finalize()` avoided in modern automation?
The `finalize()` method is completely unsuitable for managing critical resources like a `WebDriver` instance for several reasons:

1.  **Unpredictable Execution:** There is no guarantee *when* or even *if* the garbage collector will run and call `finalize()`. A test suite could finish, and the browser instances could remain open for an indefinite amount of time, or not be closed at all.
2.  **Lack of Control:** Test automation requires deterministic, immediate control over resources. We need the browser to close *right after* the test is done, not at some arbitrary point in the future.
3.  **Deprecated and Discouraged:** `finalize()` has been deprecated since Java 9. Modern Java development strongly discourages its use in favor of more explicit and reliable mechanisms like `try-with-resources` or the `finally` block.

Relying on `finalize()` for resource management in an automation framework would lead to flaky, unstable, and resource-intensive test runs.
