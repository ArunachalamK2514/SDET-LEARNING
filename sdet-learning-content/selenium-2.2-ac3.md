# Advanced Locator Strategies: Advanced CSS Selectors using Pseudo-classes and Attribute Selectors

## Overview
CSS selectors are a powerful, fast, and often more readable alternative to XPath for locating elements in Selenium WebDriver. While simple CSS selectors use tag names, IDs, or class names, advanced CSS selectors leverage pseudo-classes and attribute selectors to pinpoint elements with greater precision, especially in complex or dynamic web pages. Mastering these advanced techniques is crucial for writing efficient, robust, and maintainable locators in your test automation framework.

## Detailed Explanation

Advanced CSS selectors allow you to target elements based on their attributes (partial matches, specific values), their position within a parent, or their state.

### Attribute Selectors
Attribute selectors allow you to select elements based on their HTML attributes and values.

-   **`[attribute]`**: Selects elements with the specified attribute, regardless of its value.
    *   Example: `input[name]` (selects all input elements that have a `name` attribute)
-   **`[attribute="value"]`**: Selects elements where the attribute's value is an exact match.
    *   Example: `input[id="firstName"]` (selects an input element with `id="firstName"`)
-   **`[attribute~="value"]`**: Selects elements where the attribute's value contains a specified word, separated by spaces.
    *   Example: `div[class~="card"]` (selects div elements with a class attribute that contains the word "card")
-   **`[attribute|="value"]`**: Selects elements whose attribute value is exactly "value" or starts with "value-" (hyphenated).
    *   Example: `[lang|="en"]` (selects elements with `lang="en"` or `lang="en-us"`)
-   **`[attribute^="value"]`**: Selects elements whose attribute value *starts with* the specified string.
    *   Example: `input[name^="first"]` (selects input elements where the `name` attribute starts with "first")
-   **`[attribute$="value"]`**: Selects elements whose attribute value *ends with* the specified string.
    *   Example: `input[name$="Name"]` (selects input elements where the `name` attribute ends with "Name")
-   **`[attribute*="value"]`**: Selects elements whose attribute value *contains* the specified string anywhere.
    *   Example: `span[class*="product"]` (selects span elements where the `class` attribute contains "product")

### Pseudo-classes
Pseudo-classes are used to define a special state of an element.

-   **`:first-child`**: Selects the element that is the first child of its parent.
-   **`:last-child`**: Selects the element that is the last child of its parent.
-   **`:nth-child(n)`**: Selects the element that is the `n`-th child of its parent. `n` can be a number, a keyword (odd, even), or a formula (`An+B`).
    *   Example: `li:nth-child(2)` (selects the second `li` element)
-   **`:first-of-type`**: Selects the first sibling of its type.
-   **`:last-of-type`**: Selects the last sibling of its type.
-   **`:nth-of-type(n)`**: Selects the `n`-th sibling of its type.
-   **`:empty`**: Selects elements that have no children (elements or text).
-   **`:not(selector)`**: Selects elements that do *not* match the specified selector.
    *   Example: `li:not(.out-of-stock)` (selects list items that do not have the class "out-of-stock")
-   **`:focus`, `:hover`, `:active`, `:visited`**: Select elements based on their interactive state. (Less common in automation, but useful for verifying styles).
-   **`:enabled`, `:disabled`**: Select enabled or disabled input elements.
-   **`:checked`**: Selects checked radio buttons or checkboxes.

### Combinators (Review)
-   **` ` (Space)**: Descendant selector (selects all descendants).
    *   Example: `div span` (selects all `span` elements inside any `div`)
-   **`>`**: Child selector (selects direct children).
    *   Example: `ul > li` (selects all `li` elements that are direct children of `ul`)
-   **`+`**: Adjacent sibling selector (selects the element immediately following another element).
    *   Example: `h2 + p` (selects the `p` element immediately following an `h2`)
-   **`~`**: General sibling selector (selects all siblings that follow another element).
    *   Example: `p ~ span` (selects all `span` elements that are siblings of a `p` element, coming after it)

## Code Implementation

The following Java code demonstrates the use of 10 advanced CSS selectors, including pseudo-classes and attribute selectors. These selectors target elements on the `xpath_axes_test_page.html` file created in the previous step.

