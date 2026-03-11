"""
Hemlane API Scraper
====================
Authenticates against the internal Hemlane API (same API the web app uses)
and exports all data to JSON + CSV files for ERPNext import.

Usage:
    python hemlane_scraper.py --email you@example.com --password yourpass
    python hemlane_scraper.py --email you@example.com --password yourpass --output ./export

What gets exported:
    - properties.json / properties.csv
    - units.json / units.csv
    - tenants.json / tenants.csv
    - leases.json / leases.csv
    - transactions.json / transactions.csv
    - maintenance.json / maintenance.csv
    - owners.json / owners.csv
    - contacts.json / contacts.csv
"""

import argparse
import csv
import json
import logging
import os
import sys
import time
from pathlib import Path
from typing import Any, Optional

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# ─── Logging ────────────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger(__name__)

# ─── Constants ───────────────────────────────────────────────────────────────

BASE_URL = "https://api.hemlane.com"
APP_URL  = "https://app.hemlane.com"

ENDPOINTS = {
    "auth_login":        "/v1/auth/login",
    "auth_refresh":      "/v1/auth/token/refresh",
    "profile":           "/v1/users/me",
    "properties":        "/v1/properties",
    "units":             "/v1/units",
    "tenants":           "/v1/tenants",
    "leases":            "/v1/leases",
    "transactions":      "/v1/transactions",
    "maintenance":       "/v1/maintenance-requests",
    "owners":            "/v1/owners",
    "contacts":          "/v1/contacts",
    "listings":          "/v1/listings",
    "documents":         "/v1/documents",
    "tasks":             "/v1/tasks",
    "messages":          "/v1/messages",
}

DEFAULT_PAGE_SIZE = 100
MAX_RETRIES       = 4
BACKOFF_FACTOR    = 1.5


# ─── Session / Auth ──────────────────────────────────────────────────────────

