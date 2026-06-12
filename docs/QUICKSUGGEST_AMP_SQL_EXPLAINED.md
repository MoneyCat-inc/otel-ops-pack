# Understanding `quicksuggest-amp.sql`

This file is Firefox’s **local SQLite database** for the **Quick Suggest (AMP)** Remote Settings collection. It stores everything Firefox has downloaded from Mozilla’s servers for address-bar suggestions and sponsored suggestions.

---

## What it is

- **Path:**  
  `C:\Users\fubum\AppData\Local\Mozilla\Firefox\Profiles\fyoi34av.default-release\remote-settings\quicksuggest-amp.sql`
- **Format:** SQLite 3 database (~944 MB on disk).
- **Purpose:** Cache for the **quicksuggest-amp** Remote Settings collection: the data that powers **Quick Suggest** in the address bar (suggested sites and sponsored suggestions, including “AMP” / ad-sponsored suggestions).

Firefox fetches this collection from:

`https://firefox.settings.services.mozilla.com/v1/buckets/main/collections/quicksuggest-amp`

and stores it in this SQLite file so it can use it offline and avoid re-downloading on every startup.

---

## Schema (3 tables)

### 1. `collection_metadata` (1 row)

Describes the collection itself:

- **collection_url** – Remote Settings URL for `quicksuggest-amp`.
- **last_modified** – Timestamp (ms) when the collection was last updated (e.g. `1769884198498`).
- **bucket** – `"main"`.
- **signature**, **x5u** – Crypto material so Firefox can verify the data came from Mozilla.

So this table answers: “Which collection is this, when was it last updated, and how do we verify it?”

---

### 2. `records` (177 rows)

Each row is **one record** in the Remote Settings sense: a small JSON blob that describes *what* to show and *where* the real payload lives.

- **id** – Record ID. You’ll see:
  - **icon-*** (hash or number) – Icons (e.g. favicons) for suggestions.
  - **sponsored-suggestions-{country}-{form_factor}** – e.g. `sponsored-suggestions-pl-phone`, `sponsored-suggestions-us-desktop`. One record per locale/device type.
- **collection_url** – Same collection URL as above.
- **data** – BLOB: JSON for that record.

**Example `data` (one record):**

```json
{
  "id": "sponsored-suggestions-pl-phone",
  "last_modified": 1748541659623,
  "deleted": false,
  "attachment": {
    "filename": "sponsored-suggestions-pl-phone.json",
    "mimetype": "application/json",
    "location": "main-workspace/quicksuggest-amp/90d2e045-f14b-423d-950c-f80954fd3164.json",
    "hash": "...",
    "size": 1897
  },
  "type": "amp",
  "schema": 1748541656595,
  "country": "PL",
  "form_factor": "phone",
  "filter_expression": "env.country == 'PL' && env.formFactor == 'phone'"
}
```

So **records** are the index: “For country X and form factor Y, the actual suggestion list is in the attachment at this `location`.” The real bulk data is in **attachments**.

---

### 3. `attachments` (268 rows) — where the size comes from

Each row is **one attachment**: the actual file (JSON, image, etc.) that a record points to.

- **id** – Path-like ID, e.g. `main-workspace/quicksuggest-amp/5abd0323-9a8d-46e0-879f-de89c3407bb5.json`.
- **collection_url** – Same collection URL.
- **data** – BLOB: the full file content (JSON text or image bytes).

**Breakdown of your 268 attachments:**

| Type   | Count | Role |
|--------|-------|------|
| **.json** | 104 | Suggestion lists (per country/form factor). One JSON = one big array of suggestions/ads. |
| **.jpg**  | 90  | Icons/images for suggestions. |
| **.png**  | 74  | Icons/images for suggestions. |

The **large** attachments are the **.json** files. One of them (for one locale/segment) can be ~14 MB. That JSON is a **single array of thousands of suggestion objects** (one per ad/suggestion).

**Example: one item inside a large JSON array**

The big JSON files are **root = array** of suggestion objects. Each object looks conceptually like:

```json
{
  "advertiser": "Amazon",
  "click_url": "https://bridge.pdx1.admarketplace.net/ctp?...",
  "full_keywords": [["amazon", 4]],
  "iab_category": "22 - Shopping",
  "serp_categories": "...",
  "icon": "...",
  "id": "...",
  "impression_url": "...",
  "keywords": "...",
  "score": ...,
  "title": "...",
  "url": "..."
}
```

So:

- **records** = “Use this attachment for country X, phone/desktop.”
- **attachments** = The actual files: either **big JSON arrays** (one array per locale/segment, each with thousands of `advertiser`/`click_url`/`title`/`url`/… entries) or **images** (icons).

---

## Why the file is ~1 GB

- **records:** 177 rows, total `data` size is tiny (~81 KB). They’re just metadata + pointer to an attachment.
- **attachments:** 268 rows, total `data` ~1 GB:
  - **104 JSON files** – Many are multi‑MB each (one sampled file has **6,935 items** in a single array). So you have many locales/segments × large arrays of suggestions/ads.
  - **90 JPG + 74 PNG** – Icon/image blobs; smaller than the JSON but still add up.

So the size is **by design**: Firefox is storing the full Quick Suggest/AMP catalog (all locales and form factors) plus all referenced icons. The fact that it’s ~1 GB means Mozilla is shipping a large catalog and your client is caching it all in this one SQLite file.

---

## How Firefox uses it

1. **Remote Settings** client in Firefox periodically (or on demand) fetches the **quicksuggest-amp** collection from Mozilla.
2. Server sends **records** (the index) and **attachments** (the JSON lists and images).
3. Firefox stores them in **quicksuggest-amp.sql** (this file).
4. When you type in the **address bar**, Firefox:
   - Uses your locale and device type (e.g. US, desktop).
   - Finds the matching **records** (e.g. `sponsored-suggestions-us-desktop`).
   - Loads the **attachment** (the big JSON) for that record.
   - Filters/search that list by keywords and shows **Quick Suggest** / sponsored suggestions.

So this file is the **local mirror** of the Quick Suggest/AMP dataset that powers those address-bar suggestions.

---

## Summary

| Piece | What it is |
|-------|------------|
| **File** | SQLite DB for the **quicksuggest-amp** Remote Settings collection. |
| **collection_metadata** | Who/what/when: collection URL, last modified, verification (signature, x5u). |
| **records** | Index: 177 entries (icons + one “sponsored-suggestions-{country}-{form_factor}” per segment), each pointing to an attachment. |
| **attachments** | 268 blobs: 104 big JSON arrays (suggestion lists), 90 JPG, 74 PNG (icons). |
| **Big JSONs** | Root = array of thousands of objects; each object = one ad/suggestion (advertiser, click_url, title, url, keywords, icon, etc.). |
| **Why ~1 GB** | Full cached catalog: many locales × large suggestion arrays + all icons. |

If you want to re-inspect it yourself, you can use the script:

`c:\otel\scripts\inspect_quicksuggest.py`

It prints schema, sample records, and a sample suggestion object from a large JSON attachment.
