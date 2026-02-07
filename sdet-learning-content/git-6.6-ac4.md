# Git Branch Operations: Create, Switch, Merge, and Delete

## Overview
Branching is a core concept in Git, allowing developers to diverge from the main line of development to work on new features, bug fixes, or experiments without affecting the stable codebase. This mastery guide covers the essential Git commands for creating, switching between, merging, and deleting branches, crucial for collaborative development and efficient workflow. Understanding these operations is fundamental for any SDET to effectively manage code changes and contribute to a team project.

## Detailed Explanation

Git branches are essentially lightweight movable pointers to a commit. When you create a branch, Git creates a new pointer. When you make commits on that branch, the pointer moves forward.

### 1. Creating a New Branch (`git branch <branch-name>` or `git checkout -b <new-branch-name>`)
- `git branch <branch-name>`: Creates a new branch but keeps you on the current branch.
- `git checkout -b <new-branch-name>`: This is a convenience command that creates a new branch and immediately switches to it. It's equivalent to `git branch <new-branch-name>` followed by `git checkout <new-branch-name>`.

### 2. Switching Branches (`git checkout <branch-name>`)
- `git checkout <branch-name>`: Moves your `HEAD` pointer to the specified branch. This changes your working directory to reflect the snapshot of the chosen branch.
- `git switch <branch-name>` (newer alternative): A more intuitive and safer command introduced in Git 2.23. It's specifically for switching branches, separating concerns from `git restore`.

### 3. Merging Branches (`git merge <branch-to-merge-in>`)
- `git merge <branch-to-merge-in>`: Integrates changes from the specified branch into your current branch.
    - **Fast-forward merge**: Occurs when there is a linear path from the current branch to the target branch. Git simply moves the current branch pointer forward. No new merge commit is created.
    - **Three-way merge (recursive merge)**: Occurs when the branch histories have diverged. Git creates a new "merge commit" that has two parent commits (the tips of the merged branches). This is where merge conflicts can arise.

### 4. Deleting a Branch (`git branch -d <branch-name>` or `git branch -D <branch-name>`)
- `git branch -d <branch-name>`: Deletes the specified branch. Git will prevent deletion if the branch contains unmerged changes, acting as a safety mechanism.
- `git branch -D <branch-name>`: Force-deletes the specified branch, even if it contains unmerged changes. Use with caution! This is useful for discarding experimental branches.

### 5. Verifying the Graph (`git log --oneline --graph --all`)
- `git log --oneline --graph --all`: This command provides a concise, visual representation of your repository's commit history across all branches. It's invaluable for understanding the branching and merging flow.

## Code Implementation

Let's walk through a common branching scenario:

```bash
# 1. Initialize a new Git repository (if not already in one)
echo "# My Awesome Project" > README.md
git init
git add README.md
git commit -m "Initial commit: Add README"

# Verify current branch (usually 'master' or 'main')
git branch

# 2. Create a new feature branch and switch to it
echo "Creating and switching to 'feature/add-login' branch"
git checkout -b feature/add-login
git branch # Verify we are on feature/add-login

# 3. Make some changes on the feature branch
echo "console.log('Login function added');" > login.js
git add login.js
git commit -m "FEAT: Add login functionality"

# Simulate another commit on the feature branch
echo "console.log('Login form validation');" >> login.js
git add login.js
git commit -m "FEAT: Implement login form validation"

# 4. Switch back to the main branch
echo "Switching back to 'main' branch"
git checkout main
git branch # Verify we are on main

# 5. Simulate work on the main branch (e.g., a hotfix)
echo "console.log('Bug fix for header');" > header.js
git add header.js
git commit -m "FIX: Header alignment issue"

# 6. Merge the feature branch into main
echo "Merging 'feature/add-login' into 'main'"
git merge feature/add-login
# You might see a fast-forward or a merge commit, depending on history.

# 7. Verify the graph to see the merge history
echo "Git history graph:"
git log --oneline --graph --all

# 8. Delete the feature branch (after successful merge)
echo "Deleting 'feature/add-login' branch"
git branch -d feature/add-login

# Try to delete it again (will fail as it's already deleted)
# git branch -d feature/add-login

# Create a new experimental branch with some changes
git checkout -b experimental/temp-feature
echo "Experimental code" > temp.js
git add temp.js
git commit -m "EXP: Temporary feature"

# Force delete an unmerged branch
echo "Force deleting 'experimental/temp-feature' without merging"
git branch -D experimental/temp-feature

# Verify branches after deletion
echo "Branches after cleanup:"
git branch
```

