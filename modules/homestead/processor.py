"""
Homestead Screenshot OCR Processor

Polls the screenshots table for pending entries, runs Tesseract OCR,
parses bank transaction data, deduplicates, and inserts into the
transactions table.

Parser profiles:
  - ark_valley: Ark Valley Credit Union online banking format
  - generic: Fallback for standard MM/DD Description $Amount lines
"""

import os
import re
import subprocess
import sys
from datetime import datetime, date
from decimal import Decimal, InvalidOperation

import psycopg2

DB_NAME = "homestead"


def get_db():
    return psycopg2.connect(dbname=DB_NAME)


def ocr_image(file_path):
    """Run Tesseract OCR on an image file."""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Image not found: {file_path}")
    result = subprocess.run(
        ["tesseract", file_path, "stdout", "--psm", "6"],
        capture_output=True, text=True, timeout=60
    )
    if result.returncode != 0:
        raise RuntimeError(f"Tesseract failed: {result.stderr}")
    return result.stdout


def parse_date_compact(date_str):
    """Parse compact date like '4192025' (MDDYYYY or MMDDYYYY)."""
    s = date_str.strip()
    if len(s) < 7 or len(s) > 8:
        return None
    # Try MMDDYYYY (8 digits) and MDDYYYY (7 digits)
    if len(s) == 8:
        month, day, year = s[:2], s[2:4], s[4:]
    elif len(s) == 7:
        month, day, year = s[:1], s[1:3], s[3:]
    else:
        return None
    try:
        return date(int(year), int(month), int(day))
    except ValueError:
        return None


def parse_date_standard(date_str):
    """Parse date string with separators (MM/DD/YYYY, etc.)."""
    for fmt in ("%m/%d/%Y", "%m/%d/%y", "%m/%d", "%m-%d-%Y", "%m-%d-%y"):
        try:
            d = datetime.strptime(date_str.strip(), fmt).date()
            if "%Y" not in fmt and "%y" not in fmt:
                d = d.replace(year=date.today().year)
            return d
        except ValueError:
            continue
    return None


def parse_ocr_amount(amount_str):
    """
    Parse dollar amount from OCR text.
    Handles OCR artifacts: '$' misread as 's', missing decimal points.
    Examples: 's1676' -> 16.76, '$2.70' -> 2.70, '1700' -> 17.00
    """
    cleaned = amount_str.strip()
    # Remove leading s/S (OCR misread of $) or actual $
    cleaned = re.sub(r'^[sS$]+', '', cleaned)
    # Remove commas
    cleaned = cleaned.replace(",", "")

    if not cleaned or not re.match(r'^[\d.]+$', cleaned):
        return None

    try:
        if "." in cleaned:
            return Decimal(cleaned)
        else:
            # No decimal point: assume cents (last 2 digits are cents)
            if len(cleaned) >= 3:
                dollars = cleaned[:-2]
                cents = cleaned[-2:]
                return Decimal(f"{dollars}.{cents}")
            elif len(cleaned) == 2:
                return Decimal(f"0.{cleaned}")
            elif len(cleaned) == 1:
                return Decimal(f"0.0{cleaned}")
            else:
                return None
    except InvalidOperation:
        return None


def parse_amount_standard(amount_str):
    """Parse a standard dollar amount with decimal point."""
    cleaned = amount_str.strip().replace(",", "").replace("$", "")
    if cleaned.startswith("(") and cleaned.endswith(")"):
        cleaned = "-" + cleaned[1:-1]
    try:
        return Decimal(cleaned)
    except InvalidOperation:
        return None


# ---------------------------------------------------------------------------
# Ark Valley Credit Union parser
# ---------------------------------------------------------------------------

