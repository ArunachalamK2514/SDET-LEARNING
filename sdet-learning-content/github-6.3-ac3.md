# GitHub Actions: Configuring Workflow Triggers

## Overview
GitHub Actions workflows are automated processes that can be triggered by specific events in your repository. Understanding how to configure these triggers is fundamental to building robust Continuous Integration/Continuous Deployment (CI/CD) pipelines. This document delves into various trigger types, including `push`, `pull_request`, `schedule`, and `workflow_dispatch`, providing SDETs with the knowledge to automate testing and deployment efficiently. Properly configured triggers ensure that your automation runs precisely when needed, optimizing resource usage and maintaining code quality.

## Detailed Explanation

GitHub Actions workflows are defined in YAML files (`.yml` or `.yaml`) located in the `.github/workflows/` directory of your repository. The `on:` keyword specifies the event(s) that trigger the workflow.

### 1. `push` Trigger
The `push` event triggers a workflow when a commit is pushed to the repository. You can specify branches to include or exclude.

-   **Trigger on push to main branch:** This is common for running unit tests or linters immediately after code is merged or pushed directly to the main development branch.
    ```yaml
    on:
      push:
        branches:
          - main # Triggers when changes are pushed to the 'main' branch
    ```
-   **Excluding branches:** You might want to run a workflow on all pushes except those to specific release branches.
    ```yaml
    on:
      push:
        branches-ignore:
          - 'releases/**' # Ignores pushes to any branch under 'releases/'
    ```
-   **Filtering by paths:** You can also trigger workflows only when changes occur in specific directories. This is useful for monorepos.
    ```yaml
    on:
      push:
        paths:
          - 'src/**' # Triggers only if changes are made within the 'src/' directory
          - 'tests/**' # Or within the 'tests/' directory
    ```

### 2. `pull_request` Trigger
The `pull_request` event triggers a workflow when a pull request is opened, synchronized, reopened, or edited. This is crucial for running pre-merge checks like integration tests, code quality scans, and UI tests.

-   **Trigger on PR opening/sync:**
    ```yaml
    on:
      pull_request:
        branches:
          - main # Triggers for PRs targeting the 'main' branch
        types: [opened, synchronize, reopened] # Specific PR activity types
    ```
    -   `opened`: When a new pull request is opened.
    -   `synchronize`: When new commits are pushed to the PR's branch.
    -   `reopened`: When a pull request is reopened after being closed.
    -   `edited`: When a pull request's title or description is edited (less common for test automation).

### 3. `schedule` Trigger
The `schedule` event allows workflows to run at specific times using cron syntax. This is ideal for nightly builds, daily reports, scheduled end-to-end tests, or data cleanup tasks.

-   **Trigger on cron schedule (e.g., `0 0 * * *`):** This example runs daily at midnight UTC.
    ```yaml
    on:
      schedule:
        # Run daily at midnight UTC
        # For more cron schedule examples, see: https://crontab.guru/
        - cron: '0 0 * * *' # Minute, Hour, Day of Month, Month, Day of Week
    ```
    Cron syntax: `┌─── minute (0 - 59)`
    `│ ┌─── hour (0 - 23)`
    `│ │ ┌─── day of month (1 - 31)`
    `│ │ │ ┌─── month (1 - 12)`
    `│ │ │ │ ┌─── day of week (0 - 6, where 0 is Sunday)`
    `│ │ │ │ │`
    `* * * * *`

### 4. `workflow_dispatch` Trigger
The `workflow_dispatch` event allows you to manually trigger a workflow from the GitHub UI, GitHub CLI, or REST API. This is invaluable for ad-hoc test runs, re-running failed deployments, or executing administrative tasks.

-   **Manually trigger using `workflow_dispatch`:**
    ```yaml
    on:
      workflow_dispatch:
        inputs:
          logLevel:
            description: 'Log level'
            required: true
            default: 'warning'
            type: choice
            options:
            - info
            - warning
            - debug
          tags:
            description: 'Test scenario tags'
            required: false
            type: string
          environment:
            description: 'The environment to deploy to'
            required: true
            default: 'dev'
            type: environment
    ```
    This example demonstrates how to add input parameters, allowing users to customize the workflow run directly from the GitHub UI. These inputs are then accessible within the workflow using `github.event.inputs.<input_name>`.

## Code Implementation

Here's a complete YAML example demonstrating all these triggers in a single workflow file, along with a simple job that prints the event type.

```yaml
name: CI Workflow Triggers Demo

on:
  push:
    branches:
      - main # Trigger on pushes to the 'main' branch
    paths-ignore:
      - '**/docs/**' # Ignore changes in the docs folder

  pull_request:
    branches:
      - main # Trigger for PRs targeting 'main'
    types: [opened, synchronize, reopened] # Specific PR activities

  schedule:
    # Run every day at 3 AM UTC
    - cron: '0 3 * * *'

  workflow_dispatch:
    inputs:
      test_suite:
        description: 'Which test suite to run?'
        required: true
        default: 'smoke'
        type: choice
        options:
          - smoke
          - regression
          - full

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Report event type
        run: echo "This workflow was triggered by a ${{ github.event_name }} event."

      - name: Handle workflow_dispatch inputs
        if: github.event_name == 'workflow_dispatch'
        run: |
          echo "Manual trigger activated!"
          echo "Selected test suite: ${{ github.event.inputs.test_suite }}"
          # In a real scenario, you would use this input to run specific tests.
          # For example: mvn test -Dsuite=${{ github.event.inputs.test_suite }}
```

