# Comfort Cat — Filesystem Naming Pitfalls (Systemic Examples)

Why this matters
- Naming drift (spaces vs hyphens, case, Unicode lookalikes) produces duplicate directories, broken links, and fragile scripts.
- This is systemic: OSs, shells, editors, and humans handle names differently.

Common pitfalls (with examples)
- Spaces vs hyphens
  - Example: `docs/comfort cat` vs `docs/comfort-cat`
  - Breaks: globs, URLs, scripts without quoting
- Case differences
  - Example: `Assets/` vs `assets/` (works on Windows/macOS, breaks on Linux)
- Unicode lookalikes
  - Example: `copy.md` vs `сopy.md` (Cyrillic “с”), `type.md` vs `typе.md` (Cyrillic “е”)
- Trailing/leading whitespace
  - Example: `guides/ README.md` (invisible in diffs; confusing merges)
- Punctuation and special chars
  - Example: `design&motion/` or `cat#1/` (requires quoting/escaping in many tools)
- Locale normalization
  - Example: `résumé/` vs `resume/` vs `résumé/` (composed vs decomposed accents)

Comfort Cat rules (adopt consistently)
- Directory/file names: lowercase, hyphen-separated, ASCII only
- No spaces; no punctuation beyond `-` and `.`
- Reserve caps for code symbols, not filenames
- Use one canonical path in code: `docs/comfort-cat` (Windows mirror may differ)
- Add a header line to creative-facing files: `See C:\otel\docs\comfort cat`

How to avoid systemic issues
- Pre-commit checks
  - Add a linter to reject non-canonical names
- Repo search before creating folders
  - `rg --ignore-case --iglob '*/' 'comfort.?cat'`
- Normalize during merges
  - Copy into canonical path; suffix conflicts with `.conflict`; resolve explicitly
- Teach scripts to be resilient
  - Always quote paths; avoid bare globs; prefer `-LiteralPath`

Quick detection commands
```powershell
# Find space vs hyphen variants
Get-ChildItem -Recurse -Directory | Where-Object { $_.Name -match ' ' -or $_.Name -match '-' } | Select-Object FullName

# Case-only duplicates (Windows/macOS): potential Linux breakage
Get-ChildItem -Recurse -Directory | Group-Object { $_.FullName.ToLowerInvariant() } | Where-Object { $_.Count -gt 1 }

# Unicode lookalikes (rough heuristic)
rg -n "[\u0400-\u04FF]"  # Cyrillic range
```

Remediation playbook
- Pick the canonical name (lowercase-hyphen-ASCII)
- Move/copy content; write a merge report
- Update references (repo path vs Windows mirror)
- Add an incident note under `docs/ECRR_REPORTS/`

Footnote
- Problem is global: shell quoting, editor normalization, OS case sensitivity, and language lookalikes all contribute. We choose convention + tooling over confusion.

macOS compatibility notes (handy pitfalls)
- Default case-insensitive filesystem (APFS/HFS+)
  - macOS allows `Assets/` and `assets/` to co-exist in Git history but not on disk; you may only see one. Linux CI (case-sensitive) will see both and fail. Prefer lowercase names only.
- Unicode normalization (NFD vs NFC)
  - macOS often stores filenames in decomposed form (e.g., `résumé`). Linux/Windows may use composed form (`résumé`). Avoid non-ASCII in names; otherwise expect merge diffs that look identical.
- Hidden files and metadata
  - `.DS_Store`, `._*` AppleDouble files, and extended attributes (xattrs) like `com.apple.quarantine` can sneak into archives.
  - Clean up:
    - `find . -name .DS_Store -delete`
    - `git config --global core.excludesfile ~/.gitignore_global` and add `.DS_Store` there
- Executable bits
  - macOS respects POSIX exec bits; Windows doesn’t. Use `git add --chmod=+x script.sh` to keep CI consistent.
- Symlinks vs Aliases
  - Prefer real symlinks committed to Git. Finder “Aliases” are metadata pointers and won’t behave in CI.
- Line endings
  - macOS uses LF (same as Linux). Keep `.gitattributes` to enforce LF for scripts: `*.sh text eol=lf`.
