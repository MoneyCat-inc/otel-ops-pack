# ANTIclickbait Transparency Hub

Static documentation bundle that publishes an evidence-first status board for the Resonai [OTel] project. The hub lists each major feature, the claims we make about it, links to primary evidence, and the limitations that still apply.

## Folder Layout

```
docs/anticlickbait/
├── index.html   # Homepage and scoring overview
├── style.css    # Comfort Cat derived styling
├── app.js       # Client-side renderer for cards and filters
├── data.json    # Source of truth for cards, scores, and metadata
├── schema.json  # JSON schema for data.json
└── assets/      # Reserved for screenshots or supporting media
```

## Data Model

`data.json` follows the schema described in `schema.json`. Each card requires:

- `id`: stable identifier (string)
- `title`: short name for the capability
- `category`: grouping used by the filter dropdown
- `score`: integer 0-100 (evidence quality)
- `claims`: array of one or more statements
- `evidence`: prose summary of supporting proof
- `limitations`: honest disclosure of gaps or caveats
- `sources`: array of URLs or plain-text references

The `metadata` block also stores the published version, update date, and total card count.

## Updating the Hub

1. Edit `data.json` to add or revise cards.
2. Run the lane check: `pnpm run anticlickbait:verify`.
3. Open `docs/anticlickbait/index.html` in a browser to confirm layout and filtering.
4. Capture any new evidence assets in `docs/anticlickbait/assets/`.
5. Commit changes with an ECRR report that links back to the updated evidence.

## Lane Budget

- Code files (HTML/CSS/JS): ≤10 total, ≤200 non-empty lines combined.
- Current usage after formatting: 3 files, 166 non-empty lines.
- Data and documentation files are excluded from the LOC budget but should remain concise.

## Pending Work

Funding support for the project is outside the scope of this bundle. See `BOSSCAT_ANTICLICKBAIT_DECISION_REQUIRED.md` for the decision log that tracks donation placement and messaging.
