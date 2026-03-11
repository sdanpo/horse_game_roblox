"""
ERPNext CSV Mapper
===================
Transforms raw Hemlane export data into ERPNext-compatible import CSVs.

Hemlane → ERPNext mapping:
    properties + units  →  Item (asset/property)
    tenants + leases    →  Customer + Rental Contract
    transactions        →  Payment Entry / Sales Invoice
    owners              →  Supplier (or Customer)
    contacts            →  Contact
    maintenance         →  Maintenance Schedule / Issue

Usage:
    python erpnext_mapper.py --input ./hemlane_export --output ./erpnext_import

Then in ERPNext:
    Settings → Data Import → Upload each CSV in this order:
    1. customer.csv
    2. supplier.csv
    3. contact.csv
    4. address.csv
    5. item.csv              (properties/units)
    6. sales_invoice.csv     (rent charges)
    7. payment_entry.csv     (received payments)
    8. maintenance_issue.csv
"""

import csv
import json
import logging
import re
import sys
from pathlib import Path
from typing import Any, Optional

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger(__name__)


# ─── Helpers ─────────────────────────────────────────────────────────────────

def load_json(path: Path) -> list[dict]:
    if not path.exists():
        log.warning("File not found: %s", path)
        return []
    with open(path) as f:
        data = json.load(f)
    return data if isinstance(data, list) else data.get("data", [])


def write_csv(path: Path, fieldnames: list[str], rows: list[dict]):
    if not rows:
        log.warning("No rows to write for %s — skipping", path.name)
        return
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)
    log.info("  wrote %-40s  (%d rows)", path.name, len(rows))


def safe(value: Any, default: str = "") -> str:
    if value is None:
        return default
    s = str(value).strip()
    return s if s not in ("None", "null", "nan") else default


def full_name(*parts) -> str:
    return " ".join(p for p in parts if p and safe(p))


def format_date(value: Any) -> str:
    """Normalize various date formats to YYYY-MM-DD for ERPNext."""
    if not value:
        return ""
    s = str(value).strip()
    # Already ISO
    m = re.match(r"(\d{4}-\d{2}-\d{2})", s)
    if m:
        return m.group(1)
    # MM/DD/YYYY
    m = re.match(r"(\d{1,2})/(\d{1,2})/(\d{4})", s)
    if m:
        return f"{m.group(3)}-{int(m.group(1)):02d}-{int(m.group(2)):02d}"
    return s


def format_currency(value: Any) -> str:
    if value is None or value == "":
        return "0.00"
    try:
        return f"{float(value):.2f}"
    except (ValueError, TypeError):
        return "0.00"


# ─── Mappers ─────────────────────────────────────────────────────────────────

