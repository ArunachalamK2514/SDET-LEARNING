package com.sdet.portfolio.core.exceptions;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Properties;

/**
 * java-1.1-ac6: Write code examples for checked vs unchecked exceptions with test automation scenarios.
 * 
 * This class demonstrates the difference between:
 * 1. Checked Exceptions (Compile-time): Exceptions that the compiler requires us to handle.
 * 2. Unchecked Exceptions (Runtime): Exceptions that occur during execution (e.g., programming errors).
 */
public class ExceptionHandlingDemo {

    public static void main(String[] args) {
        System.out.println("--- Checked Exception Example: Reading Config File ---");
        readConfig("config.properties"); // This may throw a checked exception (FileNotFoundException)

        System.out.println("--- Unchecked Exception Example: Null WebDriver (Mock) ---");
        performActionOnNullDriver(); // This will throw an unchecked exception (NullPointerException)
    }

    /**
     * Checked Exception Scenario: Reading a properties file.
     * FileNotFoundException is a checked exception; Java forces us to handle it or declare it.
     * Using try-with-resources ensures the FileInputStream is closed automatically.
     */
    private static void readConfig(String filePath) {
        try (FileInputStream fis = new FileInputStream(filePath)) {
            Properties prop = new Properties();
            prop.load(fis);
            System.out.println("Config loaded successfully.");
        } catch (FileNotFoundException e) {
            System.err.println("Checked Exception Caught: Config file not found at " + filePath);
        } catch (IOException e) {
            System.err.println("Checked Exception Caught: Error reading the file.");
        }
    }

    /**
     * Unchecked Exception Scenario: Using a null object.
     * NullPointerException is a runtime (unchecked) exception. 
     * The compiler does NOT force us to use a try-catch, but the program will crash if not handled.
     */
    private static void performActionOnNullDriver() {
        // Simulating a null WebDriver object, a common SDET error
        Object mockDriver = null; 

        try {
            System.out.println("Attempting to get URL from null driver...");
            mockDriver.toString(); // Throws NullPointerException
        } catch (NullPointerException e) {
            System.err.println("Unchecked Exception Caught: WebDriver was null before use!");
        }
    }
}
