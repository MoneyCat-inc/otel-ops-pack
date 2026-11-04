#!/usr/bin/env python3
"""Fixture proof for the gitleaks lane (.gitleaks.toml, .github/workflows/gitleaks.yml).

Every leak class this repository has had must be caught, and placeholders and references
must not be. The script writes synthetic fixtures -- seeded random values, never real ones --
to a temporary directory outside the checkout, scans it twice with `gitleaks dir` (plain,
then --redact) and asserts per case:

  positive  exactly one finding in the file, from the expected rule, whose secret is exactly
            the planted value (so --redact masks the value, not the variable name);
  negative  no finding in the file;
and once for the run:
  redacted  no planted value appears anywhere in the --redact report;
  structure no [[rules]] id repeats in the config, and every custom regex has exactly one
            capture group with secretGroup = 1.

Exit 0 when every assertion holds, 1 when any fails, 2 when gitleaks cannot run. A check
that cannot fail proves nothing: point --config at the pre-2026-11-04 .gitleaks.toml
(git show 729121a:.gitleaks.toml) and it fails.

No token, key or name=value assignment that a rule would match appears in this file. Each
fixture line is a template (@NAME@, @V@) filled at run time, names are split string
literals and token prefixes are concatenated, so the scanner never flags its own proof.

Usage, from the repository root:
  python3 BRAV/SCPT/ci/gitleaks-fixtures.py [--config .gitleaks.toml] [--gitleaks gitleaks]
      [--seed 20261104] [--keep DIR] [--summary-json PATH]
"""
import argparse
import base64
import hashlib
import json
import os
import random
import shutil
import string
import subprocess
import sys
import tempfile

ALNUM = string.ascii_letters + string.digits
B32 = string.ascii_uppercase + "234567"
DASH5 = "-" * 5


class Gen:
    """Seeded generator of synthetic values; the same seed gives the same fixtures."""

    def __init__(self, seed):
        self.r = random.Random(seed)

    def s(self, n, alphabet=ALNUM):
        return "".join(self.r.choice(alphabet) for _ in range(n))

    def raw(self, n):
        return bytes(self.r.getrandbits(8) for _ in range(n))

    # Provider formats; each prefix is split so this file never contains a live-looking token.
    def ghp(self):
        return "gh" + "p_" + self.s(36)

    def akia(self):
        return "AK" + "IA" + self.s(16, B32)

    def xoxb(self):
        return (
            "xo"
            + "xb-"
            + self.s(12, string.digits)
            + "-"
            + self.s(13, string.digits)
            + "-"
            + self.s(24)
        )

    def glpat(self):
        return "gl" + "pat-" + self.s(20)

    def aiza(self):
        return "AI" + "za" + self.s(35, ALNUM + "_-")

    def pem(self):
        body = base64.b64encode(self.raw(256)).decode()
        kind = "RSA PRIVATE" + " KEY"
        lines = [body[i : i + 64] for i in range(0, len(body), 64)]
        return (
            DASH5
            + "BEGIN "
            + kind
            + DASH5
            + "\n"
            + "\n".join(lines)
            + "\n"
            + DASH5
            + "END "
            + kind
            + DASH5
        )

    def jwt(self):
        def b64url(data):
            return base64.urlsafe_b64encode(data).decode().rstrip("=")

        header = b64url(
            json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode()
        )
        claims = {
            "sub": self.s(12),
            "iat": 1700000000 + self.r.randrange(10**7),
            "nonce": self.s(16),
        }
        payload = b64url(json.dumps(claims, separators=(",", ":")).encode())
        return header + "." + payload + "." + b64url(self.raw(32))

    def signoz_key(self):
        # 32 random bytes in standard base64 (44 characters): the SigNoz API key format.
        return base64.b64encode(self.raw(32)).decode()

    def password(self, n=20):
        return self.s(1) + self.s(n - 1, ALNUM + "!@#%^*-_")

    def passphrase(self, words=5):
        # Word-like dev defaults are what the built-in generic rule's stopwords drop.
        pool = [
            "amber",
            "cobalt",
            "delta",
            "ember",
            "fjord",
            "garnet",
            "harbor",
            "indigo",
            "juniper",
            "kestrel",
            "lagoon",
            "marble",
            "nimbus",
            "orchid",
            "quartz",
        ]
        return "-".join(self.r.choice(pool) for _ in range(words))


