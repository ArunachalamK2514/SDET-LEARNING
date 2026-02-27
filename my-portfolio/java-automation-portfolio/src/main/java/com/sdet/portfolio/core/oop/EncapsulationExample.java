package com.sdet.portfolio.core.oop;

/**
 * Encapsulation: Bundling data and methods, and restricting direct access.
 * 
 * Your Task:
 * 1. Make the fields 'username' and 'password' private.
 * 2. Create public getters and setters.
 * 3. In the 'setPassword' method, add a check to ensure the password is at
 * least 8 characters long.
 */
public class EncapsulationExample {

    // These should be private to hide them from direct access
    private String username;
    private String password;

    // TODO: Create a public constructor
    public EncapsulationExample(String username, String password) {
        this.username = username;
        this.password = password;
    }

    // TODO: Implement public String getUsername()
    public String getUsername() {
        return username;
    }

    // TODO: Implement public void setUsername(String username)
    public void setUsername(String username) {
        this.username = username;
    }

    // TODO: Implement public void setPassword(String password) with length
    // validation
    public void setPassword(String password) {
        if (password.length() >= 8) {
            this.password = password;
        } else {
            System.out.println("Password must be at least 8 characters long.");
        }
    }

    // TODO: Implement public String getMaskedPassword() - should return "********"
    public String getMaskedPassword() {
        return "********";
    }
}
