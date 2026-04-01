# Branch & Repository Protection Setup

> Manual steps the repository owner must apply in **GitHub Settings → Branches**.

## Branch Strategy

```
hardening (development)
    │
    │  All changes happen here.
    │  CI Gate runs: lint → build → scan → smoke test
    │
    ▼
PR: hardening → main
    │
    │  Requires: all CI Gate checks passed + CODEOWNER approval
    │
    ▼
main (production)
    │
    │  Publish workflow runs: build → final scan → push → sign → SBOM
    │
    ▼
ghcr.io/yonrasgg/<image>:latest    ← signed, attested, scanned
```

## Branch Protection Rules

### `main` (apply these settings)

| Setting | Value | Why |
|---------|-------|-----|
| **Require a pull request before merging** | ✅ | No direct pushes to main |
| **Required approvals** | 1 | CODEOWNER must review |
| **Dismiss stale PR reviews** | ✅ | New pushes invalidate old approvals |
| **Require status checks to pass** | ✅ | Gate must pass before merge |
| **Required status checks** | `✅ All CI Gates Passed` | The aggregated gate job |
| **Require branches to be up-to-date** | ✅ | Tests run on latest main |
| **Require signed commits** | Optional | Cosign handles image signing |
| **Require linear history** | ✅ | Squash merge for clean history |
| **Include administrators** | ✅ | Even admins go through the gate |
| **Restrict who can push** | ✅ | Only merge via PR |
| **Allow force pushes** | ❌ | Never |
| **Allow deletions** | ❌ | Never |

### `hardening` (lighter rules)

| Setting | Value | Why |
|---------|-------|-----|
| **Allow direct pushes** | ✅ | Fast iteration during development |
| **Allow force pushes** | ❌ | Preserve history |
| **Allow deletions** | ❌ | Protect the branch |

## How to Apply

1. Go to **Settings → Branches → Add branch protection rule**
2. Branch name pattern: `main`
3. Apply the settings from the table above
4. Check **"✅ All CI Gates Passed"** under required status checks
   - This job name comes from `.github/workflows/ci-gate.yml`
   - It will appear after the first PR run
5. Save the rule
6. Repeat for `hardening` with lighter settings

## Rulesets (Alternative — Recommended)

GitHub Rulesets are the newer, more flexible version of branch protection. If available:

1. **Settings → Rules → Rulesets → New ruleset**
2. Target: `main`
3. Add rules:
   - Require pull request (1 approval, dismiss stale)
   - Require status checks: `✅ All CI Gates Passed`
   - Require linear history
   - Block force pushes
   - Block deletions

## Tag Protection

If you publish versioned tags:

1. **Settings → Tags → Protected tags**
2. Pattern: `v*`
3. Only maintainers can create version tags
