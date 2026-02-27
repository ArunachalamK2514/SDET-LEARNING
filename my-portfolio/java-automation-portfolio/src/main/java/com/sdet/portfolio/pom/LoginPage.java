package com.sdet.portfolio.pom;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

/**
 * java-1.2-ac2: Create Page Object Model classes demonstrating encapsulation principles.
 * 
 * Your Task:
 * 1. Define private By or WebElement locators for:
 *    - Username field
 *    - Password field
 *    - Login button
 * 2. Create a constructor that initializes the WebDriver.
 * 3. Create public getter/action methods that use these private locators.
 * 4. Show how this protects the page state by not exposing locators directly.
 */
public class LoginPage {
    private WebDriver driver;

    // TODO: Define private By locators here
    private By usernameField = By.id("username");
    private By passwordField = By.id("password");
    private By loginButton = By.id("login-button");

    public LoginPage(WebDriver driver) {
        this.driver = driver;
    }

    // TODO: Implement public methods for:
    // - enterUsername(String username)
    public void enterUsername(String username) {
        driver.findElement(usernameField).sendKeys(username);
    }

    // - enterPassword(String password)
    public void enterPassword(String password) {
        driver.findElement(passwordField).sendKeys(password);
    }

    // - clickLogin()
    public void clickLogin() {
        driver.findElement(loginButton).click();
    }
}
