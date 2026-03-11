# Hemlane → ERPNext Migration

Scrapes all data from Hemlane (using the same internal API the web app uses) and produces ERPNext-ready CSV import files.

## Files

| File | Purpose |
|---|---|
| `hemlane_scraper.py` | Authenticates + exports all Hemlane data to JSON/CSV |
| `erpnext_mapper.py` | Transforms raw export into ERPNext import CSVs |
| `discover_endpoints.py` | Probes API to find working endpoints (run first if scraper fails) |
| `requirements.txt` | Python dependencies |

## Quick Start

```bash
pip install -r requirements.txt

# Step 1: Scrape Hemlane
python hemlane_scraper.py \
  --email you@example.com \
  --password yourpassword \
  --output ./hemlane_export

# Step 2: Map to ERPNext format
python erpnext_mapper.py \
  --input ./hemlane_export \
  --output ./erpnext_import \
  --company "Your Company Name"
```

## Output

### `hemlane_export/` — raw data from Hemlane
```
properties.json / properties.csv
units.json / units.csv
tenants.json / tenants.csv
leases.json / leases.csv
transactions.json / transactions.csv
maintenance.json / maintenance.csv
owners.json / owners.csv
contacts.json / contacts.csv
listings.json / listings.csv
documents.json / documents.csv
summary.json
```

### `erpnext_import/` — ready to import into ERPNext
```
customer.csv          ← Tenants
supplier.csv          ← Property owners
contact.csv           ← All contacts
address.csv           ← Property addresses
item.csv              ← Properties + units (as fixed assets)
sales_invoice.csv     ← Rent charges
payment_entry.csv     ← Received payments
maintenance_issue.csv ← Maintenance requests
IMPORT_ORDER.txt      ← Step-by-step import guide
```

## ERPNext Import Steps

1. Open ERPNext → **Settings → Data Import**
2. Click **New Data Import**
3. For each CSV, in this order:
   1. `customer.csv` — DocType: **Customer**
   2. `supplier.csv` — DocType: **Supplier**
   3. `contact.csv` — DocType: **Contact**
   4. `address.csv` — DocType: **Address**
   5. `item.csv` — DocType: **Item**
   6. `sales_invoice.csv` — DocType: **Sales Invoice**
   7. `payment_entry.csv` — DocType: **Payment Entry**
   8. `maintenance_issue.csv` — DocType: **Maintenance Visit**

## Troubleshooting

### "Login failed on all attempted paths"
Hemlane uses the same email/password as `app.hemlane.com`. Double-check credentials.

### Some entities have 0 records
Run the endpoint discovery tool to see what endpoints are active on your account:
```bash
python discover_endpoints.py --email you@example.com --password yourpass
```
This saves `discovered_endpoints.json` — update `ENDPOINTS` in `hemlane_scraper.py` accordingly.

### API returns 403
Hemlane's API access may require a Premier plan. If blocked, use browser automation:
- Install Playwright: `pip install playwright && playwright install chromium`
- The scraper can be adapted to use Playwright for cookie-based auth

### Need to use Apify
If your Hemlane account blocks API access, Apify can handle browser-based scraping.
Set your Apify token in the environment:
```bash
export APIFY_TOKEN=your_apify_token
```
Then run with `--use-apify` flag (to be implemented with your specific Apify actor config).