**`xpath_axes_test_page.html` (Use the same file from `selenium-2.2-ac2` content):**
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>XPath Axes Test Page</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; line-height: 1.6; }
        .container { max-width: 900px; margin: 20px auto; padding: 20px; border: 1px solid #ccc; border-radius: 8px; background-color: #f9f9f9; }
        h1, h2, h3 { color: #333; }
        .section { margin-bottom: 25px; padding: 15px; border: 1px solid #ddd; border-radius: 5px; background-color: #fff; }
        .item-list { list-style: none; padding: 0; }
        .item-list li { margin-bottom: 10px; padding: 10px; border: 1px solid #eee; background-color: #fafafa; border-radius: 3px; }
        .card { border: 1px solid #cce; padding: 15px; margin-top: 15px; background-color: #eef; border-radius: 5px; }
        .card-header { font-weight: bold; margin-bottom: 10px; color: #55a; }
        .card-body { font-size: 0.9em; color: #66b; }
        .user-info { display: flex; margin-bottom: 10px; align-items: center; }
        .user-info .avatar { width: 40px; height: 40px; background-color: #aaa; border-radius: 50%; margin-right: 10px; }
        .user-info .name { font-weight: bold; color: #007bff; }
        .user-info .role { font-size: 0.8em; color: #6c757d; margin-left: 5px; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: bold; }
        .form-group input[type="text"], .form-group input[type="email"] { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; }
        .btn { padding: 10px 15px; background-color: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 1em; }
        .btn:hover { background-color: #218838; }
        footer { text-align: center; margin-top: 30px; font-size: 0.8em; color: #888; }
    </style>
</head>
<body>
    <div class="container">
        <h1 id="main-title">Demonstrating XPath Axes</h1>
        <p>This page provides various HTML structures to practice complex XPath expressions using axes.</p>

        <div class="section" id="products-section">
            <h2 class="section-title">Product Listings</h2>
            <div class="product-category" id="electronics">
                <h3>Electronics</h3>
                <ul class="item-list">
                    <li id="prod-101">
                        <span class="product-name">Laptop Pro</span>
                        <span class="price">$1200</span>
                        <span class="stock">In Stock</span>
                    </li>
                    <li id="prod-102">
                        <span class="product-name">Gaming Mouse</span>
                        <span class="price">$75</span>
                        <span class="stock out-of-stock">Out of Stock</span>
                    </li>
                    <li id="prod-103">
                        <span class="product-name">External SSD</span>
                        <span class="price">$150</span>
                        <span class="stock">In Stock</span>
                    </li>
                </ul>
            </div>
            <div class="product-category" id="books">
                <h3>Books</h3>
                <ul class="item-list">
                    <li id="prod-201">
                        <span class="product-name">Selenium Mastery</span>
                        <span class="price">$45</span>
                        <span class="stock">In Stock</span>
                    </li>
                    <li id="prod-202">
                        <span class="product-name">Java for SDETs</span>
                        <span class="price">$55</span>
                        <span class="stock">In Stock</span>
                    </li>
                </ul>
            </div>
        </div>

        <div class="section" id="user-reviews-section">
            <h2 class="section-title">User Reviews</h2>
            <div class="card review-card" data-review-id="R1">
                <div class="user-info">
                    <div class="avatar"></div>
                    <span class="name">Alice Smith</span>
                    <span class="role">(Customer)</span>
                </div>
                <div class="card-header">Great Product!</div>
                <div class="card-body">"This laptop is amazing. Fast delivery and excellent performance."</div>
                <span class="rating">5 Stars</span>
                <span class="date">2023-01-15</span>
            </div>
            <div class="card review-card" data-review-id="R2">
                <div class="user-info">
                    <div class="avatar"></div>
                    <span class="name">Bob Johnson</span>
                    <span class="role">(Verified Buyer)</span>
                </div>
                <div class="card-header">Good Value</div>
                <div class="card-body">"Mouse works well for gaming. Battery life is decent."</div>
                <span class="rating">4 Stars</span>
                <span class="date">2023-02-20</span>
            </div>
            <div class="card review-card" data-review-id="R3">
                <div class="user-info">
                    <div class="avatar"></div>
                    <span class="name">Charlie Brown</span>
                    <span class="role">(Admin)</span>
                </div>
                <div class="card-header">Excellent Service</div>
                <div class="card-body">"Resolved my query quickly. Highly recommend this store."</div>
                <span class="rating">5 Stars</span>
                <span class="date">2023-03-01</span>
            </div>
        </div>

        <div class="section" id="contact-form-section">
            <h2 class="section-title">Contact Us</h2>
            <form id="contact-form">
                <div class="form-group">
                    <label for="firstName">First Name:</label>
                    <input type="text" id="firstName" name="firstName">
                </div>
                <div class="form-group">
                    <label for="lastName">Last Name:</label>
                    <input type="text" id="lastName" name="lastName">
                </div>
                <div class="form-group">
                    <label for="email">Email:</label>
                    <input type="email" id="email" name="email">
                </div>
                <div class="form-group">
                    <label for="message">Message:</label>
                    <textarea id="message" name="message" rows="5"></textarea>
                </div>
                <button type="submit" class="btn submit-btn">Send Message</button>
            </form>
        </div>

        <footer>&copy; 2023 XPath Learning Site</footer>
    </div>
</body>
</html>
```

**`AdvancedCssSelectors.java`:**
```java
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import java.nio.file.Paths;
import java.util.List;
import java.util.concurrent.TimeUnit;

public class AdvancedCssSelectors {

    public static void main(String[] args) throws InterruptedException {
        // Path to the HTML file for testing
        String htmlFilePath = Paths.get("xpath_axes_test_page.html").toAbsolutePath().toString();

        WebDriver driver = setupWebDriver();
        try {
            driver.get("file:///" + htmlFilePath);
            driver.manage().window().maximize();
            Thread.sleep(2000); // Give some time for the page to load visually

            System.out.println("Demonstrating Advanced CSS Selectors:");

            // CSS 1: Attribute selector (exact match)
            // Find the h1 element with id="main-title"
            findElementAndPrint(driver, By.cssSelector("h1[id='main-title']"),
                    "1. Attribute Selector (Exact Match): h1 with id 'main-title'", true);

            // CSS 2: Attribute selector (contains substring) - *=
            // Find a span whose class contains 'product' (e.g., product-name)
            List<WebElement> productSpans = driver.findElements(By.cssSelector("span[class*='product']"));
            printElements(productSpans, "2. Attribute Selector (Contains Substring): Spans with class containing 'product'");

            // CSS 3: Attribute selector (starts with) - ^=
            // Find input elements whose name starts with 'first' (e.g., firstName)
            findElementAndPrint(driver, By.cssSelector("input[name^='first']"),
                    "3. Attribute Selector (Starts With): Input with name starting with 'first'", true);

            // CSS 4: Attribute selector (ends with) - $=
            // Find input elements whose name ends with 'Name' (e.g., firstName, lastName)
            List<WebElement> nameInputs = driver.findElements(By.cssSelector("input[name$='Name']"));
            printElements(nameInputs, "4. Attribute Selector (Ends With): Inputs with name ending with 'Name'");

            // CSS 5: Direct child selector (>)
            // Find direct li children of the ul with class 'item-list' inside the 'books' category
            List<WebElement> bookItems = driver.findElements(By.cssSelector("#books > .item-list > li"));
            printElements(bookItems, "5. Direct Child Selector: li elements in 'Books' item list");

            // CSS 6: Adjacent sibling selector (+)
            // Find the div that immediately follows the div with class 'user-info' within any review card
            findElementAndPrint(driver, By.cssSelector(".review-card .user-info + .card-header"),
                    "6. Adjacent Sibling Selector: card-header immediately after user-info", true);
            
            // CSS 7: General sibling selector (~)
            // Find all span elements that are siblings of an element with class 'product-name'
            List<WebElement> generalSiblings = driver.findElements(By.cssSelector(".product-name ~ span"));
            printElements(generalSiblings, "7. General Sibling Selector: Spans following product-name (any sibling)");

            // CSS 8: Pseudo-class :nth-child()
            // Find the second list item in the 'electronics' category
            findElementAndPrint(driver, By.cssSelector("#electronics .item-list li:nth-child(2)"),
                    "8. Pseudo-class :nth-child(2): Second list item in 'Electronics'", true);

            // CSS 9: Pseudo-class :first-of-type
            // Find the first span of type in the first product item
            findElementAndPrint(driver, By.cssSelector("#prod-101 span:first-of-type"),
                    "9. Pseudo-class :first-of-type: First span in 'Laptop Pro'", true);
            
            // CSS 10: Combining multiple selectors (AND logic)
            // Find an li element with id 'prod-103' AND containing a span with class 'stock'
            findElementAndPrint(driver, By.cssSelector("li#prod-103 span.stock"),
                    "10. Combined Selectors: li with id 'prod-103' and span.stock", true);
            // Another combination example (more complex)
            findElementAndPrint(driver, By.cssSelector("div.section input[type='text'][name='firstName']"),
                    "11. Combined Selectors: First Name input in a section div", true);


        } finally {
            if (driver != null) {
                driver.quit();
            }
        }
    }

    private static WebDriver setupWebDriver() {
        // Set up Chrome WebDriver
        ChromeOptions options = new ChromeOptions();
        // options.addArguments("--headless"); // Uncomment to run in headless mode
        WebDriver driver = new ChromeDriver(options);
        driver.manage().timeouts().implicitlyWait(10, TimeUnit.SECONDS); // Implicit wait
        return driver;
    }

    private static void findElementAndPrint(WebDriver driver, By by, String description, boolean isSingleElement) {
        System.out.println(description + ":");
        try {
            if (isSingleElement) {
                WebElement element = driver.findElement(by);
                System.out.println("  Found: " + element.getTagName() + " - " + element.getText().trim());
            } else {
                List<WebElement> elements = driver.findElements(by);
                printElements(elements, ""); // Pass empty description as it's already printed
            }
        } catch (Exception e) {
            System.out.println("  Not Found or Error: " + e.getMessage());
        }
    }

    private static void printElements(List<WebElement> elements, String description) {
        if (!description.isEmpty()) {
            System.out.println(description + ":");
        }
        if (elements.isEmpty()) {
            System.out.println("  No elements found.");
        } else {
            for (int i = 0; i < elements.size(); i++) {
                WebElement element = elements.get(i);
                System.out.println("  [" + (i + 1) + "] " + element.getTagName() + " - " + element.getText().trim());
            }
        }
    }
}