## Best Practices
-   **Specificity:** Be as specific as possible with branches (`branches`, `branches-ignore`) and paths (`paths`, `paths-ignore`) to avoid unnecessary workflow runs and save CI minutes.
-   **`pull_request` for pre-merge checks:** Always use `pull_request` triggers for any automated checks (linting, unit tests, integration tests) that must pass before code is merged.
-   **`schedule` for comprehensive/long-running tests:** Reserve scheduled triggers for tests that are resource-intensive, take a long time, or need to run outside of regular development hours (e.g., full regression suites, performance tests).
-   **`workflow_dispatch` for ad-hoc execution:** Provide `workflow_dispatch` with meaningful inputs for flexible, on-demand execution of specific tasks or test suites.
-   **Combine triggers:** It's common to combine `push` (for fast feedback on development branches), `pull_request` (for quality gates), and `workflow_dispatch` (for manual intervention) in a single workflow.

## Common Pitfalls
-   **Over-triggering:** Not using `branches`, `paths`, or `types` filters can lead to workflows running far too often, consuming valuable CI resources and slowing down feedback loops.
    *   **How to avoid:** Always define `branches` or `branches-ignore` and `paths` or `paths-ignore` for `push` and `pull_request` events relevant to your project structure.
-   **Incorrect Cron Syntax:** Misunderstanding cron syntax can lead to workflows running at unexpected times or not at all.
    *   **How to avoid:** Use a cron expression validator (like [crontab.guru](https://crontab.guru/)) to verify your schedules. Remember GitHub Actions schedules are in UTC.
-   **Sensitive Data in `workflow_dispatch` inputs:** Avoid passing sensitive information directly as `workflow_dispatch` inputs, as they are visible in the UI.
    *   **How to avoid:** Use GitHub Secrets for sensitive data, which can then be referenced within the workflow.
-   **Lack of `pull_request` for critical checks:** Relying solely on `push` for all checks can mean that issues are only caught *after* merging, leading to a broken `main` branch.
    *   **How to avoid:** Implement robust `pull_request` checks, and consider using branch protection rules to enforce that these checks pass before merging.

## Interview Questions & Answers
1.  **Q: Explain the difference between `on: push` and `on: pull_request` triggers in GitHub Actions.**
    A: The `on: push` trigger runs a workflow when new commits are pushed to a specified branch. This is often used for immediate feedback on code changes or for deploying to development environments. The `on: pull_request` trigger, on the other hand, runs when a pull request is opened, synchronized (new commits pushed to the PR branch), or reopened. It's primarily used for validating code quality, running tests, and ensuring all checks pass *before* merging the code into a target branch like `main`.

2.  **Q: When would you use a `schedule` trigger, and can you provide an example of its cron syntax?**
    A: A `schedule` trigger is used when you need to run a workflow at a specific, recurring time interval, irrespective of code changes. Common use cases include nightly regression test suites, daily security scans, or generating periodic reports. An example of cron syntax to run a workflow every Sunday at 1 AM UTC would be `0 1 * * SUN`.

3.  **Q: How can you manually trigger a GitHub Actions workflow, and why would an SDET use this feature?**
    A: A GitHub Actions workflow can be manually triggered using the `workflow_dispatch` event. This adds a "Run workflow" button in the GitHub UI, allowing users to initiate a workflow run. An SDET would use `workflow_dispatch` for several reasons: to re-run a specific test suite ad-hoc, to debug a pipeline failure, to perform manual deployments to a specific environment, or to execute administrative tasks without requiring a code push. It's particularly useful for scenarios that don't fit into automatic `push` or `pull_request` triggers.

4.  **Q: How do `paths` and `paths-ignore` work with triggers, and why are they important for efficient CI/CD?**
    A: `paths` and `paths-ignore` are filters that you can apply to `push` and `pull_request` events. `paths` will only trigger the workflow if changes are detected in the specified files or directories, while `paths-ignore` will prevent the workflow from triggering if changes are *only* in the ignored paths. They are crucial for efficient CI/CD, especially in monorepos, because they prevent unnecessary workflow runs. For instance, if you have separate services in a monorepo, a change to `serviceA/src/` should only trigger CI for Service A, not for Service B, saving CI minutes and speeding up feedback.

## Hands-on Exercise
1.  **Objective:** Create a GitHub Actions workflow that runs different tests based on the trigger event and an input parameter.
2.  **Instructions:**
    *   In your repository, create a new file: `.github/workflows/trigger-exercise.yml`.
    *   Configure the workflow to trigger on:
        *   `push` to any branch starting with `feature/`.
        *   `pull_request` targeting the `main` branch.
        *   `schedule` to run every Monday at 9 AM UTC.
        *   `workflow_dispatch` with an input named `test_type` that accepts `unit`, `e2e`, or `api` (default to `unit`).
    *   Add a job that checks out the code.
    *   Add a step that prints "Running unit tests" if the event is `push` or if `test_type` is `unit` via `workflow_dispatch`.
    *   Add a step that prints "Running E2E tests" if the event is `pull_request` or if `test_type` is `e2e` via `workflow_dispatch`.
    *   Add a step that prints "Running API tests (scheduled)" if the event is `schedule` or if `test_type` is `api` via `workflow_dispatch`.
    *   Push a commit to a `feature/new-feature` branch, open a PR to `main`, and manually trigger the workflow from the UI with different `test_type` values to observe the behavior.

## Additional Resources
-   **Events that trigger workflows:** [https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows)
-   **Workflow syntax for GitHub Actions:** [https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#on](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#on)
-   **Crontab Guru:** [https://crontab.guru/](https://crontab.guru/) - A helpful tool for understanding cron schedules.
