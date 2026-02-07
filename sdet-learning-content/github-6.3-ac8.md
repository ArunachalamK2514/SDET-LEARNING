# GitHub Actions: Environment Variables and Secrets

## Overview
In CI/CD pipelines, especially with GitHub Actions, managing sensitive information like API keys, database credentials, or tokens, and configuring runtime settings via environment variables, is crucial for secure and flexible automation. This feature explains how to securely configure and use both environment variables and secrets within GitHub Actions workflows. Properly utilizing these mechanisms ensures that your automation scripts can interact with external services and adapt to different environments without hardcoding sensitive data or requiring manual changes.

## Detailed Explanation

GitHub Actions provides two primary ways to pass dynamic or sensitive data into your workflow runs:
1.  **Environment Variables (`env`)**: These are general-purpose key-value pairs that can be set at the workflow, job, or step level. They are accessible to all commands executed within their scope and are suitable for non-sensitive configuration data (e.g., build flags, feature toggles, non-secret API endpoints).
2.  **Secrets (`secrets`)**: These are encrypted environment variables that you create in your repository, organization, or environment settings. Secrets are designed for sensitive information that should not be exposed in logs or source code (e.g., API keys, passwords, private tokens). GitHub Redacts secrets automatically if they appear in logs.

### Setting Environment Variables

You can set environment variables at different scopes:

*   **Workflow Level**: Available to all jobs in the workflow.
    ```yaml
    # .github/workflows/main.yml
    name: My CI Workflow
    on: push

    env:
      BUILD_VERSION: 1.0.0
      ENVIRONMENT: production

    jobs:
      build:
        runs-on: ubuntu-latest
        steps:
          - name: Print env vars
            run: |
              echo "Build Version: ${{ env.BUILD_VERSION }}"
              echo "Environment: ${{ env.ENVIRONMENT }}"
    ```

*   **Job Level**: Available to all steps within a specific job.
    ```yaml
    jobs:
      test:
        runs-on: ubuntu-latest
        env:
          TEST_SUITE: integration
          BROWSER: chromium
        steps:
          - name: Run tests with job env vars
            run: |
              echo "Running ${{ env.TEST_SUITE }} tests on ${{ env.BROWSER }}"
    ```

*   **Step Level**: Available only to that specific step.
    ```yaml
    jobs:
      deploy:
        runs-on: ubuntu-latest
        steps:
          - name: Deploy to staging
            env:
              DEPLOY_TARGET: staging
            run: |
              echo "Deploying to: ${{ env.DEPLOY_TARGET }}"
    ```

### Using Secrets

Secrets are stored in GitHub and injected into the workflow at runtime. They are accessed using the `secrets` context.

1.  **Adding Secrets**: Go to your repository settings -> `Secrets and variables` -> `Actions` -> `New repository secret`. Enter the `Name` (e.g., `API_KEY`) and `Value`.

2.  **Injecting Secrets into Workflow**:
    ```yaml
    # .github/workflows/ci.yml
    name: Secure CI

    on: push

    jobs:
      call-api:
        runs-on: ubuntu-latest
        steps:
          - name: Use API Key
            run: |
              # Avoid directly echoing secrets in logs.
              # Use them with tools that expect environment variables.
              echo "Calling API with key..."
              # Example: A script that uses the API_KEY environment variable
              # curl -H "Authorization: Bearer ${{ secrets.API_KEY }}" https://api.example.com/data
              # For demonstration, we'll print a masked version
              echo "API_KEY length: ${{ secrets.API_KEY_LENGTH }}" # This is a placeholder for demonstration
            env:
              API_KEY_LENGTH: ${{ secrets.API_KEY.length }} # Example of passing a property of the secret
    ```
    **Note**: GitHub automatically redacts secrets from logs. Even if you `echo` a secret, it will appear as `***` in the logs. However, it's a best practice to avoid directly echoing secrets.

### Verifying Access

To verify that your tests or scripts can access these variables and secrets, you can typically print them (non-sensitive ones) or check for their presence in your test runner's environment.

## Code Implementation

Let's create a sample GitHub Actions workflow that uses both environment variables and a secret, and a simple shell script to verify their access.

**1. Create a secret**: In your GitHub repository settings, add a new repository secret named `MY_SUPER_SECRET` with any value (e.g., `my-super-secure-token`).

**2. Create the workflow file**: `project/.github/workflows/verify_vars.yml`
```yaml
# .github/workflows/verify_vars.yml
name: Verify Env Vars and Secrets

on: [push, pull_request]

env:
  GLOBAL_ENV_VAR: "Hello from Global"

jobs:
  check_variables:
    runs-on: ubuntu-latest
    env:
      JOB_ENV_VAR: "Hello from Job"
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Verify Environment Variables and Secrets
        env:
          STEP_ENV_VAR: "Hello from Step"
          # Injecting the secret as an environment variable for the step
          # This makes MY_SUPER_SECRET available as an env var within this step
          MY_INJECTED_SECRET: ${{ secrets.MY_SUPER_SECRET }}
        run: |
          echo "--- Checking Environment Variables ---"
          echo "Global Env Var: $GLOBAL_ENV_VAR"
          echo "Job Env Var: $JOB_ENV_VAR"
          echo "Step Env Var: $STEP_ENV_VAR"

          echo "--- Checking Secret Access ---"
          # Directly accessing the secret from the secrets context (not recommended for simple echo)
          echo "Secret from context length: ${{ secrets.MY_SUPER_SECRET.length }}"
          # Accessing the secret injected as an environment variable (preferable)
          echo "Injected Secret (masked): $MY_INJECTED_SECRET"
          echo "Note: GitHub automatically masks secrets in logs."
          
          # Example of how a script might use it (e.g., a Python script)
          # python -c "import os; print(f'Script using secret: {os.environ.get("MY_INJECTED_SECRET")}')"

```

