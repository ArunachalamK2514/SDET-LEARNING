package com.sdet.portfolio.core.keywords;

/**
 * Demonstrates the use of the 'final' keyword in Java.
 * 'final' can be applied to variables, methods, and classes.
 */
public class FinalExample {

    // 1. final variable: Cannot be reassigned once initialized.
    public static final String BROWSER = "Chrome";
    public static final int TIMEOUT = 30;

    public void demonstrateFinalVariable() {
        System.out.println("Final Variable BROWSER: " + BROWSER);
        // BROWSER = "Firefox"; // COMPILE ERROR: Cannot assign a value to final variable 'BROWSER'
    }

    // 2. final method: Cannot be overridden by subclasses.
    public static class BasePage {
        public final void login() {
            System.out.println("BasePage: Standardized login process. This cannot be overridden.");
        }
        
        public void navigate() {
            System.out.println("BasePage: Default navigation.");
        }
    }

    public static class LoginPage extends BasePage {
        // @Override
        // public void login() { } // COMPILE ERROR: 'login()' cannot override 'login()' in 'BasePage'; overridden method is final
        
        @Override
        public void navigate() {
            System.out.println("LoginPage: Custom navigation to login page.");
        }
    }

    // 3. final class: Cannot be inherited (subclassed).
    public final static class WebDriverUtils {
        public static void takeScreenshot() {
            System.out.println("WebDriverUtils: Taking a screenshot.");
        }
    }

    // public class MyUtils extends WebDriverUtils { } // COMPILE ERROR: Cannot inherit from final 'com.sdet.portfolio.core.keywords.FinalExample.WebDriverUtils'

    public void runDemo() {
        System.out.println("--- Final Keyword Demo ---");
        demonstrateFinalVariable();
        
        BasePage page = new LoginPage();
        page.login();
        page.navigate();
        
        WebDriverUtils.takeScreenshot();
        System.out.println("---------------------------");
    }
}