class ERPNextMapper:
    def __init__(self, input_dir: Path, output_dir: Path, company: str = "My Company"):
        self.input_dir  = input_dir
        self.output_dir = output_dir
        self.company    = company
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Load all source data
        self.properties   = load_json(input_dir / "properties.json")
        self.units        = load_json(input_dir / "units.json")
        self.tenants      = load_json(input_dir / "tenants.json")
        self.leases       = load_json(input_dir / "leases.json")
        self.transactions = load_json(input_dir / "transactions.json")
        self.owners       = load_json(input_dir / "owners.json")
        self.contacts     = load_json(input_dir / "contacts.json")
        self.maintenance  = load_json(input_dir / "maintenance.json")

        log.info("Loaded: properties=%d units=%d tenants=%d leases=%d "
                 "transactions=%d owners=%d contacts=%d maintenance=%d",
                 len(self.properties), len(self.units), len(self.tenants),
                 len(self.leases), len(self.transactions), len(self.owners),
                 len(self.contacts), len(self.maintenance))

    # ── Customers (Tenants) ───────────────────────────────────────────────

    def map_customers(self):
        """Tenants → ERPNext Customer"""
        rows = []
        for t in self.tenants:
            first = safe(t.get("firstName") or t.get("first_name"))
            last  = safe(t.get("lastName")  or t.get("last_name"))
            name  = full_name(first, last) or safe(t.get("name") or t.get("fullName"))
            if not name:
                name = f"Tenant-{safe(t.get('id', 'unknown'))}"

            rows.append({
                "Customer Name":     name,
                "Customer Type":     "Individual",
                "Customer Group":    "Tenant",
                "Territory":         "United States",
                "Email Id":          safe(t.get("email")),
                "Mobile No":         safe(t.get("phone") or t.get("mobilePhone") or t.get("cellPhone")),
                "Customer POS Id":   safe(t.get("id")),   # keep Hemlane ID for cross-reference
            })

        write_csv(
            self.output_dir / "customer.csv",
            ["Customer Name", "Customer Type", "Customer Group", "Territory",
             "Email Id", "Mobile No", "Customer POS Id"],
            rows,
        )

    # ── Suppliers (Owners / Vendors) ──────────────────────────────────────

    def map_suppliers(self):
        """Owners/vendors → ERPNext Supplier"""
        rows = []
        for o in self.owners:
            first = safe(o.get("firstName") or o.get("first_name"))
            last  = safe(o.get("lastName")  or o.get("last_name"))
            name  = full_name(first, last) or safe(o.get("name") or o.get("fullName"))
            if not name:
                name = f"Owner-{safe(o.get('id', 'unknown'))}"

            rows.append({
                "Supplier Name":   name,
                "Supplier Type":   "Individual",
                "Supplier Group":  "Property Owner",
                "Email Id":        safe(o.get("email")),
                "Mobile No":       safe(o.get("phone") or o.get("mobilePhone")),
                "Custom Hemlane Id": safe(o.get("id")),
            })

        write_csv(
            self.output_dir / "supplier.csv",
            ["Supplier Name", "Supplier Type", "Supplier Group",
             "Email Id", "Mobile No", "Custom Hemlane Id"],
            rows,
        )

    # ── Contacts ──────────────────────────────────────────────────────────

    def map_contacts(self):
        """Hemlane contacts → ERPNext Contact"""
        rows = []
        sources = self.contacts or []

        # Also add contacts from tenants and owners if contacts list is empty
        if not sources:
            for t in self.tenants:
                sources.append({**t, "_source": "tenant"})
            for o in self.owners:
                sources.append({**o, "_source": "owner"})

        for c in sources:
            first = safe(c.get("firstName") or c.get("first_name"))
            last  = safe(c.get("lastName")  or c.get("last_name"))
            name  = full_name(first, last) or safe(c.get("name") or c.get("fullName"))
            if not name:
                continue

            rows.append({
                "First Name":   first or name,
                "Last Name":    last,
                "Email Id":     safe(c.get("email")),
                "Mobile No":    safe(c.get("phone") or c.get("mobilePhone")),
                "Is Primary Contact": 1,
            })

        write_csv(
            self.output_dir / "contact.csv",
            ["First Name", "Last Name", "Email Id", "Mobile No", "Is Primary Contact"],
            rows,
        )

    # ── Addresses ─────────────────────────────────────────────────────────

    def map_addresses(self):
        """Property addresses → ERPNext Address"""
        rows = []
        for p in self.properties:
            addr = (p.get("address") or {}) if isinstance(p.get("address"), dict) else {}

            line1  = safe(addr.get("street") or addr.get("address1") or p.get("address"))
            line2  = safe(addr.get("address2") or addr.get("unit") or "")
            city   = safe(addr.get("city")  or p.get("city"))
            state  = safe(addr.get("state") or p.get("state"))
            zipcode= safe(addr.get("zip")   or addr.get("zipCode") or p.get("zip") or p.get("zipCode"))
            name   = safe(p.get("name") or p.get("propertyName") or line1 or f"Property-{p.get('id')}")

            if not line1:
                continue

            rows.append({
                "Address Title":     name,
                "Address Type":      "Billing",
                "Address Line 1":    line1,
                "Address Line 2":    line2,
                "City":              city,
                "State":             state,
                "Pincode":           zipcode,
                "Country":           "United States",
                "Is Primary Address": 1,
            })

        write_csv(
            self.output_dir / "address.csv",
            ["Address Title", "Address Type", "Address Line 1", "Address Line 2",
             "City", "State", "Pincode", "Country", "Is Primary Address"],
            rows,
        )

    # ── Items (Properties / Units) ────────────────────────────────────────

    def map_items(self):
        """Properties/units → ERPNext Item (rental asset)"""
        rows = []

        # Properties
        for p in self.properties:
            pid  = safe(p.get("id"))
            name = safe(p.get("name") or p.get("propertyName"))
            addr = (p.get("address") or {}) if isinstance(p.get("address"), dict) else {}
            street = safe(addr.get("street") or addr.get("address1") or p.get("address") or name)

            rows.append({
                "Item Code":        f"PROP-{pid}",
                "Item Name":        name or street,
                "Item Group":       "Property",
                "Description":      street,
                "Is Stock Item":    0,
                "Is Fixed Asset":   1,
                "Custom Hemlane Id": pid,
            })

        # Units
        for u in self.units:
            uid   = safe(u.get("id"))
            name  = safe(u.get("name") or u.get("unitName") or u.get("unitNumber") or f"Unit-{uid}")
            pid   = safe(u.get("propertyId"))

            rows.append({
                "Item Code":        f"UNIT-{uid}",
                "Item Name":        name,
                "Item Group":       "Rental Unit",
                "Description":      f"Unit in property {pid}",
                "Is Stock Item":    0,
                "Is Fixed Asset":   1,
                "Custom Hemlane Id": uid,
                "Custom Property Id": pid,
            })

        write_csv(
            self.output_dir / "item.csv",
            ["Item Code", "Item Name", "Item Group", "Description",
             "Is Stock Item", "Is Fixed Asset", "Custom Hemlane Id", "Custom Property Id"],
            rows,
        )

    # ── Sales Invoices (Rent Charges) ─────────────────────────────────────

    def map_sales_invoices(self):
        """Lease charges/transactions (type=charge/rent) → ERPNext Sales Invoice"""
        rows = []

        # Build tenant lookup: id → customer name
        tenant_map: dict[str, str] = {}
        for t in self.tenants:
            tid   = safe(t.get("id"))
            first = safe(t.get("firstName") or t.get("first_name"))
            last  = safe(t.get("lastName")  or t.get("last_name"))
            tenant_map[tid] = full_name(first, last) or f"Tenant-{tid}"

        for txn in self.transactions:
            txn_type = safe(txn.get("type") or txn.get("transactionType") or "").lower()
            # Only include charges (not payments)
            if txn_type in ("payment", "paid"):
                continue

            tid       = safe(txn.get("tenantId") or txn.get("tenant_id"))
            customer  = tenant_map.get(tid) or f"Tenant-{tid}" if tid else "Unknown Tenant"
            due_date  = format_date(txn.get("dueDate") or txn.get("due_date") or txn.get("date"))
            amount    = format_currency(txn.get("amount") or txn.get("totalAmount"))
            desc      = safe(txn.get("description") or txn.get("category") or "Rent")
            inv_id    = safe(txn.get("id"))

            rows.append({
                "ID":                f"HINV-{inv_id}",
                "Customer":          customer,
                "Posting Date":      due_date,
                "Due Date":          due_date,
                "Item Code":         "Rent",
                "Item Name":         desc,
                "Qty":               1,
                "Rate":              amount,
                "Amount":            amount,
                "Currency":          "USD",
                "Company":           self.company,
                "Custom Hemlane Id": inv_id,
            })

        write_csv(
            self.output_dir / "sales_invoice.csv",
            ["ID", "Customer", "Posting Date", "Due Date", "Item Code", "Item Name",
             "Qty", "Rate", "Amount", "Currency", "Company", "Custom Hemlane Id"],
            rows,
        )

    # ── Payment Entries (Received Payments) ───────────────────────────────

    def map_payment_entries(self):
        """Transactions (type=payment) → ERPNext Payment Entry"""
        rows = []

        tenant_map: dict[str, str] = {}
        for t in self.tenants:
            tid   = safe(t.get("id"))
            first = safe(t.get("firstName") or t.get("first_name"))
            last  = safe(t.get("lastName")  or t.get("last_name"))
            tenant_map[tid] = full_name(first, last) or f"Tenant-{tid}"

        for txn in self.transactions:
            txn_type = safe(txn.get("type") or txn.get("transactionType") or "").lower()
            if txn_type not in ("payment", "paid", "receive"):
                # If no type, include anyway as payment
                if txn_type and txn_type not in ("", "unknown"):
                    continue

            tid      = safe(txn.get("tenantId") or txn.get("tenant_id"))
            customer = tenant_map.get(tid) or f"Tenant-{tid}" if tid else "Unknown Tenant"
            pay_date = format_date(txn.get("paidDate") or txn.get("paid_date")
                                   or txn.get("date") or txn.get("createdAt"))
            amount   = format_currency(txn.get("amount") or txn.get("paidAmount"))
            txn_id   = safe(txn.get("id"))

            rows.append({
                "Payment Type":     "Receive",
                "Party Type":       "Customer",
                "Party":            customer,
                "Posting Date":     pay_date,
                "Paid Amount":      amount,
                "Received Amount":  amount,
                "Currency":         "USD",
                "Mode of Payment":  safe(txn.get("paymentMethod") or ""),
                "Reference No":     txn_id,
                "Reference Date":   pay_date,
                "Company":          self.company,
                "Custom Hemlane Id": txn_id,
            })

        write_csv(
            self.output_dir / "payment_entry.csv",
            ["Payment Type", "Party Type", "Party", "Posting Date",
             "Paid Amount", "Received Amount", "Currency", "Mode of Payment",
             "Reference No", "Reference Date", "Company", "Custom Hemlane Id"],
            rows,
        )

    # ── Maintenance Issues ────────────────────────────────────────────────

    def map_maintenance(self):
        """Maintenance requests → ERPNext Maintenance Visit / Issue"""
        rows = []
        for m in self.maintenance:
            mid     = safe(m.get("id"))
            title   = safe(m.get("title") or m.get("subject") or m.get("description") or f"Maintenance-{mid}")
            desc    = safe(m.get("description") or m.get("details") or "")
            status  = safe(m.get("status") or "Open").title()
            created = format_date(m.get("createdAt") or m.get("created_at") or m.get("date"))
            unit_id = safe(m.get("unitId") or m.get("unit_id") or "")
            prop_id = safe(m.get("propertyId") or m.get("property_id") or "")

            # Map Hemlane statuses to ERPNext
            status_map = {
                "Open":       "Open",
                "Pending":    "Open",
                "Inprogress": "Work In Progress",
                "In Progress":"Work In Progress",
                "Resolved":   "Closed",
                "Closed":     "Closed",
                "Cancelled":  "Cancelled",
            }
            erpnext_status = status_map.get(status, "Open")

            rows.append({
                "Subject":           title,
                "Description":       desc,
                "Status":            erpnext_status,
                "Opening Date":      created,
                "Item Code":         f"UNIT-{unit_id}" if unit_id else f"PROP-{prop_id}",
                "Custom Hemlane Id": mid,
            })

        write_csv(
            self.output_dir / "maintenance_issue.csv",
            ["Subject", "Description", "Status", "Opening Date",
             "Item Code", "Custom Hemlane Id"],
            rows,
        )

    # ── Run All ───────────────────────────────────────────────────────────

    def run(self):
        log.info("Mapping Hemlane data to ERPNext format …")
        self.map_customers()
        self.map_suppliers()
        self.map_contacts()
        self.map_addresses()
        self.map_items()
        self.map_sales_invoices()
        self.map_payment_entries()
        self.map_maintenance()

        # Write import order guide
        guide = self.output_dir / "IMPORT_ORDER.txt"
        guide.write_text("""ERPNext Data Import Order
==========================
Import these CSV files in the following order to avoid reference errors:

1.  customer.csv          → Customers (tenants)
2.  supplier.csv          → Suppliers (owners)
3.  contact.csv           → Contacts
4.  address.csv           → Addresses
5.  item.csv              → Items (properties + units)
6.  sales_invoice.csv     → Sales Invoices (rent charges)
7.  payment_entry.csv     → Payment Entries (received payments)
8.  maintenance_issue.csv → Maintenance Issues

How to import in ERPNext:
    Settings > Data Import > New Data Import
    Select DocType → Upload CSV → Map Columns → Start Import

Notes:
    - All amounts are in USD
    - Dates are in YYYY-MM-DD format
    - Custom Hemlane Id fields preserve the original Hemlane record IDs
      for cross-reference during migration validation
""")
        log.info("  wrote IMPORT_ORDER.txt")
        log.info("Done. All files are in: %s", self.output_dir.resolve())


# ─── CLI ─────────────────────────────────────────────────────────────────────

import argparse

def parse_args():
    p = argparse.ArgumentParser(
        description="Map Hemlane export data to ERPNext-compatible CSVs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    p.add_argument(
        "--input", default="./hemlane_export",
        help="Directory containing Hemlane JSON export files (default: ./hemlane_export)",
    )
    p.add_argument(
        "--output", default="./erpnext_import",
        help="Output directory for ERPNext CSV files (default: ./erpnext_import)",
    )
    p.add_argument(
        "--company", default="My Company",
        help="ERPNext company name (used in invoices/payments)",
    )
    return p.parse_args()


def main():
    args   = parse_args()
    mapper = ERPNextMapper(
        input_dir  = Path(args.input),
        output_dir = Path(args.output),
        company    = args.company,
    )
    mapper.run()


if __name__ == "__main__":
    main()
