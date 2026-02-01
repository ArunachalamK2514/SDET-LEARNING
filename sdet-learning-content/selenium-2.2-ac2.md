# Advanced Locator Strategies: Complex XPath Expressions with Axes

## Overview
While basic XPath expressions are sufficient for many scenarios, real-world web applications often feature complex, dynamic, or deeply nested HTML structures that necessitate more sophisticated localization techniques. XPath axes provide a powerful way to navigate the HTML DOM tree relative to a currently selected node, allowing you to locate elements based on their relationships (parent, child, sibling, ancestor, descendant) rather than just their absolute path or attributes. Mastering XPath axes is a critical skill for any SDET to write robust and maintainable locators.

## Detailed Explanation

XPath axes represent the relationship between the context (current) node and other nodes in the document tree. They allow for flexible and powerful navigation, moving both upwards (ancestor), downwards (descendant), sideways (sibling), or even across the entire document.

Here are the most commonly used XPath axes and their descriptions:

1.  **`ancestor`**: Selects all ancestor elements (parent, grandparent, etc.) of the current node.
2.  **`parent`**: Selects the immediate parent of the current node.
3.  **`following-sibling`**: Selects all siblings *after* the current node. Siblings are nodes that have the same parent.
4.  **`preceding-sibling`**: Selects all siblings *before* the current node.
5.  **`descendant`**: Selects all descendant elements (children, grandchildren, etc.) of the current node.
6.  **`child`**: Selects all immediate children of the current node.
7.  **`following`**: Selects everything in the document *after* the closing tag of the current node, irrespective of parentage.
8.  **`preceding`**: Selects everything in the document *before* the opening tag of the current node, irrespective of parentage.
9.  **`ancestor-or-self`**: Selects all ancestors (parent, grandparent, etc.) and the current node itself.
10. **`descendant-or-self`**: Selects all descendants (children, grandchildren, etc.) and the current node itself.
11. **`self`**: Selects the current node itself. Often used with predicates `[]` to apply conditions to the current node.

### Syntax for using Axes:
`current_node/axis_name::node_test[predicate]`

-   `current_node`: The starting point (e.g., `//div[@id='myElement']`).
-   `axis_name`: The relationship (e.g., `parent`, `following-sibling`).
-   `node_test`: The type of node you are looking for (e.g., `*` for any element, `div`, `span`, `text()`).
-   `predicate`: Optional condition to filter the nodes selected by the axis (e.g., `[@class='active']`, `[1]` for the first one).

## Code Implementation

The following Java code demonstrates the use of 10 complex XPath expressions using various axes. These XPaths target elements on the `xpath_axes_test_page.html` file provided in the previous step.

**`xpath_axes_test_page.html` (Save this in your project root):**
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

**`ComplexXPathAxes.java`:**
```java
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import java.io.File;
import java.nio.file.Paths;
import java.util.List;
import java.util.concurrent.TimeUnit;

public class ComplexXPathAxes {

    public static void main(String[] args) throws InterruptedException {
        // Path to the HTML file for testing
        String htmlFilePath = Paths.get("xpath_axes_test_page.html").toAbsolutePath().toString();

        WebDriver driver = setupWebDriver();
        try {
            driver.get("file:///" + htmlFilePath);
            driver.manage().window().maximize();
            Thread.sleep(2000); // Give some time for the page to load visually

            System.out.println("Demonstrating XPath Axes:");

            // XPath 1: `ancestor` - Find the parent 'div' of a specific product name
            // Find the 'div' (product-category) that is an ancestor of 'Laptop Pro'
            findElementAndPrint(driver, By.xpath("//span[text()='Laptop Pro']/ancestor::div[@class='product-category']"),
                    "1. Ancestor: div of 'Laptop Pro'", true);

            // XPath 2: `parent` - Find the immediate parent 'li' of a product name
            // Find the 'li' (product item) that is the parent of 'Gaming Mouse'
            findElementAndPrint(driver, By.xpath("//span[text()='Gaming Mouse']/parent::li"),
                    "2. Parent: li of 'Gaming Mouse'", true);

            // XPath 3: `following-sibling` - Find all sibling 'span' elements after 'product-name'
            // Find all 'span' tags that come after the 'product-name' span for 'External SSD'
            List<WebElement> followingSiblings = driver.findElements(By.xpath("//span[text()='External SSD']/following-sibling::span"));
            printElements(followingSiblings, "3. Following-sibling: Spans after 'External SSD' product name");

            // XPath 4: `preceding-sibling` - Find the sibling 'span' before 'stock' status
            // Find the 'price' span that comes before the 'stock' span for 'Selenium Mastery'
            findElementAndPrint(driver, By.xpath("//span[text()='In Stock']/preceding-sibling::span[@class='price']"),
                    "4. Preceding-sibling: Price of 'In Stock' for 'Selenium Mastery'", true);

            // XPath 5: `descendant` - Find all 'span' descendants within a specific review card
            // Find all 'span' elements within the review card for 'Alice Smith'
            List<WebElement> descendants = driver.findElements(By.xpath("//div[@class='card-header' and text()='Great Product!']/ancestor::div[@class='review-card']//descendant::span"));
            printElements(descendants, "5. Descendant: Spans within 'Alice Smith' review card");

            // XPath 6: `child` - Find direct 'li' children of a product list 'ul'
            // Find all 'li' elements directly under the 'item-list' ul in 'Books' category
            List<WebElement> children = driver.findElements(By.xpath("//div[@id='books']/ul[@class='item-list']/child::li"));
            printElements(children, "6. Child: li elements in 'Books' item list");

            // XPath 7: `following` - Find all elements that come after a specific element in the HTML
            // Find the first 'h2' that appears after the 'electronics' div
            findElementAndPrint(driver, By.xpath("//div[@id='electronics']/following::h2[1]"),
                    "7. Following: First h2 after 'electronics' div", true);

            // XPath 8: `preceding` - Find all elements that come before a specific element
            // Find the 'h1' that appears before the 'user-reviews-section' div
            findElementAndPrint(driver, By.xpath("//div[@id='user-reviews-section']/preceding::h1[1]"),
                    "8. Preceding: h1 before 'user-reviews-section'", true);
            
            // XPath 9: `ancestor-or-self` - Find the card or its ancestor that has data-review-id='R2'
            // Find the 'div' (review-card) itself or its ancestor that matches data-review-id='R2' (mostly used with other conditions)
            findElementAndPrint(driver, By.xpath("//div[@data-review-id='R2']/descendant::span[@class='name']/ancestor-or-self::div[@data-review-id='R2']"),
                    "9. Ancestor-or-self: Review card R2 via its name span", true);

            // XPath 10: `self` - Check an attribute of the current node (used with predicates)
            // Find the 'span' element that has the text 'In Stock' and also has the class 'stock'
            findElementAndPrint(driver, By.xpath("//span[text()='In Stock']/self::span[@class='stock']"),
                    "10. Self: 'In Stock' span with class 'stock'", true);

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
