---
name: dependabot-triage
description: Triage and land open Dependabot (or other automated dependency) pull requests safely — enumerate them, check each one's CI, merge the green independent ones, and correctly handle bumps that only pass when landed together (lockstep dependencies like nixpkgs + nix-darwin/home-manager, or a library + its type stubs). Use this whenever the user asks to "handle", "deal with", "process", "clear out", "捌く/裁く", review, or merge Dependabot / dependency-update PRs, or when a dependency-bump PR is failing CI and you need to know whether it's a real break or a missing companion bump. Reach for it even if the user just says "sort out the dependabot PRs" without naming CI or lockstep.
---

# Dependabot Triage

Automated dependency PRs (Dependabot, Renovate, etc.) arrive in batches and mostly want to be merged — but not blindly. Some fail CI because the upgrade genuinely broke something, and some fail only because a *sibling* input needs to move at the same time. The job is to land the safe ones quickly and resolve the entangled ones correctly, without leaving the default branch broken and without creating noise the user didn't ask for.

## Core principle

**Never merge on the PR title alone. Read each PR's CI result first, and when CI is red, read the failure log before deciding.** A green independent bump is a one-click merge; a red one is a question ("is this a real break, or a missing companion?") that you answer from the log, not from a guess.

## Workflow

### 1. Enumerate the open automated PRs

Search for them rather than scrolling the PR list:

```
is:pr is:open author:app/dependabot
```

(Use `author:app/renovate` for Renovate.) For each PR, note the number, the dependency it bumps, and the head SHA.

### 2. Get each PR's real status

For every PR, fetch two things:
- **`mergeable_state`** — `clean` means mergeable with checks passing; `unstable` means mergeable **but a check is failing or still pending**; `blocked`/`dirty` mean a required check failed or there's a conflict. `unstable` is *not* a green light — treat it as "look closer".
- **The CI check runs / workflow conclusion** for the head SHA — this is the source of truth. `mergeable_state` can lag or reflect non-required checks.

Categorize each PR into:
- **Green** — CI passed. Candidate for immediate merge.
- **Red** — CI failed. Needs investigation before any action.
- **Pending** — CI still running. Wait for it before merging; don't merge into a pending state.

### 3. Merge the green, independent PRs

For each green PR whose change is self-contained (one dependency, no obvious relationship to another failing PR), merge it. A few practical notes:

- **Respect the repo's allowed merge methods.** If squash or rebase is disabled you'll get `405 ... merges are not allowed`; fall back to a plain merge commit. Don't fight the repo's settings.
- **Merge them one at a time** and let each settle. Bumps that touch the same lockfile usually edit *different stanzas*, so they don't textually conflict and stay mergeable after each merge — but check, don't assume.
- Dependabot **auto-closes** its own PR once the target version lands on the base branch, so you rarely need to close anything by hand or leave a comment. Stay frugal with comments.

### 4. Investigate every red PR before acting

Pull the failing job's log and find the actual error — don't assume "flaky, just rerun". Ask: *does the error name something that another open bump would provide or remove?* That question is what separates a real break from a lockstep pair (next section).

If the failure is a genuine incompatibility in that single dependency (a removed API your code uses, a real test failure), that's a real break: leave it, and tell the user what broke rather than merging red. Only escalate to a code change if the fix is small and unambiguous — otherwise surface it.

### 5. Detect and resolve lockstep (co-dependent) bumps

This is the case people miss. Two bumps each fail **on their own** but are **compatible together**, because they share a moving interface. Watch for it whenever the failing PRs are components that version together.

**The tell:** each PR's error references the *other* side of the same interface. Classic pattern from a Nix flake:

- Bumping **nixpkgs** alone fails: `nixos-render-docs ... --toc-depth has been removed, use --sidebar-depth instead` — the newer nixpkgs dropped a flag the *old* nix-darwin still passes.
- Bumping **nix-darwin** alone fails: `nixos-render-docs: error: unrecognized arguments: --sidebar-depth` — the newer nix-darwin passes a flag the *old* nixpkgs doesn't understand yet.

Two errors, opposite directions, same tool → they must move together. The structural reason here is `inputs.nixpkgs.follows = "nixpkgs"`: nix-darwin (and home-manager) render against the top-level nixpkgs, so their revisions are coupled. The same shape shows up elsewhere: a library and its separately-published type stubs, a plugin and its host framework, a codegen tool and its runtime.

**How to confirm cheaply:** the combination is what the default branch will actually contain after both land. You don't need a local build — when you open or update a PR that carries *both* bumps, CI runs on the merge-with-base ref and exercises exactly that combination. A green run there is your proof.

**How to land them** — pick based on what the user wants:
- **Co-merge the Dependabot PRs back-to-back** (default when the user says "just handle the Dependabot PRs"). Merge one then immediately the other. Each is individually red, but the branch is only briefly in the intermediate state and ends green. This keeps you inside Dependabot's own PRs and lets it auto-close them.
- **Combine into one branch** only if the user is comfortable with a separate PR, or if the repo blocks merging red PRs (required checks). Bump both inputs in one commit, push, let CI verify, then merge.

**Do not invent a replacement PR the user didn't ask for.** If they said "handle the Dependabot PRs", operate on those PRs — don't open your own combining PR unless they opt in. (If you already made one and they object, close it and delete the branch.)

### 6. Confirm the end state

After the dust settles, re-run the enumeration search — zero open automated PRs (or only the ones you deliberately left red with an explanation) means done. Note for the user which landed, which you combined and why, and any you left red because they're real breaks.

## Guardrails

- **Read before merge; read the log before touching red.** This is the whole skill in one line.
- **Green + independent → merge. Red → investigate. Pending → wait.**
- **Lockstep pairs move together** — never merge one half of a follows-coupled pair and walk away; you'll leave the branch broken.
- **Match the user's scope.** "Handle the Dependabot PRs" is authorization to merge/close *those* PRs, not to author new ones, push custom branches, or refactor. When the resolution needs more than that, ask first.
- **CI that only triggers on `pull_request` won't run on push to the default branch** — so your evidence that a combination works has to come from a PR's CI run, not from merging and hoping.