def parse_ark_valley(ocr_text, account_id):
    """
    Parse Ark Valley Credit Union online banking format.

    Format (two-line pairs):
      Line 1: DATE TRANSACTIONTYPE AMOUNT
        e.g. '4192025 POSIATMWITHDRAWAL s1676'
        e.g. 'PENDING TRANSACTION s2000'
      Line 2: DESCRIPTION
        e.g. 'SONIC DRIVE IN/ 1843 W CENTRAL AVE | EL DORADO KS'

    Date format: MDDYYYY or MMDDYYYY (no separators)
    Amount: prefixed with 's' (OCR misread of '$'), no decimal point
    """
    transactions = []
    lines = [l.strip() for l in ocr_text.split("\n") if l.strip()]

    # Pattern for posted transactions: date + type + amount
    posted_pattern = re.compile(
        r"(\d{7,8})"             # compact date (MDDYYYY or MMDDYYYY)
        r"\s+"
        r"(\S+)"                 # transaction type (e.g., POSIATMWITHDRAWAL)
        r"\s+"
        r"[sS$]?([\d,.]+)"      # amount (with possible s prefix)
    )

    # Pattern for pending transactions
    pending_pattern = re.compile(
        r"PENDING\s+TRANSACTION"
        r"\s+"
        r"[sS$]?([\d,.]+)"      # amount
        r"\s*$",
        re.IGNORECASE
    )

    i = 0
    while i < len(lines):
        line = lines[i]

        # Try posted transaction
        match = posted_pattern.match(line)
        if match:
            date_str, txn_type, amount_str = match.groups()
            txn_date = parse_date_compact(date_str)
            amount = parse_ocr_amount(amount_str)

            if txn_date and amount:
                # Next line is the description
                desc = lines[i + 1].strip() if i + 1 < len(lines) else txn_type
                # Skip if next line looks like another transaction
                if posted_pattern.match(desc) or pending_pattern.match(desc):
                    desc = txn_type
                else:
                    i += 1  # consume the description line

                # All withdrawals/purchases are negative
                if amount > 0:
                    amount = -amount

                transactions.append({
                    "account_id": account_id,
                    "date": txn_date,
                    "description": desc,
                    "amount": amount,
                })
            i += 1
            continue

        # Try pending transaction
        match = pending_pattern.match(line)
        if match:
            amount_str = match.group(1)
            amount = parse_ocr_amount(amount_str)

            if amount:
                desc = lines[i + 1].strip() if i + 1 < len(lines) else "PENDING"
                if posted_pattern.match(desc) or pending_pattern.match(desc):
                    desc = "PENDING"
                else:
                    i += 1

                if amount > 0:
                    amount = -amount

                transactions.append({
                    "account_id": account_id,
                    "date": date.today(),
                    "description": f"(PENDING) {desc}",
                    "amount": amount,
                })
            i += 1
            continue

        i += 1

    return transactions


# ---------------------------------------------------------------------------
# Generic parser (fallback)
# ---------------------------------------------------------------------------

def parse_generic(ocr_text, account_id):
    """
    Generic parser for standard bank statement formats.
    Matches lines like: MM/DD  DESCRIPTION  $123.45
    """
    transactions = []
    lines = ocr_text.split("\n")

    date_pattern = re.compile(
        r"(\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?)"
        r"\s+"
        r"(.+?)"
        r"\s+"
        r"(-?\$?[\d,]+\.\d{2})"
        r"(?:\s+\$?[\d,]+\.\d{2})?"
        r"\s*$"
    )

    for line in lines:
        line = line.strip()
        if not line:
            continue

        match = date_pattern.match(line)
        if not match:
            continue

        date_str, desc, amount_str = match.groups()
        txn_date = parse_date_standard(date_str)
        amount = parse_amount_standard(amount_str)

        if txn_date is None or amount is None:
            continue

        desc = desc.strip()
        if len(desc) < 2:
            continue

        transactions.append({
            "account_id": account_id,
            "date": txn_date,
            "description": desc,
            "amount": amount,
        })

    return transactions


def parse_transactions(ocr_text, account_id):
    """
    Try parsers in order of specificity. Use whichever returns results.
    """
    # Try Ark Valley format first
    results = parse_ark_valley(ocr_text, account_id)
    if results:
        print(f"  Parser: ark_valley matched {len(results)} transactions")
        return results

    # Fall back to generic
    results = parse_generic(ocr_text, account_id)
    if results:
        print(f"  Parser: generic matched {len(results)} transactions")
        return results

    print("  Parser: no parser matched any transactions")
    return []


