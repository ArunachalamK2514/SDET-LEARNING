# Inter-Thread Coordination with wait(), notify(), and notifyAll()

## Overview
In multithreaded programming, it's crucial for threads to communicate and coordinate their actions. Simply using `synchronized` blocks prevents race conditions but doesn't allow threads to signal each other about their state. For instance, one thread (a "consumer") might need to wait for another thread (a "producer") to create data before it can proceed. Java provides a powerful mechanism for this inter-thread communication directly within the `Object` class: the `wait()`, `notify()`, and `notifyAll()` methods.

These methods are fundamental for building complex, efficient, and responsive multithreaded applications, including advanced test automation frameworks where parallel execution requires careful management of shared resources.

## Detailed Explanation
The `wait()`, `notify()`, and `notifyAll()` methods can only be called from within a `synchronized` block and on the object that is being used as the lock.

-   **`wait()`**: When a thread calls `wait()` on an object, it immediately releases the lock on that object and enters a "waiting" state. It remains in this state until another thread calls `notify()` or `notifyAll()` on the *same object*. Once awakened, the thread must re-acquire the lock before it can exit the `wait()` method and proceed. Because the lock might have been acquired and released by other threads in the meantime, the condition that the thread was waiting for might no longer be true. Therefore, `wait()` should always be called inside a loop that re-checks the condition (a "spurious wakeup").

-   **`notify()`**: This method wakes up a *single* thread that is currently waiting on the object's monitor. If multiple threads are waiting, the choice of which thread to wake up is arbitrary and depends on the JVM's implementation. The awakened thread will not run immediately but will be moved to the "runnable" state. It must still wait for the notifying thread to release the lock and then successfully re-acquire the lock itself.

-   **`notifyAll()`**: This method is similar to `notify()`, but it it wakes up *all* threads that are waiting on the object's monitor. Each of these threads will then compete to acquire the lock once the notifying thread releases it. `notifyAll()` is generally safer to use than `notify()` because it prevents scenarios where the "wrong" thread is notified and the condition it was waiting for is never met, leading to deadlock.

### The Producer-Consumer Problem
The classic scenario for demonstrating `wait()` and `notify()` is the Producer-Consumer problem.

1.  **Shared Resource**: There is a shared, fixed-size buffer or queue.
2.  **Producer**: A thread that adds items to the buffer. It must wait if the buffer is full.
3.  **Consumer**: A thread that removes items from the buffer. It must wait if the buffer is empty.

The `wait()`/`notify()` mechanism allows the Producer to notify the Consumer when a new item is available, and the Consumer to notify the Producer when space becomes available in the buffer.

## Code Implementation
Here is a complete, runnable example implementing the Producer-Consumer problem. The `MessageBroker` acts as the shared buffer.

```java
import java.util.LinkedList;
import java.util.Queue;

/**
 * This class represents the shared resource (a message queue) between Producer and Consumer.
 */
class MessageBroker {
    private final Queue<String> queue = new LinkedList<>();
    private final int capacity;
    private final String name;

    public MessageBroker(int capacity, String name) {
        this.capacity = capacity;
        this.name = name;
    }

    /**
     * Consumes a message from the queue.
     * It waits if the queue is empty.
     *
     * @return The message from the queue.
     * @throws InterruptedException if the thread is interrupted while waiting.
     */
    public synchronized String consume() throws InterruptedException {
        // Wait while the queue is empty (spurious wakeup loop)
        while (queue.isEmpty()) {
            System.out.println(Thread.currentThread().getName() + " on " + name + ": Queue is empty, waiting...");
            wait(); // Releases the lock and waits
        }

        String message = queue.poll();
        System.out.println(Thread.currentThread().getName() + " on " + name + ": Consumed message - '" + message + "'");

        // Notify a producer thread that there is now space in the queue
        notifyAll();
        return message;
    }

    /**
     * Produces a message and adds it to the queue.
     * It waits if the queue is full.
     *
     * @param message The message to be added.
     * @throws InterruptedException if the thread is interrupted while waiting.
     */
    public synchronized void produce(String message) throws InterruptedException {
        // Wait while the queue is full (spurious wakeup loop)
        while (queue.size() == capacity) {
            System.out.println(Thread.currentThread().getName() + " on " + name + ": Queue is full, waiting...");
            wait(); // Releases the lock and waits
        }

        queue.add(message);
        System.out.println(Thread.currentThread().getName() + " on " + name + ": Produced message - '" + message + "'");

        // Notify a consumer thread that a new message is available
        notifyAll();
    }
}

/**
 * The Producer thread.
 */
class Producer implements Runnable {
    private final MessageBroker broker;

    public Producer(MessageBroker broker) {
        this.broker = broker;
    }

    @Override
    public void run() {
        try {
            for (int i = 0; i < 5; i++) {
                broker.produce("Message " + i);
                Thread.sleep(100); // Simulate time taken to produce
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}

/**
 * The Consumer thread.
 */
class Consumer implements Runnable {
    private final MessageBroker broker;

    public Consumer(MessageBroker broker) {
        this.broker = broker;
    }

    @Override
    public void run() {
        try {
            for (int i = 0; i < 5; i++) {
                broker.consume();
                Thread.sleep(200); // Simulate time taken to consume
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}

/**
 * Main class to demonstrate the Producer-Consumer pattern.
 */
public class CoordinationDemo {
    public static void main(String[] args) {
        // A shared message broker with a capacity of 2
        MessageBroker broker = new MessageBroker(2, "TestBroker");

        // In a test framework, this could be a shared pool of WebDriver instances or test data sets.
        Thread producerThread = new Thread(new Producer(broker), "Producer");
        Thread consumerThread1 = new Thread(new Consumer(broker), "Consumer-1");
        Thread consumerThread2 = new Thread(new Consumer(broker), "Consumer-2");


        System.out.println("Starting Producer and Consumer threads...");
        producerThread.start();
        consumerThread1.start();
        // consumerThread2.start(); // Uncomment to see multiple consumers

        try {
            producerThread.join();
            consumerThread1.join();
            // consumerThread2.join();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        System.out.println("All threads finished.");
    }
}
```

