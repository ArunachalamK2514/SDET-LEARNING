# GitHub Actions for Test Automation: Uploading and Downloading Test Artifacts

## Overview
In continuous integration and continuous deployment (CI/CD) pipelines, especially within test automation, it's crucial to preserve and access outputs from test runs. These outputs, known as "artifacts," can include test reports (HTML, XML, JSON), screenshots, video recordings of test execution, logs, or any other files generated during the workflow. GitHub Actions provides a robust mechanism to upload these artifacts during a workflow run and then download them later for analysis, debugging, or reporting purposes. This ensures that even if a job fails, the evidence for troubleshooting is readily available.

## Detailed Explanation
The `actions/upload-artifact` and `actions/download-artifact` actions are fundamental for managing artifacts in GitHub Actions.

### `actions/upload-artifact`
This action is used to upload files or directories produced by a workflow run. It takes several inputs:
-   `name`: (Required) The name of the artifact. This is how you'll refer to it when downloading. It's good practice to make this descriptive (e.g., `test-results-chromium`, `playwright-screenshots`).
-   `path`: (Required) One or more file paths or directory paths to upload. Wildcards (`*`, `**`) are supported. Multiple paths can be specified on separate lines.
-   `retention-days`: (Optional) The number of days to retain the artifact. Defaults to 90 days or the repository's default, whichever is less.

**Example Scenario:** After a Playwright test run, you might have an HTML report, screenshots of failed tests, and a video recording.

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Playwright
        run: npm install playwright
      - name: Run Playwright tests
        run: npx playwright test
      - name: Upload Playwright test results
        uses: actions/upload-artifact@v4 # Use v4 for newer features and better performance
        with:
          name: playwright-test-results
          path: |
            playwright-report/
            test-results/ # Contains screenshots, videos, traces
          retention-days: 5
```

### `actions/download-artifact`
This action is used to download artifacts that were previously uploaded in the same workflow run or in a different workflow run from the same repository. It can be particularly useful in subsequent jobs that need to process or publish these artifacts, or for manual downloads after a workflow completes.

-   `name`: (Optional) The name of the artifact to download. If omitted, all artifacts from the run are downloaded.
-   `path`: (Optional) The directory to download artifacts to. Defaults to the `GITHUB_WORKSPACE` directory. If a specific artifact name is provided, it will be downloaded into a subdirectory with that name.

**Example Scenario:** After tests run and artifacts are uploaded, you might have a separate job to publish these reports to an external service or simply ensure they are available for download.

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      # ... (steps to run tests and upload artifacts as shown above) ...

  publish-report:
    runs-on: ubuntu-latest
    needs: test # Ensure this job runs after the 'test' job
    steps:
      - name: Download all workflow artifacts
        uses: actions/download-artifact@v4
        with:
          path: downloaded-artifacts # All artifacts will be downloaded here

      - name: List downloaded files (for verification)
        run: ls -R downloaded-artifacts

      - name: Access Playwright report
        run: echo "Playwright report path: downloaded-artifacts/playwright-test-results/playwright-report/index.html"
        # In a real scenario, you might then publish this to a web server or attach it to a release.
```

## Code Implementation
Here's a comprehensive GitHub Actions workflow (`.github/workflows/playwright_tests.yml`) demonstrating both uploading and downloading artifacts for a Playwright test suite.

```yaml
# .github/workflows/playwright_tests.yml
name: Playwright Test Workflow with Artifacts

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
  workflow_dispatch: # Allows manual trigger

jobs:
  run-tests:
    name: Run Playwright Tests
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20' # Use a stable Node.js version

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install --with-deps

      - name: Run Playwright tests
        run: npx playwright test

      - name: Upload Playwright Test Report and Media
        uses: actions/upload-artifact@v4
        if: always() # Upload even if tests fail
        with:
          name: playwright-test-output
          path: |
            playwright-report/
            test-results/ # Contains screenshots, videos, traces
          retention-days: 7 # Retain artifacts for 7 days

  analyze-artifacts:
    name: Analyze & Process Artifacts
    runs-on: ubuntu-latest
    needs: run-tests # This job depends on 'run-tests' completing successfully
    if: success() || failure() # Run regardless of test job outcome

    steps:
      - name: Checkout code (optional, only if needed for further processing)
        uses: actions/checkout@v4

      - name: Download Playwright Test Output
        uses: actions/download-artifact@v4
        with:
          name: playwright-test-output
          path: ./downloaded-test-output # Downloads to this directory

      - name: List downloaded files for verification
        run: |
          echo "Contents of downloaded-test-output:"
          ls -R ./downloaded-test-output
          echo "---"

      - name: Example: Process HTML report (e.g., parse for summary, or serve locally)
        run: |
          if [ -f "./downloaded-test-output/playwright-report/index.html" ]; then
            echo "Playwright HTML report found. You can now process it."
            # Example: copy to a web server directory, or use a tool to parse it.
            # cp ./downloaded-test-output/playwright-report/index.html /var/www/html/playwright-report.html
          else
            echo "Playwright HTML report not found, perhaps tests didn't generate one or path is incorrect."
          fi

      - name: Example: Access a specific screenshot if available
        run: |
          find ./downloaded-test-output -name "*.png" -print -quit
          echo "If any .png files are listed above, you can access them."
```

