# Agent Instructions

## GitHub Actions dependencies

- Keep remote GitHub Actions references on version tags and record their verified commits in `.github/workflows/actions.lock`.
- After adding, removing, or changing a remote `uses:` reference, install the GitHub CLI extension once with `gh extension install github/gh-actions-lock`, then run `gh actions-lock` and `gh actions-lock --verify` from the repository root.
- Do not edit `actions.lock` by hand; regenerate it with `gh actions-lock`.
- Renovate's `github-actions` manager is disabled because it updates workflow references without regenerating `actions.lock`. Update Action versions and the lockfile together by hand.
- Workflow files can differ between `main` and `for-business`. Verify and update the lockfile on the branch being changed.
