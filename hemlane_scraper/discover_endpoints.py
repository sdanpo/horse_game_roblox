"""
Hemlane Endpoint Discovery Tool
================================
If the main scraper can't find data, run this first.
It logs in and probes common API patterns to find what endpoints exist
on your specific Hemlane instance.

Usage:
    python discover_endpoints.py --email you@example.com --password yourpass
"""

import argparse
import json
import logging
import sys
import time

import requests

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger(__name__)

BASE_URL = "https://api.hemlane.com"

AUTH_PATHS = [
    "/v1/auth/login",
    "/v1/auth/authenticate",
    "/v1/authenticate",
    "/authenticate",
    "/login",
    "/api/login",
    "/api/v1/auth/login",
    "/api/v1/login",
]

PROBE_PATHS = [
    # Properties
    "/v1/properties",
    "/v1/property",
    "/api/v1/properties",
    "/properties",
    # Units
    "/v1/units",
    "/v1/unit",
    "/units",
    # Tenants
    "/v1/tenants",
    "/v1/tenant",
    "/tenants",
    # Leases
    "/v1/leases",
    "/v1/lease",
    "/leases",
    # Transactions / Payments
    "/v1/transactions",
    "/v1/payments",
    "/v1/financials",
    "/v1/ledger",
    "/transactions",
    # Maintenance
    "/v1/maintenance-requests",
    "/v1/maintenance_requests",
    "/v1/maintenance",
    "/v1/maintenanceRequests",
    "/maintenance",
    # People
    "/v1/owners",
    "/v1/contacts",
    "/v1/users",
    "/v1/users/me",
    "/v1/profile",
    "/owners",
    "/contacts",
    # Listings
    "/v1/listings",
    "/listings",
    # Docs
    "/v1/documents",
    "/documents",
    # Tasks
    "/v1/tasks",
    "/tasks",
    # Messages
    "/v1/messages",
    "/v1/conversations",
    # Misc
    "/v1/reports",
    "/v1/invoices",
    "/v1/charges",
    "/v1/ledger-entries",
    "/v1/rent-rolls",
]


def try_login(session: requests.Session, email: str, password: str) -> str | None:
    payload = {"email": email, "password": password}
    for path in AUTH_PATHS:
        url  = BASE_URL + path
        resp = session.post(url, json=payload)
        log.debug("POST %s → %s", path, resp.status_code)
        if resp.ok:
            log.info("✓ Login succeeded via %s", path)
            data  = resp.json()
            token = (data.get("token") or data.get("access_token")
                     or data.get("accessToken") or data.get("jwt"))
            if not token and isinstance(data.get("data"), dict):
                token = data["data"].get("token") or data["data"].get("access_token")
            if token:
                log.info("  Token type: %s…", token[:20])
            return token
        if resp.status_code not in (404, 405, 401, 400):
            log.warning("  Unexpected status %s at %s: %s",
                        resp.status_code, path, resp.text[:200])
    return None


def probe_endpoints(session: requests.Session) -> list[str]:
    found = []
    for path in PROBE_PATHS:
        url  = BASE_URL + path
        resp = session.get(url, params={"limit": 1, "page": 1})
        if resp.status_code == 200:
            try:
                data = resp.json()
                count = len(data) if isinstance(data, list) else "?"
                log.info("✓ %s  [%s records on first page]", path, count)
                found.append(path)
            except Exception:
                log.info("✓ %s  [non-JSON response]", path)
                found.append(path)
        elif resp.status_code == 401:
            log.warning("✗ %s  [401 Unauthorized]", path)
        elif resp.status_code == 403:
            log.warning("○ %s  [403 Forbidden — endpoint exists but no access]", path)
        elif resp.status_code == 404:
            pass  # endpoint doesn't exist, don't log
        else:
            log.debug("  %s → %s", path, resp.status_code)
        time.sleep(0.1)
    return found


def main():
    p = argparse.ArgumentParser(description="Discover Hemlane API endpoints")
    p.add_argument("--email",    required=True)
    p.add_argument("--password", required=True)
    p.add_argument("--debug",    action="store_true")
    args = p.parse_args()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)

    session = requests.Session()
    session.headers.update({
        "Accept":       "application/json",
        "Content-Type": "application/json",
        "User-Agent":   "Mozilla/5.0",
        "Origin":       "https://app.hemlane.com",
        "Referer":      "https://app.hemlane.com/",
    })

    token = try_login(session, args.email, args.password)
    if not token:
        log.error("Login failed on all attempted paths. Check credentials.")
        sys.exit(1)

    session.headers.update({"Authorization": f"Bearer {token}"})

    log.info("\nProbing %d endpoints …\n", len(PROBE_PATHS))
    found = probe_endpoints(session)

    log.info("\n%s", "=" * 60)
    log.info("DISCOVERED ENDPOINTS (%d):", len(found))
    for p in found:
        log.info("  %s", p)

    # Write to file for reference
    with open("discovered_endpoints.json", "w") as f:
        json.dump(found, f, indent=2)
    log.info("\nSaved to discovered_endpoints.json")


if __name__ == "__main__":
    main()
