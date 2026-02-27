package com.sdet.portfolio.core.oop;

/**
 * Abstraction: Hiding complexity and showing only essential features.
 * 
 * Your Task:
 * 1. Complete the abstract class 'BasePage'.
 * 2. Create a concrete class 'LoginPage' that extends 'BasePage'.
 * 3. Ensure 'LoginPage' implements the abstract method 'verifyPage()'.
 */
public class AbstractionExample {

    public abstract static class BasePage {
        protected String pageName;

        public BasePage(String pageName) {
            this.pageName = pageName;
        }

        // Concrete method: All pages have a way to navigate
        public void navigateTo(String url) {
            System.out.println(pageName + ": Navigating to " + url);
        }

        // Abstract method: Each page MUST implement its own verification logic
        public abstract void verifyPage();
    }

    // TODO: Create public static class LoginPage extends BasePage
    public static class LoginPage extends BasePage {
        public LoginPage (String pageName){
            super(pageName);
        }

        @Override
        public void verifyPage() {
            System.out.println(pageName + ": Verifying login page elements.");
        }
    }
    // 1. Implement the constructor
    // 2. Implement the verifyPage() method
}
