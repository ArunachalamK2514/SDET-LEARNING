package com.sdet.portfolio.core.keywords;

/**
 * Demonstrates the 'finalize()' method and its deprecation.
 * NOTE: finalize() is deprecated since Java 9 and should not be used for resource cleanup.
 */
public class FinalizeExample {

    private String resourceName;

    public FinalizeExample(String resourceName) {
        this.resourceName = resourceName;
        System.out.println("Object created: " + resourceName);
    }

    @Override
    @SuppressWarnings("deprecation")
    protected void finalize() throws Throwable {
        try {
            // Unreliable and unpredictable timing
            System.out.println("FINALIZE: Garbage Collector is reclaiming " + resourceName);
        } finally {
            super.finalize();
        }
    }

    public static void runDemo() {
        System.out.println("--- Finalize Method Demo (Deprecated) ---");
        FinalizeExample example = new FinalizeExample("TemporaryResource");
        System.out.println(example);
        
        // Making the object eligible for GC
        example = null;
        
        System.out.println("Object set to null. Suggesting Garbage Collection...");
        System.gc(); // Suggestion to the JVM, not a command.
        
        try {
            // Adding a small delay to give GC a chance to run (still not guaranteed)
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        
        System.out.println("Demo finished. Finalize might have run (check logs).");
        System.out.println("---------------------------");
    }
}
