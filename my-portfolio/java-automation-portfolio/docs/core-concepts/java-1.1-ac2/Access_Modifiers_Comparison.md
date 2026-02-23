# Java Access Modifiers Comparison

Use this table to document your findings after running your code examples.

| Modifier   | Same Class | Same Package | Subclass (Diff Package) | World (Diff Package) |
|------------|------------|--------------|-------------------------|----------------------|
| public     | Yes     | Yes       | Yes                  | Yes               |
| protected  | Yes     | Yes       | Yes                  | No               |
| default    | Yes     | Yes       | No                  | No               |
| private    | Yes     | No       | No                  | No               |

## Observations & Test Automation Context
*Explain how these modifiers are used in a Test Framework (e.g., hiding locators, protecting base methods).*

 - The locators, helper methods are always private in the Page object classes so they are properly encapsulated while the methods like `click()`, `login()` are public so they can be accessed from other test classes.
 - A reusable method like `waitForElementVisibility()` in a BasePage could be protected, allowing all page classes that extend it to use this common functionality
