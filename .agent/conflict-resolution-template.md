# Conflict Resolution Template for Codex-Cloud

## Standard Comment Template

````markdown
@codex please resolve this conflict set with the canonical wording below

PR: #{{PR}} — {{repo}}
Base: ``{{baseRef}}``  
Head: ``{{headRef}}``

## Context
We're normalizing wording in the **{{section}}** section. Preserve automation policy and concise style.

### Conflict hunk
````diff
<<<<<<< {{headRef}}
- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off); run `make-audit-pack.ps1` on-demand for manual capture
=======
- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail; run `make-audit-pack.ps1` on-demand if you need a manual capture
>>>>>>> {{baseRef}}
````

### Canonical resolution (apply exactly)

```markdown
- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off). Run `make-audit-pack.ps1` on demand for a manual capture.
```

### Style/intent rules

* Keep **"(hands-off)"** parenthetical (automation policy).
* Prefer concise, declarative style.
* Use **"on demand"** (no hyphen). Break into two sentences.
* Preserve the arrow **→** for action/result mapping.

### Where to patch

* File containing the heading: `## 🔄 Periodic Maintenance`
* Replace any existing "Weekly" bullet beginning with:
  `- **Weekly:** \`setup-weekly-audit.ps1\`\`

### Idempotent awk fixer (optional)

```bash
awk '
  BEGIN{h=0}
  /^##[[:space:]]+🔄[[:space:]]+Periodic[[:space:]]+Maintenance/{h=1}
  h==1 && /^- \*\*Weekly:\*\* `setup-weekly-audit\.ps1`/{
    print "- **Weekly:** `setup-weekly-audit.ps1` → automated evidence trail (hands-off). Run `make-audit-pack.ps1` on demand for a manual capture."
    next
  }
  {print}
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
```

### Acceptance criteria

* No merge markers remain.
* Weekly bullet matches the canonical line **exactly**.
* No unrelated lines changed.

````

## Common Conflict Patterns

### 1. Documentation Wording Conflicts

**Pattern**: Different phrasing for the same concept
**Resolution**: Apply consistent style rules
**Example**: "hands-off" vs "automated", "on-demand" vs "on demand"

### 2. Configuration Format Conflicts

**Pattern**: YAML/JSON formatting differences
**Resolution**: Apply project formatting standards
**Example**: Indentation, quote styles, field ordering

### 3. Script Path Conflicts

**Pattern**: Different file paths or references
**Resolution**: Use canonical paths from project structure
**Example**: `.\script.ps1` vs `scripts\script.ps1`

### 4. Version/Date Conflicts

**Pattern**: Different version numbers or dates
**Resolution**: Use the more recent or higher version
**Example**: Version bumps, timestamp updates

## Style Rules Reference

### Documentation
- Keep **"(hands-off)"** parenthetical for automation policy
- Use **"on demand"** (no hyphen)
- Prefer concise, declarative style
- Preserve arrows **→** for action/result mapping

### PowerShell Scripts
- Use `.\` for relative paths in current directory
- Use `Get-Content` with `-Raw` for multiline content
- Use `Set-Content` with `-NoNewline` to preserve exact formatting

### YAML Configuration
- Use 2-space indentation
- Quote strings that contain special characters
- Maintain consistent field ordering

### JSON Configuration
- Use 2-space indentation
- Trailing commas are not allowed
- Quote all object keys

## Safety Constraints

- **Maximum files changed**: 10 per PR
- **Maximum lines changed**: 200 per PR
- **Idempotence**: Patches must be safe to re-apply
- **No secrets**: Never commit tokens or keys
- **Diff-only**: Make minimal changes to resolve conflicts

## Verification Steps

1. **No merge markers**: Ensure `<<<<<<<`, `=======`, `>>>>>>>` are removed
2. **Style consistency**: Apply project style rules
3. **Functionality**: Verify scripts/configs still work
4. **Tests pass**: Run smoke tests if available
5. **Documentation**: Update if behavior changes

## Rollback Procedure

If a patch causes issues:

```powershell
# Revert to previous state
git checkout HEAD~1 -- <conflicted-file>

# Or reset entire branch
git reset --hard origin/main
```