class HemlaneClient:
    """Authenticated HTTP client for the Hemlane internal API."""

    def __init__(self, email: str, password: str):
        self.email    = email
        self.password = password
        self.session  = self._build_session()
        self.token: Optional[str] = None
        self.refresh_token: Optional[str] = None
        self.user_id: Optional[str] = None
        self.company_id: Optional[str] = None

    # ── HTTP ──────────────────────────────────────────────────────────────

    def _build_session(self) -> requests.Session:
        s = requests.Session()
        retry = Retry(
            total=MAX_RETRIES,
            backoff_factor=BACKOFF_FACTOR,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["HEAD", "GET", "POST"],
        )
        adapter = HTTPAdapter(max_retries=retry)
        s.mount("https://", adapter)
        s.mount("http://",  adapter)
        s.headers.update({
            "Accept":       "application/json",
            "Content-Type": "application/json",
            "User-Agent":   "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                            "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Origin":       APP_URL,
            "Referer":      APP_URL + "/",
        })
        return s

    def _set_auth_header(self):
        if self.token:
            self.session.headers.update({"Authorization": f"Bearer {self.token}"})

    def _url(self, path: str) -> str:
        return BASE_URL + path

    # ── Auth ──────────────────────────────────────────────────────────────

    def login(self):
        """Authenticate and store JWT tokens."""
        log.info("Authenticating as %s …", self.email)
        payload = {"email": self.email, "password": self.password}

        # Try standard bearer-token login
        resp = self.session.post(self._url(ENDPOINTS["auth_login"]), json=payload)

        if not resp.ok:
            # Fallback: some versions use /v1/auth/authenticate or /authenticate
            for alt in ["/v1/auth/authenticate", "/authenticate", "/login"]:
                resp = self.session.post(self._url(alt), json=payload)
                if resp.ok:
                    break

        if not resp.ok:
            log.error("Login failed: HTTP %s — %s", resp.status_code, resp.text[:400])
            raise SystemExit(1)

        data = resp.json()
        # Token field name varies — try common patterns
        self.token         = (data.get("token")
                              or data.get("access_token")
                              or data.get("accessToken")
                              or data.get("jwt"))
        self.refresh_token = (data.get("refresh_token")
                              or data.get("refreshToken"))

        # Some versions nest inside data/user/etc.
        if not self.token and isinstance(data.get("data"), dict):
            nested = data["data"]
            self.token         = nested.get("token") or nested.get("access_token")
            self.refresh_token = nested.get("refresh_token")

        if not self.token:
            log.error("Could not find token in response: %s", json.dumps(data, indent=2)[:600])
            raise SystemExit(1)

        self._set_auth_header()

        # Extract user/company IDs from token response
        user_data = data.get("user") or data.get("data", {})
        if isinstance(user_data, dict):
            self.user_id    = user_data.get("id") or user_data.get("userId")
            self.company_id = user_data.get("companyId") or user_data.get("company_id")

        log.info("Login successful. User ID: %s | Company ID: %s", self.user_id, self.company_id)

    # ── Paginated GET ─────────────────────────────────────────────────────

    def get_all(
        self,
        path: str,
        params: Optional[dict] = None,
        page_size: int = DEFAULT_PAGE_SIZE,
    ) -> list[dict]:
        """
        Fetch every page of a paginated endpoint and return the combined list.
        Handles cursor-based, offset-based, and page-number pagination.
        """
        params = params or {}
        params.setdefault("limit",    page_size)
        params.setdefault("per_page", page_size)
        params.setdefault("pageSize", page_size)

        all_records: list[dict] = []
        page       = 1
        offset     = 0
        cursor     = None

        while True:
            p = dict(params)
            p["page"]   = page
            p["offset"] = offset
            if cursor:
                p["cursor"] = cursor

            resp = self.session.get(self._url(path), params=p)

            if resp.status_code == 404:
                log.warning("Endpoint %s not found (404) — skipping", path)
                return []

            if resp.status_code == 401:
                log.info("Token expired — refreshing …")
                self._refresh()
                resp = self.session.get(self._url(path), params=p)

            if not resp.ok:
                log.warning("GET %s page %d failed: HTTP %s — %s",
                            path, page, resp.status_code, resp.text[:300])
                break

            data = resp.json()

            # Unwrap common response shapes
            records = (
                data if isinstance(data, list)
                else data.get("data")
                or data.get("results")
                or data.get("items")
                or data.get("records")
                or []
            )

            if not records:
                break

            all_records.extend(records)
            log.info("  fetched %d records (running total: %d)", len(records), len(all_records))

            # Determine next page
            total = (data.get("total") or data.get("totalCount")
                     or data.get("total_count") if isinstance(data, dict) else None)
            if total and len(all_records) >= total:
                break

            # Cursor pagination
            cursor = (data.get("nextCursor") or data.get("next_cursor")
                      if isinstance(data, dict) else None)

            # If we got fewer records than the page size, we're done
            if len(records) < page_size:
                break

            page   += 1
            offset += page_size

            # Be polite
            time.sleep(0.3)

        return all_records

    def get(self, path: str, params: Optional[dict] = None) -> dict | list:
        resp = self.session.get(self._url(path), params=params)
        if resp.status_code == 401:
            self._refresh()
            resp = self.session.get(self._url(path), params=params)
        resp.raise_for_status()
        return resp.json()

    def _refresh(self):
        if not self.refresh_token:
            log.warning("No refresh token — re-logging in")
            self.login()
            return
        resp = self.session.post(
            self._url(ENDPOINTS["auth_refresh"]),
            json={"refresh_token": self.refresh_token},
        )
        if resp.ok:
            self.token = resp.json().get("token") or resp.json().get("access_token")
            self._set_auth_header()
        else:
            self.login()


# ─── Scraper ─────────────────────────────────────────────────────────────────

