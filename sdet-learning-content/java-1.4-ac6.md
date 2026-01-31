# Java-1.4-ac6: Demonstrate thread safety using synchronized blocks and methods

## Overview

In test automation, especially when running tests in parallel, multiple threads often try to access shared resources simultaneously. This can lead to data corruption, inconsistent state, and flaky tests. A classic example is a shared counter for test data or a utility that writes to a common log file.

Thread safety ensures that when multiple threads access a shared resource, the resource's state remains consistent and predictable. The `synchronized` keyword in Java is a fundamental mechanism for achieving thread safety by ensuring that only one thread can execute a block of code or a method at any given time.

## Detailed Explanation

The `synchronized` keyword in Java can be applied in two main ways:

1.  **Synchronized Methods**: When a method is declared as `synchronized`, the thread executing it acquires an intrinsic lock (also called a monitor lock) on the object instance. No other thread can execute *any* synchronized method on the *same object instance* until the lock is released. The lock is automatically released when the method completes, either normally or through an exception.

2.  **Synchronized Blocks**: For more granular control, you can use a synchronized block. It takes an object as a parameter, and the thread acquires the lock on that specific object. This is more efficient than locking an entire method if only a small part of the method needs to be thread-safe.

The choice between a synchronized method and a block depends on the scope of protection needed. Locking the entire method is simpler but can hurt performance if the critical section is small. Synchronized blocks offer finer-grained locking, improving concurrency.

### How it Relates to Test Automation

-   **Shared Test Utilities**: If you have a utility class (e.g., `ReportManager`, `TestDataManager`) that is shared across parallel test threads, methods that modify its state (e.g., writing to a report, incrementing a counter) must be synchronized.
-   **Resource Management**: When managing a pool of shared resources, like browser sessions or database connections that are not isolated per thread, synchronization is crucial to prevent one test from interfering with another's resource.
-   **Custom Logging**: If you have a custom logging utility that writes to a single file, the write method must be synchronized to prevent log messages from different threads from getting jumbled.

## Code Implementation

Let's demonstrate a common scenario in test automation: a shared counter that assigns a unique ID to each test run. Without synchronization, parallel tests could get the same ID, leading to conflicts.

### 1. The Problem: A Non-Thread-Safe Counter

Here's a simple counter that is **not** thread-safe. When multiple threads call `getNextId()`, they can read the same value of `counter` before it's incremented, resulting in duplicate IDs.

```java
// UnsafeCounter.java
// This class is NOT thread-safe.
public class UnsafeCounter {
    private int counter = 0;

    public int getNextId() {
        // Simulate some processing time, increasing the chance of a race condition
        try {
            Thread.sleep(10);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        return counter++; // This operation is not atomic!
    }

    public int getCounter() {
        return counter;
    }
}
```

### 2. The Solution: Synchronized Method

By adding the `synchronized` keyword to the `getNextId` method, we ensure that only one thread can execute it at a time for a given `SafeCounter` instance.

```java
// SafeCounter.java
// This class is thread-safe using a synchronized method.
public class SafeCounter {
    private int counter = 0;

    // Only one thread can execute this method at a time on the same instance
    public synchronized int getNextId() {
        // Simulate some processing time
        try {
            Thread.sleep(10);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        return counter++;
    }

    public int getCounter() {
        return counter;
    }
}
```

### 3. The Solution: Synchronized Block

If the method had other non-critical operations, we could use a synchronized block for better performance. Here, we lock on the current object instance (`this`).

```java
// SafeCounterWithBlock.java
// This class is thread-safe using a synchronized block.
public class SafeCounterWithBlock {
    private int counter = 0;
    private final Object lock = new Object(); // A dedicated lock object

    public int getNextId() {
        // Other non-critical operations can happen here, outside the lock.
        System.out.println("Thread " + Thread.currentThread().getId() + " is preparing to get an ID.");

        int nextId;
        // The synchronized block ensures atomic access only to the critical section
        synchronized (lock) {
            // Simulate some processing time inside the critical section
            try {
                Thread.sleep(10);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            nextId = counter++;
        }
        
        // More non-critical operations can happen here.
        return nextId;
    }

    public int getCounter() {
        return counter;
    }
}
```

### Demonstration with Parallel Execution

This example uses `ExecutorService` to simulate 100 tests running in parallel, each trying to get a unique ID.