## Best Practices
-   **Always Use `wait()` in a Loop**: Never assume a thread was awakened because the condition it was waiting for is now true. It could be a "spurious wakeup," or another thread could have changed the state in the interim. Always re-check the condition in a `while` loop.
-   **Prefer `notifyAll()` over `notify()`**: Using `notifyAll()` is safer. It ensures that all waiting threads get a chance to check the condition again. This prevents deadlocks that can occur if `notify()` wakes up a thread that isn't the one that can make progress.
-   **Call from `synchronized` Context**: Ensure `wait()`, `notify()`, and `notifyAll()` are always called from within a `synchronized` method or block on the same object instance. Failure to do so will result in an `IllegalMonitorStateException`.
-   **Minimize Time in `synchronized` Blocks**: Hold locks for the shortest possible duration to improve concurrency. Perform long-running operations outside of the `synchronized` block if possible.

## Common Pitfalls
-   **Forgetting the `while` Loop**: Calling `wait()` inside an `if` statement is a common mistake. If the thread wakes up spuriously without the condition being met, it will proceed incorrectly.
-   **Using `notify()` in a Multi-Consumer Scenario**: If you have multiple consumers and a producer calls `notify()`, it might wake up another producer (if producers also wait) instead of a consumer, leading to a deadlock where all consumers are waiting and no one is producing. `notifyAll()` avoids this.
-   **Calling `wait()` on the Wrong Object**: The `wait()` and `notify()` methods must be called on the same object that is used for the lock. A common error is to synchronize on `this` but call `wait()` on a different object.
-   **Deadlock**: Incorrect use of `wait()` and `notify()` is a classic source of deadlocks. For example, a consumer might be waiting for a notification that never comes because the producer is also stuck waiting for a different condition.

## Interview Questions & Answers
1.  **Q: Why must `wait()` and `notify()` be called from a synchronized block?**
    **A:** These methods are used to manage an object's monitor (lock). To call `wait()`, a thread must first own the lock to ensure there is no race condition between checking the condition and entering the waiting state. If it were not synchronized, another thread could change the condition and send a notification *before* the first thread goes to sleep, causing the notification to be missed entirely (a "lost wakeup"). Similarly, `notify()` must be called by a thread that owns the lock to ensure that the state change is safely published to other threads before the notification is sent.

2.  **Q: What is a "spurious wakeup" and how do you handle it?**
    **A:** A spurious wakeup is when a waiting thread is awakened for no apparent reason, without `notify()` or `notifyAll()` having been called. It's a rare but possible behavior allowed by the Java Memory Model. To handle it, `wait()` must always be called inside a `while` loop that re-evaluates the condition the thread was waiting for. This ensures that even if the thread wakes up spuriously, it will check the condition again and go back to waiting if it's not met.

3.  **Q: When would you choose `notify()` over `notifyAll()`?**
    **A:** You should only use `notify()` if you can guarantee that any single thread that wakes up can make progress and that it's acceptable for other waiting threads to remain waiting. This is typical in highly optimized scenarios with only one producer and one consumer, where you know a producer notification is always for a consumer and vice-versa. In all other cases, especially with multiple producers or consumers, `notifyAll()` is the safer and recommended choice to avoid deadlocks.

## Hands-on Exercise
1.  **Modify the `CoordinationDemo`**:
    -   Add another `Producer` thread.
    -   Uncomment the second `Consumer` thread (`consumerThread2`).
    -   Increase the number of messages each producer creates to 10.
    -   Run the program and observe the output. Note how the threads coordinate and how the queue size stays within the capacity of 2.
2.  **Introduce a Bug**:
    -   Change `while (queue.isEmpty())` to `if (queue.isEmpty())` in the `consume` method.
    -   Change `notifyAll()` to `notify()` in both `produce` and `consume`.
    -   Run the code several times. Can you get it to hang (deadlock)? Analyze the logs to understand why it happened. This exercise will demonstrate the importance of the `while` loop and `notifyAll()`.

## Additional Resources
-   [Oracle Java Docs: Object class](https://docs.oracle.com/javase/8/docs/api/java/lang/Object.html#wait--)
-   [Baeldung: A Guide to wait(), notify(), and notifyAll() in Java](https://www.baeldung.com/java-wait-notify)
-   [GeeksforGeeks: Inter-thread Communication in Java](https://www.geeksforgeeks.org/inter-thread-communication-java/)
-   [Jenkov.com: Java wait(), notify() and notifyAll()](http://tutorials.jenkov.com/java-concurrency/wait-notify-notifyall.html)
