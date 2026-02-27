package com.sdet.portfolio.core.oop;

/**
 * Polymorphism: "One interface, many forms."
 * 
 * Your Task:
 * 1. Implement Overloading: Create two 'find' methods—one that takes a String ID, 
 *    and another that takes a String ID AND a timeout integer.
 * 2. Implement Overriding: Create a 'WebDriver' interface (or simulated class) 
 *    and two subclasses 'ChromeDriver' and 'FirefoxDriver'.
 */
public class PolymorphismExample {

    // --- Part 1: Overloading (Compile-time Polymorphism) ---
    public void findElement(String locator) {
        System.out.println("Finding element with locator: " + locator);
    }

    // TODO: Implement public void findElement(String locator, int timeout)
    public void findElement(String locator, int timeout) {
        System.out.println("Finding element with locator: " + locator + " and timeout: " + timeout + " seconds");
    }
    

    // --- Part 2: Overriding (Runtime Polymorphism) ---
    public interface SimpleDriver {
        void get(String url);
    }

    // TODO: Create class ChromeDriver implements SimpleDriver
    public static class ChromeDriver implements SimpleDriver {
        @Override
        public void get(String url) {
            System.out.println("ChromeDriver navigating to: " + url);
        }
    }
    
    // TODO: Create class FirefoxDriver implements SimpleDriver
    public static class FirefoxDriver implements SimpleDriver {
        @Override
        public void get(String url) {
            System.out.println("FirefoxDriver navigating to: " + url);
        }
    }
}