## Best Practices
- **Feature Branches**: Always work on separate branches for new features or bug fixes. This isolates your changes and prevents breaking the main codebase.
- **Descriptive Branch Names**: Use clear and concise branch names (e.g., `feature/user-profile`, `bugfix/login-issue`, `refactor/api-endpoints`).
- **Frequent Commits**: Commit small, logical changes frequently to your branch. This makes merging easier and provides granular history.
- **Pull/Merge Request Workflow**: In team environments, use pull requests (GitHub/GitLab/Bitbucket) or merge requests (GitLab) to review and discuss changes before merging into `main`.
- **Keep `main` Clean**: The `main` (or `master`) branch should always be deployable and stable.
- **Regularly Rebase/Merge `main`**: Before merging your feature branch back into `main`, update your feature branch with the latest changes from `main` to resolve conflicts early. `git pull --rebase origin main` (if tracking a remote) or `git merge main` (if main is local) from your feature branch is a good practice.

## Common Pitfalls
- **Merging without Pulling Latest `main`**: Merging an outdated feature branch into `main` can lead to complex conflicts and introduce regressions. Always `git pull origin main` (or equivalent) into your feature branch before merging into `main`.
- **Force Deleting (`-D`) a Branch Accidentally**: Using `-D` can lead to loss of unmerged work. Always ensure you no longer need the commits on a branch before force deleting.
- **Working Directly on `main`**: Making direct commits to `main` bypasses code review processes and can introduce instability.
- **Long-lived Branches**: Branches that exist for a very long time without merging or rebasing can accumulate many conflicts, making the eventual merge very difficult.

## Interview Questions & Answers
1.  **Q: Explain the difference between `git branch -d` and `git branch -D`. When would you use each?**
    A: `git branch -d <branch-name>` is a "safe" deletion. It will only delete the branch if it has been fully merged into its upstream branch (or `HEAD`). If there are unmerged commits, Git will warn you and refuse to delete the branch. `git branch -D <branch-name>` is a "force" deletion. It will delete the branch regardless of its merged status, discarding any unmerged commits. You would use `-d` for cleaning up successfully merged branches, and `-D` for discarding experimental or unwanted branches where you are certain you don't need the changes.

2.  **Q: Describe a typical Git workflow involving branching for a new feature.**
    A: A typical workflow starts by ensuring your `main` branch is up-to-date (`git checkout main && git pull`). Then, create a new feature branch from `main` (`git checkout -b feature/new-feature`). Work on the feature, making frequent, small commits. Periodically, pull the latest changes from `main` into your feature branch (`git checkout main && git pull && git checkout feature/new-feature && git merge main`) to resolve conflicts early. Once the feature is complete and tested, push your branch to the remote, create a pull request, get it reviewed, and then merge it into `main`. Finally, delete the local and remote feature branches.

3.  **Q: How do you handle a merge conflict?**
    A: When a `git merge` or `git pull` results in conflicts, Git will pause the operation and mark the conflicting files. You need to manually edit these files, looking for conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`). Choose which changes to keep (yours, theirs, or a combination). After resolving the conflicts in all files, `git add` the resolved files and then `git commit` to finalize the merge.

## Hands-on Exercise
1.  Create a new directory and initialize a Git repository.
2.  Create a branch named `develop`.
3.  Switch to `develop` and create a file `app.py` with some initial code. Commit this change.
4.  Switch back to `main`.
5.  Create another branch named `feature/database` from `main`.
6.  On `feature/database`, create a file `database.py` and commit it.
7.  Switch to `develop`.
8.  Merge `main` into `develop` (this should be a fast-forward).
9.  Now, on `develop`, add a new function to `app.py`. Commit this change.
10. Switch back to `feature/database`. Make a conflicting change to `app.py` (e.g., modify the same line as on `develop`). Commit this change.
11. Attempt to merge `feature/database` into `develop`. Resolve the merge conflict.
12. Use `git log --oneline --graph --all` to visualize your history.
13. Delete the `feature/database` branch.

## Additional Resources
- [Git Branching - Basic Branching and Merging](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging)
- [Atlassian Git Tutorial - Branches](https://www.atlassian.com/git/tutorials/using-branches)
- [Pro Git Book](https://git-scm.com/book/en/v2) (Chapter 3: Git Branching)