def fill(template, name, value):
    text = template
    if name is not None:
        text = text.replace("@NAME@", name)
    if value is not None:
        text = text.replace("@V@", value)
    return text


def build_cases(g):
    """(id, class, kind, expected rule, fixture path, text, planted value)."""
    cases = []

    def pos(cid, klass, rule, path, template, name, value):
        cases.append(
            (cid, klass, "positive", rule, path, fill(template, name, value), value)
        )

    def neg(cid, klass, path, template, name=None, value=None):
        cases.append(
            (cid, klass, "negative", None, path, fill(template, name, value), None)
        )

    # Provider tokens (built-in rules, shipped with useDefault = true).
    pos(
        "P01",
        "GitHub PAT (ghp_)",
        "github-pat",
        "ci/publish.sh",
        "export @NAME@=@V@\n",
        "GH" "_TOKEN",
        g.ghp(),
    )
    pos(
        "P02",
        "AWS access key id (AKIA)",
        "aws-access-token",
        "infra/aws.ini",
        "[default]\naws_access_key_id = @V@\n",
        None,
        g.akia(),
    )
    pos(
        "P03",
        "Slack bot token (xoxb-)",
        "slack-bot-token",
        "ops/slack.yml",
        "slack:\n  @NAME@: @V@\n",
        "SLACK_BOT" "_TOKEN",
        g.xoxb(),
    )
    pos(
        "P04",
        "GitLab PAT (glpat-)",
        "gitlab-pat",
        "tools/mirror.py",
        '@NAME@ = "@V@"\n',
        "GITLAB" "_TOKEN",
        g.glpat(),
    )
    pos(
        "P05",
        "Google API key (AIza)",
        "gcp-api-key",
        "web/maps.js",
        'const mapsKey = "@V@";\n',
        None,
        g.aiza(),
    )
    pos(
        "P06",
        "PEM private key",
        "private-key",
        "deploy/server-key.txt",
        "@V@\n",
        None,
        g.pem(),
    )
    pos(
        "P07",
        "JWT",
        "jwt",
        "fixtures/session.json",
        '{"@NAME@": "@V@"}\n',
        "access" "_token",
        g.jwt(),
    )

    # SigNoz: the class this repository leaked (six distinct keys in .md/.ps1/.sh/.ts/env/compose).
    pos(
        "P08",
        "SIGNOZ_API_KEY in .md",
        "signoz-api-key",
        "docs/runbook.md",
        '# SigNoz ingest\n\n```powershell\n$env:@NAME@ = "@V@"\n```\n',
        "SIGNOZ" "_API_KEY",
        g.signoz_key(),
    )
    pos(
        "P09",
        "SigNoz key pasted bare in .md",
        "bare-base64-key",
        "docs/handoff.md",
        "## SigNoz access\n\n**Key:** `@V@`\n",
        None,
        g.signoz_key(),
    )
    pos(
        "P10",
        "SIGNOZ_API_TOKEN in .ps1",
        "signoz-api-key",
        "scripts/signoz.secrets.ps1",
        '$env:@NAME@ = "@V@"\n',
        "SIGNOZ" "_API_TOKEN",
        g.signoz_key(),
    )
    pos(
        "P11",
        "SIGNOZ_API_KEY in .ts (redaction)",
        "signoz-api-key",
        "lib/observability/signoz.ts",
        "const @NAME@ = '@V@';\n",
        "SIGNOZ" "_API_KEY",
        g.signoz_key(),
    )

    # Named and generic assignments.
    pos(
        "P12",
        "generic api_key",
        "api-key-assignment",
        "config/service.yaml",
        "service:\n  @NAME@: @V@\n",
        "api" "_key",
        g.s(40),
    )
    pos(
        "P13",
        "built-in generic-api-key (restored)",
        "generic-api-key",
        "app/settings.py",
        "client" '_secret = "@V@"\n',
        None,
        g.s(40),
    )
    pos(
        "P14",
        "*_API_TOKEN",
        "named-secret-literal",
        "deploy/grafana.sh",
        "export @NAME@=@V@\n",
        "GRAFANA" "_API_TOKEN",
        g.s(40),
    )
    pos(
        "P15",
        "*_JWT_SECRET",
        "named-secret-literal",
        "env/app.env.txt",
        "@NAME@=@V@\n",
        "SIGNOZ" "_JWT_SECRET",
        g.s(32),
    )
    pos(
        "P16",
        "*_PASSWORD",
        "named-secret-literal",
        "compose/db.yml",
        "services:\n  db:\n    environment:\n      @NAME@: @V@\n",
        "POSTGRES" "_PASSWORD",
        g.password(),
    )
    pos(
        "P17",
        "*_PASS",
        "named-secret-literal",
        "scripts/setup.sh",
        'export @NAME@="@V@"\n',
        "SIGNOZ" "_PASS",
        g.password(16),
    )
    pos(
        "P18",
        "${VAR:-default} in compose",
        "compose-secret-default",
        "compose/signoz.yml",
        "services:\n  query-service:\n    environment:\n      - @NAME@=$"
        "{@NAME@:-@V@}\n",
        "SIGNOZ" "_JWT_SECRET",
        g.s(30),
    )
    pos(
        "P19",
        "${VAR:=default} in shell",
        "compose-secret-default",
        "scripts/env.sh",
        ': "$' '{@NAME@:=@V@}"\n',
        "SMTP" "_PASSWORD",
        g.s(24),
    )
    pos(
        "P20",
        "PowerShell [string]$ApiToken default",
        "powershell-secret-literal",
        "scripts/setup-dashboards.ps1",
        'param(\n    [string]$@NAME@ = "@V@",\n    [string]$BaseUrl = "http://localhost:8080"\n)\n',
        "Api" "Token",
        g.passphrase(),
    )
    pos(
        "P21",
        "*_SECRET via SetEnvironmentVariable",
        "named-secret-literal",
        "docs/deploy-guide.md",
        '[Environment]::SetEnvironmentVariable("@NAME@", "@V@", "Machine")\n',
        "SIGNOZ_WEBHOOK" "_SECRET",
        g.passphrase(4) + "-" + g.s(4, string.digits),
    )
    pos(
        "P22",
        "SigNoz key as PowerShell $ApiToken default",
        "powershell-secret-literal",
        "scripts/test-signoz-api.ps1",
        '# SigNoz alert rules API\nparam(\n    [string]$@NAME@ = "@V@"\n)\n',
        "Api" "Token",
        g.signoz_key(),
    )
    pos(
        "P23",
        "key pasted bare, no SigNoz in the file",
        "bare-base64-key",
        "docs/handoff-2.md",
        "- **Token:** `@V@` (expires in 1 day)\n",
        None,
        g.signoz_key(),
    )

    # Placeholders and references: none may be reported.
    neg(
        "N01",
        "placeholder SigNoz key in .md",
        "docs/quickstart.md",
        '$env:@NAME@ = "your-signoz-api-key-here"\n',
        "SIGNOZ" "_API_KEY",
    )
    neg(
        "N02",
        "env interpolation",
        "compose/ref.yml",
        "      - @NAME@=$" "{@NAME@}\n",
        "SIGNOZ" "_API_KEY",
    )
    neg(
        "N03",
        "GitHub Actions secret reference",
        "ci/workflow.yml",
        "        env:\n          @NAME@: $" "{{ secrets.@NAME@ }}\n",
        "SIGNOZ" "_API_KEY",
    )
    neg(
        "N04",
        "PowerShell environment lookup",
        "scripts/read-key.ps1",
        '$key = [Environment]::GetEnvironmentVariable("@NAME@", "User")\n',
        "SIGNOZ" "_API_KEY",
    )
    neg(
        "N05",
        "compose empty default",
        "compose/empty.yml",
        "      - @NAME@=$" "{@NAME@:-}\n",
        "SIGNOZ" "_JWT_SECRET",
    )
    neg(
        "N06",
        "compose required, no default",
        "compose/required.yml",
        "      - @NAME@=$" "{@NAME@:?set @NAME@}\n",
        "SIGNOZ" "_JWT_SECRET",
    )
    neg(
        "N07",
        "compose nested default",
        "compose/nested.yml",
        "      - @NAME@=$" "{@NAME@:-$" "{FALLBACK" "_JWT_SECRET}}\n",
        "SIGNOZ" "_JWT_SECRET",
    )
    neg(
        "N08",
        "compose placeholder default",
        "compose/placeholder.yml",
        "      - @NAME@=$" "{@NAME@:-changeme}\n",
        "CLICKHOUSE" "_PASSWORD",
    )
    neg(
        "N09",
        "named placeholder",
        "env/smtp.env.txt",
        "@NAME@=your_smtp_password_here\n",
        "SMTP" "_PASSWORD",
    )
    neg(
        "N10",
        "named angle-bracket placeholder",
        "env/db.env.txt",
        "@NAME@=<set-in-vault>\n",
        "DB" "_PASSWORD",
    )
    neg(
        "N11",
        "Python environment lookup",
        "app/config.py",
        '@NAME@ = os.getenv("@NAME@")\n',
        "API" "_TOKEN",
    )
    neg(
        "N12",
        "function call",
        "app/vault.py",
        "@NAME@ = fetch_token_from_vault()\n",
        "API" "_TOKEN",
    )
    neg(
        "N13",
        "Node environment lookup",
        "web/config.js",
        "  @NAME@: process.env.@NAME@,\n",
        "API" "_TOKEN",
    )
    neg(
        "N14",
        "AWS documentation-style example id",
        "docs/aws.md",
        "aws_access_key_id = @V@\n",
        None,
        "AK" "IA" + g.s(9, B32) + "EXAM" "PLE",
    )
    neg(
        "N15",
        "low-entropy api_key",
        "config/blank.yaml",
        "service:\n  @NAME@: @V@\n",
        "api" "_key",
        "x" * 36,
    )
    neg(
        "N16",
        "PEM header named in prose",
        "docs/keys.md",
        "Never commit a file that starts with "
        + DASH5
        + "BEGIN RSA PRIVATE"
        + " KEY"
        + DASH5
        + ".\n",
    )
    neg(
        "N17",
        "SRI integrity hash on a SigNoz page",
        "docs/signoz-page.html",
        '<script src="/signoz/app.js" integrity="sha256-@V@"></script>\n',
        None,
        g.signoz_key(),
    )
    neg("N18", "short status value", "artifacts/run.txt", "TESTS" "_PASS: 120\n")
    neg(
        "N19",
        "header documented with a placeholder",
        "docs/api.md",
        'curl -H "SIGNOZ'
        '-API-KEY: <your-api-key>" http://localhost:8080/api/v1/rules\n',
    )
    neg(
        "N20",
        "GitHub PAT placeholder",
        "ci/placeholder.sh",
        "export @NAME@=@V@\n",
        "GH" "_TOKEN",
        "gh" "p_" + "x" * 36,
    )
    neg(
        "N21",
        "value is a file name",
        "deploy/key-file.yml",
        "      @NAME@: secrets/signoz-api-key.txt\n",
        "SIGNOZ" "_API_KEY",
    )
    neg(
        "N22",
        "elided PEM example",
        "docs/github-app.md",
        "```\n"
        + DASH5
        + "BEGIN RSA PRIVATE"
        + " KEY"
        + DASH5
        + "\nMIIEpAIBAAKCAQEA"
        + g.s(24)
        + "...\n...\n"
        + DASH5
        + "END RSA PRIVATE"
        + " KEY"
        + DASH5
        + "\n```\n",
    )
    neg(
        "N23",
        "list of secret names",
        "docs/pipeline.md",
        "**Configuration**: AZURE_CLIENT_ID, AZURE_CLIENT"
        "_SECRET, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID configured\n",
    )
    neg(
        "N24",
        "CI service-container default password",
        "ci/services.yml",
        "    services:\n      postgres:\n        env:\n          @NAME@: postgres\n",
        "POSTGRES" "_PASSWORD",
    )
    neg(
        "N25",
        "PowerShell references, not literals",
        "scripts/read-token.ps1",
        "$@NAME@ = $env:SIGNOZ"
        '_API_TOKEN\n$tokenUrl = "http://localhost:8080/api/v1/token"\n',
        "Api" "Token",
    )
    neg(
        "N26",
        "token-named string, then an identifier",
        "web/http.js",
        'const csrf = {cookie: "XSRF-TOKEN", header: ["X-XSRF-TOKEN", xsrfHeaderName]};\n',
    )
    return cases