When this workflow runs, you will see the environment variables printed. For the secret, GitHub will automatically mask its value in the logs, appearing as `***`, confirming that it was correctly accessed but not exposed.

## Best Practices
-   **Least Privilege**: Only provide secrets to workflows and jobs that absolutely need them. Use environment-specific secrets for deployments.
-   **Don't Hardcode**: Never hardcode secrets or sensitive information directly into your workflow files or source code.
-   **Scope Appropriately**: Use workflow-level `env` for truly global configurations. Use job-level or step-level `env` for more specific configurations.
-   **Use Encrypted Secrets**: Always store sensitive data as GitHub Secrets. Do not use plain environment variables for secrets.
-   **Avoid `echo`ing Secrets**: While GitHub redacts secrets, it's a good practice to avoid explicitly printing secrets in your `run` commands to minimize accidental exposure, especially in complex scripts or when piping output.
-   **Rotate Secrets**: Regularly rotate your secrets (e.g., API keys, tokens) to minimize the impact of a potential compromise.
-   **Separate Environments**: Use GitHub Environments to manage environment-specific secrets (e.g., `staging_API_KEY`, `production_API_KEY`). This adds an extra layer of protection and approval workflows.

## Common Pitfalls
-   **Forgetting to define secrets**: Workflow fails because a secret expected by a step is not defined in the repository settings.
-   **Typos in secret names**: `secrets.API_KEY` vs `secrets.APIKEY`. Names are case-sensitive.
-   **Exposing secrets in forks**: By default, secrets are not passed to pull requests from forked repositories. This is a security feature to prevent malicious code in forks from accessing your secrets. If a workflow needs secrets, it should only run on `push` to the main repository or explicitly configure this.
-   **Using environment variables for sensitive data**: Storing API keys as `env:` variables instead of `secrets:` means they are visible in the workflow file and potentially in logs.
-   **Incorrect scope**: Setting an environment variable at the step level and expecting it to be available in a subsequent step or another job.

## Interview Questions & Answers
1.  **Q: What is the difference between `env` and `secrets` in GitHub Actions, and when would you use each?**
    **A:** `env` variables are for non-sensitive configuration data that can be visible in workflow files and logs (e.g., a build version, a non-sensitive flag). `secrets` are encrypted variables stored outside the repository, designed for sensitive data like API keys or tokens. They are automatically masked in logs and should always be used for anything confidential. You'd use `env` for general configuration and `secrets` for anything that needs to be kept confidential and secure.

2.  **Q: How do you prevent secrets from being exposed in GitHub Actions logs?**
    **A:** GitHub Actions automatically redacts (masks with `***`) any string that matches a configured secret's value if it appears in the workflow logs. This happens even if you try to `echo` the secret. However, best practice is still to avoid explicitly printing secrets and to ensure they are only used by the tools that require them (e.g., passed directly to a command or script that consumes an environment variable).

3.  **Q: You have a deployment workflow that needs different API keys for staging and production environments. How would you manage this securely in GitHub Actions?**
    **A:** I would use GitHub Environments. I would create two environments, "staging" and "production," and configure environment-specific secrets (e.g., `API_KEY`) for each. The deployment workflow would then specify which environment it's targeting (e.g., `environment: staging`), and GitHub Actions would automatically provide the correct `API_KEY` for that environment. This also allows for features like required reviewers for specific environments.

## Hands-on Exercise
1.  **Fork this repository** (or your own GitHub repository).
2.  **Add a new repository secret**: Go to `Settings > Secrets and variables > Actions > Repository secrets` and add a new secret named `MY_API_TOKEN` with a dummy value like `ghp_abcdef12345`.
3.  **Create a workflow file**: In your forked repository, create a file `.github/workflows/check_vars.yml` with the following content:
    ```yaml
    name: Check Variables Exercise

    on: [push]

    env:
      APP_VERSION: "1.2.3"

    jobs:
      build_and_test:
        runs-on: ubuntu-latest
        env:
          BUILD_TYPE: "release"
        steps:
          - name: Checkout code
            uses: actions/checkout@v4

          - name: Display variables and secret
            env:
              MY_TOKEN: ${{ secrets.MY_API_TOKEN }}
            run: |
              echo "App Version: $APP_VERSION"
              echo "Build Type: $BUILD_TYPE"
              echo "My API Token (masked): $MY_TOKEN"
              echo "Length of token: ${{ secrets.MY_API_TOKEN.length }}"

          - name: Simulate API call (using the secret)
            run: |
              echo "Simulating secure API call using MY_TOKEN..."
              # In a real scenario, a tool or script would use $MY_TOKEN here.
              # e.g., curl -H "Authorization: Bearer $MY_TOKEN" https://api.example.com/data
            env:
              MY_TOKEN: ${{ secrets.MY_API_TOKEN }}
    ```
4.  **Push the workflow file** to your repository.
5.  **Observe the workflow run**: Go to the "Actions" tab in your repository, find the run for "Check Variables Exercise", and inspect the logs. Verify that `MY_API_TOKEN` is masked as `***` in the output, while `APP_VERSION` and `BUILD_TYPE` are visible.

## Additional Resources
-   **GitHub Docs - Encrypted secrets**: [https://docs.github.com/en/actions/security-guides/encrypted-secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
-   **GitHub Docs - Environment variables**: [https://docs.github.com/en/actions/learn-github-actions/variables](https://docs.github.com/en/actions/learn-github-actions/variables)
-   **GitHub Docs - Environments**: [https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