## Best Practices
-   **Use `if: always()` for uploads:** Always upload artifacts even if tests fail (`if: always()`). This ensures you have debugging information regardless of the test outcome.
-   **Descriptive artifact names:** Use meaningful names for artifacts (e.g., `junit-xml-reports`, `screenshots-chrome`) to easily identify them.
-   **Control retention:** Set `retention-days` to manage storage and keep your repository tidy. For frequently failing tests, a shorter retention might be useful; for critical releases, longer.
-   **Path specificity:** Be specific with your `path` input. Avoid uploading unnecessary files to keep artifact sizes small and uploads fast.
-   **Dependencies with `needs`:** When downloading artifacts in a subsequent job, ensure that job explicitly `needs` the job that uploaded the artifacts.
-   **Download all vs. specific:** If a job requires multiple artifacts from the same run, you can either download them individually by name or omit the `name` field in `download-artifact` to get all of them.

## Common Pitfalls
-   **Incorrect paths:** Mismatched `path` values in `upload-artifact` lead to empty artifacts or missing files. Double-check the directory structure where your reports/media are generated.
-   **Forgetting `if: always()`:** If you don't use `if: always()` for the upload step, artifacts from failed jobs won't be uploaded, making debugging harder.
-   **Large artifact sizes:** Uploading entire `node_modules` or build directories can quickly consume storage and slow down workflows. Be selective.
-   **Missing `needs` dependency:** If a download job runs before the upload job completes, the artifact won't exist, leading to failure.
-   **Artifact name confusion:** If multiple `upload-artifact` steps use the same `name` in different jobs, they might overwrite each other if not carefully managed or if a new action run starts.

## Interview Questions & Answers
1.  **Q: Why is artifact management important in a CI/CD pipeline for test automation?**
    A: Artifact management is critical because it allows us to persist and retrieve crucial outputs from test runs. This includes test reports (for pass/fail status, detailed results), logs (for debugging), screenshots/videos (for visual evidence of failures), and other generated data. Without artifacts, diagnosing failures or demonstrating test coverage becomes significantly harder, breaking the feedback loop essential for CI/CD.

2.  **Q: Explain the difference between `actions/upload-artifact` and `actions/download-artifact`. When would you use each?**
    A: `actions/upload-artifact` is used within a workflow job to take files or directories generated during that job's execution and store them as a workflow artifact. You use it immediately after a process (like test execution) generates output you want to save. `actions/download-artifact` is used to retrieve these stored artifacts. You'd typically use it in a subsequent job (e.g., a "publish report" job) that needs access to those files, or simply to make the artifacts available for manual download from the GitHub Actions UI after the workflow completes.

3.  **Q: How do you ensure artifacts are uploaded even if a test job fails in GitHub Actions?**
    A: You ensure artifacts are uploaded by adding an `if: always()` condition to the `upload-artifact` step. This condition overrides the default behavior, which is to skip subsequent steps if an earlier step in the same job fails. By using `if: always()`, the artifact upload step will execute regardless of whether the test command succeeded or failed, ensuring that valuable debugging information is always preserved.

## Hands-on Exercise
**Goal:** Create a simple GitHub Actions workflow that runs a basic script, generates a log file, and then uploads this log file as an artifact. In a subsequent job, download and display the content of this artifact.

**Steps:**
1.  **Create a new file:** In your project's root, create a file named `simple_script.sh` with the following content:
    ```bash
    #!/bin/bash
    echo "Running a simple script at $(date)" > script_output.log
    echo "This is a log message." >> script_output.log
    echo "Script finished successfully." >> script_output.log
    exit 0
    ```
2.  **Make it executable:** `chmod +x simple_script.sh`
3.  **Create workflow file:** Create `.github/workflows/artifact_exercise.yml`:
    ```yaml
    name: Artifact Exercise Workflow

    on:
      workflow_dispatch:

    jobs:
      generate-and-upload:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
          - name: Run simple script
            run: ./simple_script.sh
          - name: Upload log file
            uses: actions/upload-artifact@v4
            with:
              name: script-logs
              path: script_output.log

      download-and-display:
        runs-on: ubuntu-latest
        needs: generate-and-upload
        steps:
          - uses: actions/checkout@v4 # Optional, but good practice
          - name: Download log file
            uses: actions/download-artifact@v4
            with:
              name: script-logs
              path: ./downloaded-artifacts
          - name: Display downloaded log content
            run: cat ./downloaded-artifacts/script_output.log
    ```
4.  **Push to GitHub:** Push these changes to your GitHub repository.
5.  **Run the workflow:** Go to your repository's Actions tab, find "Artifact Exercise Workflow", and run it manually using "Run workflow".
6.  **Verify:** After the workflow completes, check the "Summary" page of the workflow run. You should see "Artifacts" listed (e.g., `script-logs`) that you can download. Also, check the output of the `Display downloaded log content` step in the `download-and-display` job to see the log content echoed in the workflow run logs.

## Additional Resources
-   **GitHub Actions Documentation - Storing workflow data as artifacts:** [https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
-   **`actions/upload-artifact` on GitHub Marketplace:** [https://github.com/actions/upload-artifact](https://github.com/actions/upload-artifact)
-   **`actions/download-artifact` on GitHub Marketplace:** [https://github.com/actions/download-artifact](https://github.com/actions/download-artifact)