def run_gitleaks(binary, config, source, report, redact):
    cmd = [
        binary,
        "dir",
        source,
        "--no-banner",
        "--config",
        config,
        "--report-format",
        "json",
        "--report-path",
        report,
        "--exit-code",
        "0",
        "--max-decode-depth",
        "0",
        # Hermetic: no .gitleaksignore from the checkout may mask a fixture.
        "--gitleaks-ignore-path",
        os.path.join(source, ".no-gitleaksignore"),
    ]
    if redact:
        cmd.append("--redact")
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0 or not os.path.exists(report):
        sys.stderr.write(proc.stdout + proc.stderr)
        raise RuntimeError(f"gitleaks exited {proc.returncode}")
    with open(report, encoding="utf-8") as fh:
        text = fh.read()
    return (json.loads(text) if text.strip() else []), text


def sha8(value):
    return hashlib.sha256(value.encode()).hexdigest()[:8]


def md(text):
    """Escape a table cell for the GitHub job summary (class names hold * _ $ | and <)."""
    for ch in "\\`*_|<>[]":
        text = text.replace(ch, "\\" + ch)
    return text


def config_problems(path):
    """Structural rules the fixtures alone would only report as 'missed':
    a repeated [[rules]] id replaces the earlier rule instead of extending it, and a custom
    regex with more than one group, or no explicit secretGroup = 1, can make the key name
    the secret (the pre-2026-11-04 failure)."""
    try:
        import re
        import tomllib
    except ImportError:  # Python < 3.11: the fixtures still run
        return ["(structural check skipped: needs Python 3.11+ tomllib)"], False
    with open(path, "rb") as fh:
        rules = tomllib.load(fh).get("rules", [])
    problems, seen = [], set()
    for rule in rules:
        rid = rule.get("id", "?")
        if rid in seen:
            problems.append(
                f"rule id {rid} appears twice; the second block replaces the first"
            )
        seen.add(rid)
        if "regex" in rule:
            try:
                groups = re.compile(rule["regex"]).groups
            except re.error:
                continue  # RE2-only syntax; gitleaks itself validates the regex
            if groups != 1 or rule.get("secretGroup") != 1:
                problems.append(
                    f"rule {rid}: {groups} capture groups, secretGroup "
                    f"{rule.get('secretGroup', 'unset')} (want exactly 1 and 1)"
                )
    return problems, bool(problems)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--config", default=".gitleaks.toml")
    ap.add_argument("--gitleaks", default="gitleaks")
    ap.add_argument("--seed", type=int, default=20261104)
    ap.add_argument("--keep", help="write fixtures and reports here and keep them")
    ap.add_argument(
        "--summary-json", help="write the per-case results (no values) here"
    )
    args = ap.parse_args()

    config = os.path.abspath(args.config)
    if not os.path.isfile(config):
        print(f"::error::config not found: {args.config}")
        return 2
    work = (
        os.path.abspath(args.keep)
        if args.keep
        else tempfile.mkdtemp(prefix="gitleaks-fixtures-")
    )
    src = os.path.join(work, "src")
    shutil.rmtree(src, ignore_errors=True)
    os.makedirs(src)
    try:
        cases = build_cases(Gen(args.seed))
        for cid, _klass, _kind, _rule, path, text, _value in cases:
            full = os.path.join(src, cid + "-" + path.replace("/", "-"))
            with open(full, "w", encoding="utf-8", newline="\n") as fh:
                fh.write(text)
        try:
            plain, _ = run_gitleaks(
                args.gitleaks, config, src, os.path.join(work, "plain.json"), False
            )
            _, redacted_text = run_gitleaks(
                args.gitleaks, config, src, os.path.join(work, "redacted.json"), True
            )
        except (OSError, RuntimeError) as exc:
            print(f"::error::gitleaks could not run: {exc}")
            return 2

        by_file = {}
        for f in plain:
            by_file.setdefault(os.path.basename(f["File"]), []).append(f)
        results, failed = [], 0
        for cid, klass, kind, rule, path, _text, value in cases:
            name = cid + "-" + path.replace("/", "-")
            found = by_file.pop(name, [])
            got = sorted(f["RuleID"] for f in found)
            if kind == "positive":
                ok = (
                    len(found) == 1
                    and found[0]["RuleID"] == rule
                    and found[0]["Secret"] == value
                )
                why = (
                    ""
                    if ok
                    else (
                        "missed"
                        if not found
                        else (
                            f"{len(found)} findings"
                            if len(found) > 1
                            else (
                                f"rule {got[0]}"
                                if found[0]["RuleID"] != rule
                                else f"secret is {len(found[0]['Secret'])} chars, planted {len(value)} (wrong group)"
                            )
                        )
                    )
                )
                ref = f"len={len(value)} sha8={sha8(value)}"
            else:
                ok = not found
                why = "" if ok else "reported: " + ", ".join(got)
                ref = "-"
            failed += 0 if ok else 1
            results.append(
                {
                    "id": cid,
                    "class": klass,
                    "kind": kind,
                    "expected": rule or "none",
                    "got": got,
                    "ok": ok,
                    "why": why,
                    "fixture": path,
                    "value": ref,
                }
            )
        stray = sum(len(v) for v in by_file.values())
        planted = [c[6] for c in cases if c[6]]
        leaked = sum(1 for v in planted if v in redacted_text)
        problems, structural_fail = config_problems(config)

        print(f"{'case':4}  {'result':6}  {'expected rule':28}  {'class':44}  value")
        for r in results:
            print(
                f"{r['id']:4}  {'PASS' if r['ok'] else 'FAIL':6}  {r['expected']:28}  {r['class']:44}  "
                f"{r['value']}{'  <- ' + r['why'] if r['why'] else ''}"
            )
        print(
            f"redacted report: {leaked} of {len(planted)} planted values present "
            f"({'PASS' if leaked == 0 else 'FAIL'})"
        )
        if stray:
            print(f"unexpected findings outside the case files: {stray} (FAIL)")
        for p in problems:
            print(f"config: {p}{' (FAIL)' if structural_fail else ''}")
        pos_ok = sum(1 for r in results if r["kind"] == "positive" and r["ok"])
        neg_ok = sum(1 for r in results if r["kind"] == "negative" and r["ok"])
        n_pos = sum(1 for r in results if r["kind"] == "positive")
        n_neg = len(results) - n_pos
        total_fail = (
            failed
            + (1 if leaked else 0)
            + (1 if stray else 0)
            + (1 if structural_fail else 0)
        )
        verdict = "PASS" if total_fail == 0 else "FAIL"
        print(
            f"{verdict}: positives caught {pos_ok}/{n_pos}, negatives clean {neg_ok}/{n_neg}, "
            f"redaction {'ok' if leaked == 0 else 'LEAKS'}, config structure "
            f"{'FAIL' if structural_fail else 'ok'}; config {os.path.relpath(config)}; seed {args.seed}"
        )

        summary = {
            "verdict": verdict,
            "positives": [pos_ok, n_pos],
            "negatives": [neg_ok, n_neg],
            "redacted_values_present": leaked,
            "stray_findings": stray,
            "config_problems": problems if structural_fail else [],
            "seed": args.seed,
            "config": os.path.relpath(config),
            "cases": results,
        }
        if args.summary_json:
            with open(args.summary_json, "w", encoding="utf-8") as fh:
                json.dump(summary, fh, indent=2)
                fh.write("\n")
        step_summary = os.environ.get("GITHUB_STEP_SUMMARY")
        if step_summary:
            with open(step_summary, "a", encoding="utf-8") as fh:
                fh.write(f"### Gitleaks fixtures: {verdict}\n\n")
                fh.write(
                    f"Positives caught **{pos_ok}/{n_pos}**, negatives clean **{neg_ok}/{n_neg}**, "
                    f"planted values in the --redact report: **{leaked}**. Synthetic values only "
                    f"(seed {args.seed}); referenced by length and sha256[:8].\n\n"
                )
                fh.write(
                    "| Case | Result | Class | Expected rule | Reported |\n|---|---|---|---|---|\n"
                )
                for r in results:
                    fh.write(
                        f"| {r['id']} | {'✅' if r['ok'] else '❌'} | {md(r['class'])} | {r['expected']} | "
                        f"{', '.join(r['got']) or '—'}{' — ' + md(r['why']) if r['why'] else ''} |\n"
                    )
                fh.write("\n")
        return 0 if total_fail == 0 else 1
    finally:
        if not args.keep:
            shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
