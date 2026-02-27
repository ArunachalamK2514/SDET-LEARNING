package com.sdet.portfolio.core.keywords;

/**
 * Demonstrates the use of the 'finally' block in Java.
 * 'finally' ensures code execution regardless of whether an exception is thrown.
 */
public class FinallyExample {

    /**
     * Simulates a test execution scenario where resources must be cleaned up.
     */
    public void executeTestSimulation(boolean triggerException) {
        System.out.println("--- Finally Block Demo ---");
        System.out.println("Starting test simulation. triggerException=" + triggerException);
        
        try {
            System.out.println("TRY: Initializing 'WebDriver'...");
            System.out.println("TRY: Performing test actions...");
            
            if (triggerException) {
                System.out.println("TRY: Throwing a simulated exception!");
                throw new RuntimeException("Test Failed!");
            }
            
            System.out.println("TRY: Test actions completed successfully.");
            
        } catch (RuntimeException e) {
            System.out.println("CATCH: Caught exception: " + e.getMessage());
        } finally {
            // This block ALWAYS runs, which is perfect for driver.quit()
            System.out.println("FINALLY: Cleaning up resources (e.g., driver.quit()).");
            System.out.println("FINALLY: Simulation complete.");
        }
        System.out.println("---------------------------");
    }

    /**
     * Demonstrates that 'finally' runs even if there is a 'return' statement.
     */
    public String demonstrateFinallyWithReturn() {
        try {
            System.out.println("TRY (with return): Executing logic.");
            return "Value from TRY";
        } finally {
            System.out.println("FINALLY (after return): I still execute!");
        }
    }
}