class HemlaneScraper:
    def __init__(self, client: HemlaneClient, output_dir: Path):
        self.client     = client
        self.output_dir = output_dir
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.data: dict[str, list[dict]] = {}

    # ── Fetch All Data ────────────────────────────────────────────────────

    def fetch_all(self):
        self.client.login()

        # Fetch profile first to confirm auth works
        try:
            profile = self.client.get(ENDPOINTS["profile"])
            log.info("Profile OK: %s", profile.get("email") or profile.get("name"))
        except Exception as e:
            log.warning("Could not fetch profile: %s", e)

        tasks = [
            ("properties",   ENDPOINTS["properties"]),
            ("units",        ENDPOINTS["units"]),
            ("tenants",      ENDPOINTS["tenants"]),
            ("leases",       ENDPOINTS["leases"]),
            ("transactions", ENDPOINTS["transactions"]),
            ("maintenance",  ENDPOINTS["maintenance"]),
            ("owners",       ENDPOINTS["owners"]),
            ("contacts",     ENDPOINTS["contacts"]),
            ("listings",     ENDPOINTS["listings"]),
            ("documents",    ENDPOINTS["documents"]),
            ("tasks",        ENDPOINTS["tasks"]),
        ]

        for name, endpoint in tasks:
            log.info("Fetching %s …", name)
            try:
                records = self.client.get_all(endpoint)
                self.data[name] = records
                log.info("  → %d %s", len(records), name)
            except Exception as e:
                log.error("  Failed to fetch %s: %s", name, e)
                self.data[name] = []

        # Enrich: fetch units per property if top-level /units is empty
        if not self.data.get("units") and self.data.get("properties"):
            self._fetch_units_per_property()

        # Enrich: fetch leases per unit if top-level /leases is empty
        if not self.data.get("leases") and self.data.get("units"):
            self._fetch_leases_per_unit()

        # Enrich: fetch transactions per lease if top-level /transactions is empty
        if not self.data.get("transactions") and self.data.get("leases"):
            self._fetch_transactions_per_lease()

    def _fetch_units_per_property(self):
        log.info("Fetching units per property …")
        all_units = []
        for prop in self.data["properties"]:
            pid = prop.get("id") or prop.get("propertyId")
            units = self.client.get_all(f"/v1/properties/{pid}/units")
            for u in units:
                u.setdefault("propertyId", pid)
            all_units.extend(units)
        self.data["units"] = all_units
        log.info("  → %d units", len(all_units))

    def _fetch_leases_per_unit(self):
        log.info("Fetching leases per unit …")
        all_leases = []
        for unit in self.data["units"]:
            uid = unit.get("id") or unit.get("unitId")
            leases = self.client.get_all(f"/v1/units/{uid}/leases")
            for l in leases:
                l.setdefault("unitId", uid)
            all_leases.extend(leases)
        self.data["leases"] = all_leases
        log.info("  → %d leases", len(all_leases))

    def _fetch_transactions_per_lease(self):
        log.info("Fetching transactions per lease …")
        all_txns = []
        for lease in self.data["leases"]:
            lid = lease.get("id") or lease.get("leaseId")
            txns = self.client.get_all(f"/v1/leases/{lid}/transactions")
            for t in txns:
                t.setdefault("leaseId", lid)
            all_txns.extend(txns)
        self.data["transactions"] = all_txns
        log.info("  → %d transactions", len(all_txns))

    # ── Export ────────────────────────────────────────────────────────────

    def export(self):
        log.info("Exporting data to %s …", self.output_dir)
        summary = {}

        for name, records in self.data.items():
            if not records:
                continue
            self._write_json(name, records)
            self._write_csv(name, records)
            summary[name] = len(records)

        # Write summary
        summary_path = self.output_dir / "summary.json"
        summary_path.write_text(json.dumps(summary, indent=2))

        log.info("─" * 50)
        log.info("Export complete:")
        for k, v in summary.items():
            log.info("  %-20s %d records", k, v)
        log.info("Output directory: %s", self.output_dir.resolve())

    def _write_json(self, name: str, records: list[dict]):
        path = self.output_dir / f"{name}.json"
        path.write_text(json.dumps(records, indent=2, default=str))
        log.info("  wrote %s", path.name)

    def _write_csv(self, name: str, records: list[dict]):
        if not records:
            return
        path = self.output_dir / f"{name}.csv"

        # Flatten nested dicts one level deep
        flat_records = [_flatten(r) for r in records]
        fieldnames   = _merged_keys(flat_records)

        with open(path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
            writer.writeheader()
            writer.writerows(flat_records)

        log.info("  wrote %s", path.name)


# ─── Helpers ─────────────────────────────────────────────────────────────────

def _flatten(record: dict, prefix: str = "", sep: str = "_") -> dict:
    """Flatten one level of nested dicts; lists become JSON strings."""
    out = {}
    for k, v in record.items():
        key = f"{prefix}{sep}{k}" if prefix else k
        if isinstance(v, dict):
            out.update(_flatten(v, prefix=key, sep=sep))
        elif isinstance(v, list):
            out[key] = json.dumps(v, default=str)
        else:
            out[key] = v
    return out


def _merged_keys(records: list[dict]) -> list[str]:
    """Return a stable, merged list of all keys across records."""
    seen: dict[str, None] = {}
    for r in records:
        for k in r:
            seen[k] = None
    return list(seen.keys())


# ─── CLI ─────────────────────────────────────────────────────────────────────

def parse_args():
    p = argparse.ArgumentParser(
        description="Scrape all data from Hemlane and export to JSON/CSV",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    p.add_argument("--email",    required=True, help="Hemlane login email")
    p.add_argument("--password", required=True, help="Hemlane login password")
    p.add_argument(
        "--output", default="./hemlane_export",
        help="Output directory for exported files (default: ./hemlane_export)",
    )
    p.add_argument("--debug", action="store_true", help="Enable debug logging")
    return p.parse_args()


def main():
    args = parse_args()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)

    client  = HemlaneClient(email=args.email, password=args.password)
    scraper = HemlaneScraper(client=client, output_dir=Path(args.output))

    scraper.fetch_all()
    scraper.export()


if __name__ == "__main__":
    main()