```java
// ThreadSafetyDemo.java
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

public class ThreadSafetyDemo {

    public static void main(String[] args) throws InterruptedException {
        int numberOfTasks = 100;

        // --- Unsafe Counter Demo ---
        UnsafeCounter unsafeCounter = new UnsafeCounter();
        Set<Integer> unsafeIds = Collections.synchronizedSet(new HashSet<>());
        ExecutorService unsafeExecutor = Executors.newFixedThreadPool(10);

        for (int i = 0; i < numberOfTasks; i++) {
            unsafeExecutor.submit(() -> {
                int id = unsafeCounter.getNextId();
                unsafeIds.add(id);
            });
        }
        
        shutdownAndAwaitTermination(unsafeExecutor);
        System.out.println("--- Unsafe Counter Results ---");
        System.out.println("Final Counter Value: " + unsafeCounter.getCounter());
        System.out.println("Number of Unique IDs Generated: " + unsafeIds.size());
        if (unsafeIds.size() < numberOfTasks) {
            System.out.println("Duplicate IDs were generated! Race condition occurred.");
        }
        System.out.println();


        // --- Safe Counter Demo ---
        SafeCounter safeCounter = new SafeCounter();
        Set<Integer> safeIds = Collections.synchronizedSet(new HashSet<>());
        ExecutorService safeExecutor = Executors.newFixedThreadPool(10);

        for (int i = 0; i < numberOfTasks; i++) {
            safeExecutor.submit(() -> {
                int id = safeCounter.getNextId();
                safeIds.add(id);
            });
        }

        shutdownAndAwaitTermination(safeExecutor);
        System.out.println("--- Safe Counter (Synchronized Method) Results ---");
        System.out.println("Final Counter Value: " + safeCounter.getCounter());
        System.out.println("Number of Unique IDs Generated: " + safeIds.size());
        if (safeIds.size() == numberOfTasks) {
            System.out.println("No duplicate IDs. Thread safety was successful.");
        }
    }

    // Helper method to shut down ExecutorService
    private static void shutdownAndAwaitTermination(ExecutorService pool) {
        pool.shutdown(); // Disable new tasks from being submitted
        try {
            // Wait a while for existing tasks to terminate
            if (!pool.awaitTermination(60, TimeUnit.SECONDS)) {
                pool.shutdownNow(); // Cancel currently executing tasks
                if (!pool.awaitTermination(60, TimeUnit.SECONDS))
                    System.err.println("Pool did not terminate");
            }
        } catch (InterruptedException ie) {
            pool.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }
}
```

## Best Practices

-   **Minimize Scope of Synchronization**: Only synchronize the critical sections of your code. Over-synchronization can lead to performance bottlenecks and deadlocks.
-   **Use a Private Final Lock Object**: When using synchronized blocks, it's a best practice to lock on a `private final Object lock = new Object();` instead of `this` or the class object. This prevents external classes from acquiring the lock and causing unexpected behavior.
-   **Prefer `java.util.concurrent`**: For complex scenarios, prefer high-level concurrency utilities like `AtomicInteger`, `ReentrantLock`, and `ConcurrentHashMap` over low-level `synchronized` blocks. They offer better performance and more advanced features.
-   **Avoid Locking on Public Objects**: Locking on public objects or `this` can lead to deadlocks if other parts of the application (or third-party libraries) also try to lock on the same object.
-   **Document Thread Safety**: Clearly document which classes and methods in your framework are thread-safe and which are not.

## Common Pitfalls

-   **Deadlock**: This occurs when two or more threads are blocked forever, waiting for each other. For example, Thread A holds Lock 1 and waits for Lock 2, while Thread B holds Lock 2 and waits for Lock 1.
-   **Performance Impact**: `synchronized` adds overhead. Unnecessary synchronization can significantly slow down your test suite, negating the benefits of parallel execution.
-   **Locking on Null Objects**: Attempting to synchronize on a `null` reference will throw a `NullPointerException`.
-   **Forgetting to Synchronize All Access**: If a shared variable is written in a synchronized block but read outside of one, the reading thread may see a stale value. All access (read and write) to the shared resource must be synchronized.

## Interview Questions & Answers

1.  **Q: What is thread safety, and why is it important in a test automation framework?**
    **A:** Thread safety is the property of a piece of code that allows it to be executed by multiple threads concurrently without causing race conditions, data corruption, or inconsistent results. It is critical in test automation for enabling reliable parallel test execution. Without it, tests running in parallel could interfere with each other by accessing shared resources (like a WebDriver instance, a reporting utility, or test data files) simultaneously, leading to flaky tests, false negatives, and incorrect reporting.

2.  **Q: Can you explain the difference between a synchronized method and a synchronized block? When would you use one over the other?**
    **A:** A **synchronized method** locks the entire object (`this`) for the duration of the method call. It's simple to implement but can be inefficient if the method is long and only a small part of it accesses the shared resource. A **synchronized block** provides more granular control, allowing you to lock on a specific object for only the critical section of code. You should use a synchronized block when you want to minimize the scope of the lock to improve concurrency or when you need to lock on an object other than `this`.

3.  **Q: What are some alternatives to the `synchronized` keyword in Java?**
    **A:** The `java.util.concurrent.locks` package provides more advanced locking mechanisms, such as `ReentrantLock`, which offers features like timed waits, interruptible lock acquisition, and fairness policies. The `java.util.concurrent.atomic` package provides classes like `AtomicInteger` and `AtomicLong` that perform atomic operations without needing explicit locks, offering better performance under high contention. For collections, the `java.util.concurrent` package provides thread-safe alternatives like `ConcurrentHashMap` and `CopyOnWriteArrayList`.

## Hands-on Exercise

1.  **Objective**: Create a thread-safe utility that logs test events to a single file.
2.  **Task**:
    -   Create a `FileLogger` class with a `log(String message)` method that appends a timestamped message to a file named `test_run.log`.
    -   Make this class a Singleton to ensure all threads use the same instance.
    -   The `log` method must be thread-safe. First, implement it *without* synchronization to observe the problem.
    -   Use an `ExecutorService` with a fixed thread pool to simulate 10 test threads, each calling the `log` method 20 times in a loop. You will likely see jumbled or incomplete log messages.
    -   Now, modify the `log` method using a `synchronized` block to ensure that file-writing is atomic.
    -   Run the test again and verify that the `test_run.log` file contains complete, uncorrupted lines.

## Additional Resources

-   [Oracle Java Tutorials - Synchronized Methods](https://docs.oracle.com/javase/tutorial/essential/concurrency/syncmeth.html)
-   [Baeldung - The `synchronized` Keyword in Java](https://www.baeldung.com/java-synchronized)
-   [Jenkov.com - Java Concurrency: `synchronized`](http://tutorials.jenkov.com/java-concurrency/synchronized.html)
