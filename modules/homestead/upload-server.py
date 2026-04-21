"""
Homestead Server

HTTP server for bank transaction import and account management.

Pages:
  GET  /             - Bookmarklet generator, transaction import, balance entry

API:
  POST /import       - Import transactions from bookmarklet (JSON: account_id + transactions[])
  POST /balance      - Set account balance (JSON: account_id + balance)
  GET  /accounts     - List accounts (JSON)
  GET  /health       - Health check
"""

import json
from datetime import date, datetime
from decimal import Decimal, InvalidOperation
from http.server import HTTPServer, BaseHTTPRequestHandler

import psycopg2

DB_NAME = "homestead"
PORT = 3001

MAIN_PAGE = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Homestead</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, sans-serif; background: #111217; color: #d0d0d0; padding: 20px; }
  .container { max-width: 500px; margin: 40px auto; }
  h1 { font-size: 1.4em; margin-bottom: 20px; color: #fff; }
  h2 { font-size: 1.1em; margin-bottom: 12px; color: #fff; }
  label { display: block; font-size: 0.9em; margin-bottom: 6px; color: #aaa; }
  select, input[type=number] { width: 100%; padding: 10px; margin-bottom: 16px;
    background: #2a2b33; border: 1px solid #3a3b44; border-radius: 4px; color: #d0d0d0;
    font-size: 0.95em; }
  select:focus, input:focus { outline: none; border-color: #5a9fd4; }
  .card { background: #1a1b21; border-radius: 8px; padding: 24px; margin-bottom: 20px; }
  .bookmarklet-link { display: inline-block; padding: 12px 24px; background: #5a9fd4;
    color: #fff; border-radius: 4px; font-size: 1em; text-decoration: none;
    cursor: grab; margin: 12px 0; }
  .bookmarklet-link:hover { background: #4a8fc4; }
  .bookmarklet-link.disabled { background: #3a3b44; cursor: not-allowed; pointer-events: none; }
  .steps { list-style: none; counter-reset: step; margin-top: 16px; }
  .steps li { counter-increment: step; padding: 8px 0; padding-left: 32px; position: relative; }
  .steps li::before { content: counter(step); position: absolute; left: 0; width: 24px;
    height: 24px; background: #2a2b33; border-radius: 50%; text-align: center;
    line-height: 24px; font-size: 0.85em; color: #5a9fd4; }
  a { color: #5a9fd4; text-decoration: none; }
  a:hover { text-decoration: underline; }
  .nav { margin-bottom: 20px; font-size: 0.9em; }
  .note { font-size: 0.85em; color: #888; margin-top: 12px; }
  .status { padding: 12px; border-radius: 4px; }
  .status.success { background: #1a3a2a; color: #6fcf97; }
  .status.error { background: #3a1a1a; color: #cf6f6f; }
  .btn { width: 100%; padding: 12px; background: #5a9fd4; color: #fff; border: none;
    border-radius: 4px; font-size: 1em; cursor: pointer; }
  .btn:hover { background: #4a8fc4; }
  .btn:disabled { background: #3a3b44; cursor: not-allowed; }
  hr { border: none; border-top: 1px solid #2a2b33; margin: 20px 0; }
</style>
</head>
<body>
<div class="container">
  <div class="nav"><a href="/">Homestead</a> &middot; <a href="http://HOSTNAME_PLACEHOLDER:3000">Dashboard</a></div>
  <h1>Homestead</h1>

  <div class="card">
    <h2>Import Transactions</h2>
    <label for="account">Account</label>
    <select id="account">
      <option value="">Loading accounts...</option>
    </select>
    <p style="margin-bottom:8px; color:#aaa; font-size:0.9em;">Drag this link to your bookmarks bar:</p>
    <a id="bmLink" class="bookmarklet-link disabled" href="#">Import Transactions</a>
    <p class="note">Works on Ark Valley CU transaction history pages.</p>
    <hr>
    <h2>How to use</h2>
    <ol class="steps">
      <li>Select your account above and drag the blue link to your bookmarks bar</li>
      <li>Log into Ark Valley Credit Union online banking</li>
      <li>Navigate to Transaction History for the account</li>
      <li>Click the bookmarklet &mdash; it copies transaction data to your clipboard</li>
      <li>Come back here and click "Paste &amp; Import" below</li>
    </ol>
    <hr>
    <h2>Paste &amp; Import</h2>
    <textarea id="pasteArea" rows="4" placeholder="Paste copied transaction data here..." style="width:100%;padding:10px;margin-bottom:12px;background:#2a2b33;border:1px solid #3a3b44;border-radius:4px;color:#d0d0d0;font-size:0.9em;font-family:monospace;resize:vertical;"></textarea>
    <button id="importBtn" onclick="doImport()" class="btn">Paste &amp; Import</button>
    <div id="importStatus" class="status" style="margin-top:12px;display:none;"></div>
  </div>

  <div class="card">
    <h2>Set Account Balance</h2>
    <label for="balanceAccount">Account</label>
    <select id="balanceAccount">
      <option value="">Loading accounts...</option>
    </select>
    <label for="balanceAmount">Current Balance ($)</label>
    <input type="number" id="balanceAmount" step="0.01" placeholder="0.00">
    <button id="balanceBtn" onclick="setBalance()" class="btn">Set Balance</button>
    <div id="balanceStatus" class="status" style="margin-top:12px;display:none;"></div>
  </div>
</div>
<script>

async function loadAccounts() {
  try {
    const resp = await fetch('/accounts');
    const accounts = await resp.json();
    ['account', 'balanceAccount'].forEach(id => {
      const sel = document.getElementById(id);
      sel.innerHTML = '<option value="">Select account...</option>';
      accounts.forEach(a => {
        const opt = document.createElement('option');
        opt.value = a.id;
        opt.textContent = a.name + ' (' + a.type + ')';
        sel.appendChild(opt);
      });
    });
  } catch(e) { console.error('Failed to load accounts:', e); }
}

function updateBookmarklet() {
  const accountId = document.getElementById('account').value;
  const link = document.getElementById('bmLink');
  if (!accountId) {
    link.href = '#';
    link.className = 'bookmarklet-link disabled';
    return;
  }
  link.className = 'bookmarklet-link';
  const js = `javascript:void(function(){var t=document.getElementById('c2th0');if(!t){alert('No transaction table found. Make sure you are on the AVCU Transaction History page.');return;}var rows=t.querySelectorAll('tr');var txns=[];for(var i=1;i<rows.length;i++){var cells=rows[i].querySelectorAll('td');if(cells.length<3)continue;var dateStr=cells[0].textContent.trim();if(!dateStr||dateStr==='\\xa0')continue;var descHTML=cells[1].innerHTML;var amountStr=cells[2].textContent.trim();if(!amountStr||amountStr==='\\xa0')continue;var parts=descHTML.split(/<br[^>]*>/i);var desc='';if(parts.length>=2){desc=parts.slice(1).join(' / ').replace(/<[^>]*>/g,'').trim();}else{desc=parts[0].replace(/<[^>]*>/g,'').trim();}if(!desc)continue;txns.push({date:dateStr,description:desc,amount:amountStr});}if(txns.length===0){alert('No transactions found on this page.');return;}var data=JSON.stringify({account_id:${accountId},transactions:txns});navigator.clipboard.writeText(data).then(function(){alert('Copied '+txns.length+' transactions to clipboard.\\nOpen the Homestead import page and click Paste & Import.');}).catch(function(){prompt('Copy this text, then paste it on the Homestead import page:',data);});}())`;
  link.href = js;
}

async function doImport() {
  const textarea = document.getElementById('pasteArea');
  const btn = document.getElementById('importBtn');
  const status = document.getElementById('importStatus');
  let raw = textarea.value.trim();

  if (!raw) {
    try {
      raw = await navigator.clipboard.readText();
      textarea.value = raw;
    } catch(e) {
      status.className = 'status error';
      status.textContent = 'Paste the copied transaction data into the text area first.';
      status.style.display = 'block';
      return;
    }
  }

  let data;
  try {
    data = JSON.parse(raw);
  } catch(e) {
    status.className = 'status error';
    status.textContent = 'Invalid data format. Make sure you copied from the bookmarklet.';
    status.style.display = 'block';
    return;
  }

  btn.disabled = true;
  btn.textContent = 'Importing...';
  status.style.display = 'none';

  try {
    const resp = await fetch('/import', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: raw
    });
    const result = await resp.json();
    if (resp.ok) {
      status.className = 'status success';
      var msg = result.inserted + ' transactions imported';
      if (result.deleted > 0) msg += ' (' + result.deleted + ' previous replaced)';
      if (result.categorized > 0) msg += ', ' + result.categorized + ' auto-categorized';
      if (result.balance) msg += '. Balance: $' + parseFloat(result.balance).toFixed(2);
      status.textContent = msg;
    } else {
      status.className = 'status error';
      status.textContent = 'Error: ' + (result.error || 'Import failed');
    }
  } catch(e) {
    status.className = 'status error';
    status.textContent = 'Error: ' + e.message;
  }
  status.style.display = 'block';
  btn.disabled = false;
  btn.textContent = 'Paste & Import';
}

async function setBalance() {
  const accountId = document.getElementById('balanceAccount').value;
  const amount = document.getElementById('balanceAmount').value;
  const btn = document.getElementById('balanceBtn');
  const status = document.getElementById('balanceStatus');

  if (!accountId) {
    status.className = 'status error';
    status.textContent = 'Select an account.';
    status.style.display = 'block';
    return;
  }
  if (!amount) {
    status.className = 'status error';
    status.textContent = 'Enter a balance amount.';
    status.style.display = 'block';
    return;
  }

  btn.disabled = true;
  btn.textContent = 'Saving...';
  status.style.display = 'none';

  try {
    const resp = await fetch('/balance', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({account_id: parseInt(accountId), balance: amount})
    });
    const result = await resp.json();
    if (resp.ok) {
      status.className = 'status success';
      status.textContent = 'Balance set to $' + parseFloat(amount).toFixed(2) + ' for today.';
      document.getElementById('balanceAmount').value = '';
    } else {
      status.className = 'status error';
      status.textContent = 'Error: ' + (result.error || 'Failed');
    }
  } catch(e) {
    status.className = 'status error';
    status.textContent = 'Error: ' + e.message;
  }
  status.style.display = 'block';
  btn.disabled = false;
  btn.textContent = 'Set Balance';
}

document.getElementById('account').addEventListener('change', updateBookmarklet);
loadAccounts();
</script>
</body>
</html>"""


def get_db():
    return psycopg2.connect(dbname=DB_NAME)


# Category rules: (pattern, category_name, amount_filter)
# amount_filter: None = match any, (op, value) = match specific amounts
CATEGORY_RULES = [
    # Income
    ("DEP-%", "income", None),
    ("INTERNET TRANSFER DEPO%", "income", None),

    # Housing (rent via specific transfer amounts)
    ("INTERNET TRANSFER W/DR%", "housing", ("in", [-500, -450])),

    # Utilities
    ("Evergy%", "utilities", None),
    ("I3P*KANSAS GAS%", "utilities", None),
    ("TMOBILE%", "utilities", None),
    ("GOOGLE *FI%", "utilities", None),
    ("CITY OF EL DORA%", "utilities", None),

    # Subscriptions
    ("CLAUDE.AI%", "subscriptions", None),
    ("%CLAUDE.AI%", "subscriptions", None),
    ("ANTHROPIC%", "subscriptions", None),
    ("%ANTHROPIC%", "subscriptions", None),
    ("AMAZON PRIME%", "subscriptions", None),
    ("GOOGLE *YouTube%", "subscriptions", None),
    ("GOOGLE *Google%", "subscriptions", None),
    ("GOOGLE *Snapcha%", "subscriptions", None),
    ("GOOGLE *Garden%", "subscriptions", None),
    ("GITHUB%", "subscriptions", None),
    ("PAYPAL *GITHUB%", "subscriptions", None),
    ("Audible%", "subscriptions", None),
    ("BANDCAMP%", "subscriptions", None),
    ("DIGITALOCEAN%", "subscriptions", None),
    ("Amazon web serv%", "subscriptions", None),

    # Groceries
    ("WAL-MART%", "groceries", None),
    ("WAL WAL-MART%", "groceries", None),
    ("WM SUPERCENTER%", "groceries", None),
    ("Walmart%", "groceries", None),
    ("WALMART%", "groceries", None),
    ("DILLONS%", "groceries", None),
    ("DOLLAR%GENERAL%", "groceries", None),
    ("DOLLARTREE%", "groceries", None),
    ("TARGET%", "groceries", None),

    # Food (restaurants, fast food, convenience, vending)
    ("McDonalds%", "food", None),
    ("MCDONALDS%", "food", None),
    ("SONIC DRIVE%", "food", None),
    ("TACO BELL%", "food", None),
    ("JIMMY JOHNS%", "food", None),
    ("ARBYS%", "food", None),
    ("WENDY%", "food", None),
    ("PIZZA HUT%", "food", None),
    ("DOMINO%", "food", None),
    ("HOG WILD%", "food", None),
    ("SPANGLES%", "food", None),
    ("BEIJING BISTRO%", "food", None),
    ("TST*%", "food", None),
    ("Subway%", "food", None),
    ("KARMELCORN%", "food", None),
    ("Scooters Coffee%", "food", None),
    ("%SCOOTER%COFFE%", "food", None),
    ("209 BRAUMS%", "food", None),
    ("CASEYS%", "food", None),
    ("QT 3%", "food", None),
    ("SUNNY STOP%", "food", None),
    ("JUMP START%", "food", None),
    ("Nayax%", "food", None),

    # Transport
    ("VCN*KDORDMV%", "transport", None),
    ("SQ *CCBIKECO%", "transport", None),

    # Savings
    ("SHARE WITHDRAWAL%", "savings", None),
    ("INTERNET TRANSFER W/DR%", "savings", None),

    # Personal (shopping, services, misc)
    ("AMAZON MKTPL%", "personal", None),
    ("AMAZON RETA%", "personal", None),
    ("PAYPAL *ITCH%", "personal", None),
    ("WL *STEAM%", "personal", None),
    ("SP GAMER SUPPS%", "personal", None),
    ("SP EXOTIC PETS%", "personal", None),
    ("SP AMYMK%", "personal", None),
    ("MICHAELS%", "personal", None),
    ("ACE HARDWARE%", "personal", None),
    ("WESTLAKE HARDWA%", "personal", None),
    ("WILLES SPORTS%", "personal", None),
    ("SQ *THAIRAPY%", "personal", None),
    ("SQ *RJC%", "personal", None),
    ("SQ *SCOTSFARE%", "personal", None),
    ("EXPRESS LAUNDRY%", "personal", None),
    ("CASH APP%", "personal", None),
    ("EL DORADO- SMIT%", "personal", None),
    ("KS.GOV PAYMENT%", "personal", None),
    ("JCPENNEY%", "personal", None),
]


def auto_categorize(cur, account_id, min_date, max_date):
    """Categorize uncategorized transactions using pattern rules."""
    # Load category name->id mapping
    cur.execute("SELECT id, name FROM categories")
    cat_map = {name: cid for cid, name in cur.fetchall()}

    categorized = 0
    for pattern, cat_name, amount_filter in CATEGORY_RULES:
        cat_id = cat_map.get(cat_name)
        if not cat_id:
            continue

        if amount_filter:
            op, values = amount_filter
            if op == "in":
                placeholders = ",".join(["%s"] * len(values))
                cur.execute(
                    f"""UPDATE transactions SET category_id = %s
                       WHERE account_id = %s AND date >= %s AND date <= %s
                       AND category_id IS NULL
                       AND description ILIKE %s
                       AND amount IN ({placeholders})""",
                    [cat_id, account_id, min_date, max_date, pattern] + values
                )
            categorized += cur.rowcount
        else:
            cur.execute(
                """UPDATE transactions SET category_id = %s
                   WHERE account_id = %s AND date >= %s AND date <= %s
                   AND category_id IS NULL
                   AND description ILIKE %s""",
                (cat_id, account_id, min_date, max_date, pattern)
            )
            categorized += cur.rowcount

    return categorized


class Handler(BaseHTTPRequestHandler):
    def _cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _json_response(self, status, data):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self._cors_headers()
        self.end_headers()
        self.wfile.write(body)

    def _html_response(self, status, html):
        body = html.encode()
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors_headers()
        self.end_headers()

    def do_GET(self):
        hostname = self.headers.get("Host", "localhost:3001").split(":")[0]
        if self.path == "/":
            self._html_response(200, MAIN_PAGE.replace("HOSTNAME_PLACEHOLDER", hostname))
        elif self.path == "/accounts":
            self._handle_accounts()
        elif self.path == "/health":
            self._json_response(200, {"status": "ok"})
        else:
            self._json_response(404, {"error": "not found"})

    def do_POST(self):
        if self.path == "/import":
            self._handle_import()
        elif self.path == "/balance":
            self._handle_balance()
        else:
            self._json_response(404, {"error": "not found"})

    def _read_json(self):
        content_type = self.headers.get("Content-Type", "")
        if "application/json" not in content_type:
            return None
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length)
        return json.loads(body)

    def _handle_accounts(self):
        try:
            conn = get_db()
            cur = conn.cursor()
            cur.execute("SELECT id, name, institution, account_type FROM accounts ORDER BY name")
            rows = cur.fetchall()
            cur.close()
            conn.close()
            accounts = [
                {"id": r[0], "name": r[1], "institution": r[2], "type": r[3]}
                for r in rows
            ]
            self._json_response(200, accounts)
        except Exception as e:
            self._json_response(500, {"error": str(e)})

    def _handle_import(self):
        try:
            data = self._read_json()
            if data is None:
                self._json_response(400, {"error": "Content-Type must be application/json"})
                return

            account_id = data.get("account_id")
            transactions = data.get("transactions", [])

            if not account_id:
                self._json_response(400, {"error": "missing account_id"})
                return
            if not transactions:
                self._json_response(400, {"error": "no transactions provided"})
                return

            conn = get_db()
            cur = conn.cursor()

            # Parse all transactions first
            parsed = []
            skipped = 0
            for txn in transactions:
                txn_date = self._parse_import_date(txn.get("date", ""))
                description = txn.get("description", "").strip()
                amount = self._parse_amount(txn.get("amount", ""))

                if txn_date is None or amount is None or not description:
                    skipped += 1
                    continue
                parsed.append((account_id, txn_date, description, amount))

            if not parsed:
                self._json_response(200, {"inserted": 0, "deleted": 0, "total": len(transactions)})
                return

            # Determine date range of import
            min_date = min(t[1] for t in parsed)
            max_date = max(t[1] for t in parsed)

            # Delete existing bookmarklet transactions in this date range
            cur.execute(
                """DELETE FROM transactions
                   WHERE account_id = %s AND source = 'bookmarklet'
                   AND date >= %s AND date <= %s""",
                (account_id, min_date, max_date)
            )
            deleted = cur.rowcount

            # Insert the full set
            for acct_id, txn_date, description, amount in parsed:
                cur.execute(
                    """INSERT INTO transactions (account_id, date, description, amount, source)
                       VALUES (%s, %s, %s, %s, 'bookmarklet')""",
                    (acct_id, txn_date, description, amount)
                )

            # Auto-categorize new transactions
            categorized = auto_categorize(cur, account_id, min_date, max_date)

            # Recalculate balance after import
            new_balance = self._recalculate_balance(cur, account_id)

            conn.commit()
            cur.close()
            conn.close()

            result = {
                "inserted": len(parsed),
                "deleted": deleted,
                "categorized": categorized,
                "total": len(transactions),
            }
            if new_balance is not None:
                result["balance"] = str(new_balance)

            self._json_response(200, result)

        except Exception as e:
            self._json_response(500, {"error": str(e)})

    def _handle_balance(self):
        try:
            data = self._read_json()
            if data is None:
                self._json_response(400, {"error": "Content-Type must be application/json"})
                return

            account_id = data.get("account_id")
            balance_str = data.get("balance", "")

            if not account_id:
                self._json_response(400, {"error": "missing account_id"})
                return

            balance = self._parse_amount(str(balance_str))
            if balance is None:
                self._json_response(400, {"error": "invalid balance amount"})
                return

            conn = get_db()
            cur = conn.cursor()
            cur.execute(
                """INSERT INTO balance_snapshots (account_id, snapshot_date, balance, source)
                   VALUES (%s, %s, %s, 'manual')""",
                (account_id, date.today(), balance)
            )
            conn.commit()
            cur.close()
            conn.close()

            self._json_response(200, {
                "account_id": account_id,
                "balance": str(balance),
                "date": str(date.today()),
            })

        except Exception as e:
            self._json_response(500, {"error": str(e)})

    @staticmethod
    def _recalculate_balance(cur, account_id):
        """
        Recalculate account balance from the latest manual anchor.

        Logic: find most recent manual balance snapshot, then add all
        transactions after that date. Insert a new 'calculated' snapshot
        for today. Returns the new balance, or None if no anchor exists.
        """
        # Find the latest manual anchor
        cur.execute(
            """SELECT snapshot_date, balance FROM balance_snapshots
               WHERE account_id = %s AND source = 'manual'
               ORDER BY snapshot_date DESC, id DESC LIMIT 1""",
            (account_id,)
        )
        anchor = cur.fetchone()
        if not anchor:
            return None

        anchor_date, anchor_balance = anchor

        # Sum transactions after the anchor date
        cur.execute(
            """SELECT COALESCE(SUM(amount), 0) FROM transactions
               WHERE account_id = %s AND date > %s""",
            (account_id, anchor_date)
        )
        txn_sum = cur.fetchone()[0]

        new_balance = anchor_balance + txn_sum

        # Upsert today's calculated snapshot
        today = date.today()
        cur.execute(
            """INSERT INTO balance_snapshots (account_id, snapshot_date, balance, source)
               VALUES (%s, %s, %s, 'calculated')
               ON CONFLICT (account_id, snapshot_date, source)
               DO UPDATE SET balance = EXCLUDED.balance""",
            (account_id, today, new_balance)
        )

        return new_balance

    @staticmethod
    def _parse_import_date(date_str):
        if not date_str:
            return None
        for fmt in ("%m/%d/%Y", "%m/%d/%y"):
            try:
                return datetime.strptime(date_str.strip(), fmt).date()
            except ValueError:
                continue
        return None

    @staticmethod
    def _parse_amount(amount_str):
        if not amount_str:
            return None
        cleaned = str(amount_str).strip().replace("$", "").replace(",", "")
        try:
            return Decimal(cleaned)
        except InvalidOperation:
            return None

    def log_message(self, format, *args):
        print(f"[homestead] {args[0]} {args[1]} {args[2]}")


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), Handler)
    print(f"Homestead server listening on port {PORT}")
    server.serve_forever()