def parse_balance(ocr_text):
    """Extract balance from OCR text if present."""
    patterns = [
        r"(?:available|current|ending|closing)\s*balance\s*:?\s*[sS$]?([\d,]+\.?\d*)",
        r"balance\s*:?\s*[sS$]?([\d,]+\.?\d*)",
    ]
    for pattern in patterns:
        match = re.search(pattern, ocr_text, re.IGNORECASE)
        if match:
            return parse_ocr_amount(match.group(1))
    return None


def is_fuzzy_duplicate(cur, account_id, txn_date, amount, description):
    """Check for fuzzy duplicates using pg_trgm similarity."""
    cur.execute(
        """SELECT id, description FROM transactions
           WHERE account_id = %s AND date = %s AND amount = %s
           AND similarity(description, %s) > 0.4
           LIMIT 1""",
        (account_id, txn_date, amount, description)
    )
    return cur.fetchone()


def process_pending():
    """Process all pending screenshots."""
    conn = get_db()
    cur = conn.cursor()

    cur.execute(
        """SELECT id, file_path, account_id
           FROM screenshots
           WHERE status = 'pending'
           ORDER BY uploaded_at
           LIMIT 10"""
    )
    pending = cur.fetchall()

    if not pending:
        print("No pending screenshots.")
        cur.close()
        conn.close()
        return

    for screenshot_id, file_path, account_id in pending:
        print(f"Processing screenshot {screenshot_id}: {file_path}")
        try:
            # Mark as processing
            cur.execute(
                "UPDATE screenshots SET status = 'processing' WHERE id = %s",
                (screenshot_id,)
            )
            conn.commit()

            # OCR
            ocr_text = ocr_image(file_path)
            cur.execute(
                "UPDATE screenshots SET ocr_text = %s WHERE id = %s",
                (ocr_text, screenshot_id)
            )

            inserted = 0
            skipped_exact = 0
            skipped_fuzzy = 0

            if account_id:
                transactions = parse_transactions(ocr_text, account_id)
                print(f"  Parsed {len(transactions)} transactions from OCR text")

                for txn in transactions:
                    # Check for fuzzy duplicate first
                    fuzzy = is_fuzzy_duplicate(
                        cur, txn["account_id"], txn["date"],
                        txn["amount"], txn["description"]
                    )
                    if fuzzy:
                        print(f"  SKIP (fuzzy match #{fuzzy[0]}): {txn['date']} {txn['description']} {txn['amount']}")
                        skipped_fuzzy += 1
                        continue

                    # Insert with exact dedup via ON CONFLICT
                    cur.execute(
                        """INSERT INTO transactions (account_id, date, description, amount, source)
                           VALUES (%s, %s, %s, %s, 'ocr')
                           ON CONFLICT (account_id, date, description, amount) DO NOTHING
                           RETURNING id""",
                        (txn["account_id"], txn["date"], txn["description"], txn["amount"])
                    )
                    result = cur.fetchone()
                    if result:
                        inserted += 1
                        print(f"  INSERT: {txn['date']} {txn['description']} {txn['amount']}")
                    else:
                        skipped_exact += 1
                        print(f"  SKIP (exact): {txn['date']} {txn['description']} {txn['amount']}")

                # Try to extract balance
                balance = parse_balance(ocr_text)
                if balance is not None:
                    cur.execute(
                        """INSERT INTO balance_snapshots (account_id, snapshot_date, balance, source)
                           VALUES (%s, %s, %s, 'ocr')""",
                        (account_id, date.today(), balance)
                    )
                    print(f"  Balance snapshot: {balance}")

            status = "completed" if account_id else "review"
            cur.execute(
                "UPDATE screenshots SET status = %s, processed_at = NOW() WHERE id = %s",
                (status, screenshot_id)
            )
            conn.commit()
            print(f"  Done: {inserted} inserted, {skipped_exact} exact dupes, {skipped_fuzzy} fuzzy dupes")

        except Exception as e:
            conn.rollback()
            cur.execute(
                "UPDATE screenshots SET status = 'failed', error_message = %s WHERE id = %s",
                (str(e), screenshot_id)
            )
            conn.commit()
            print(f"  FAILED: {e}")

    cur.close()
    conn.close()


if __name__ == "__main__":
    process_pending()
