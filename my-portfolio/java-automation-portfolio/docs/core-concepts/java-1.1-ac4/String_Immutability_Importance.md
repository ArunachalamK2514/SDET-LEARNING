# String Immutability in Java

## Definition
*What does it mean that Strings are immutable?*
    This means that after the String object is created, it can never be changed. Any operations that is performed like `concat()` or `replace()` will only return a new string object and does not modify the original string object. This original string object will be garbage collected by the JVM if it is not referenced anywhere else in the code.

## Why are Strings Immutable?
*List 2-3 reasons (e.g., Security, String Pool, Thread Safety).*
 - Thread safety: Since strings are immutable, they can be shared safely between the threadds without the need to have synchronized blocks.
 - Security: Once the security check is performed on a string, it can never be modified before use. So malicious code can't actually modify the original string.
 - Since strings are immutable, the JVM knows that the literals can't be changed and hence it references same literal to different string objects to save memory.
 - It is also an important factor in the HashMap algorithm since strings are used as keys in the HashMap and since they are immutable, when a speciic key is called, it always returns the corresponding value with out errors if the key actually exists in the Map.

## Importance in Test Automation
### Example 1: Shared Configuration
*How does immutability protect shared resources like environment URLs or database credentials?*
If configuration data (like a base URL `https://test.example.com`) is stored in an immutable String, it can be safely shared across the entire test suite. No test can accidentally modify it (e.g., by appending a path), preventing bugs where one test inadvertently breaks the configuration for all subsequent tests. The original value remains constant and predictable.

### Example 2: Thread Safety in Parallel Execution
*Explain how immutability helps when running tests in parallel.*
When tests run in parallel, multiple threads might access the same data. Immutable objects are inherently thread-safe because their state cannot be changed after creation. This eliminates the risk of race conditions, where one thread modifies data while another is reading it, leading to inconsistent state. You don't need to use complex locks or synchronization, making parallel test code simpler and more reliable.
