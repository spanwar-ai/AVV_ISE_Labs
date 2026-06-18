# PurchaseReciept (ISE) — Developer Guide & Further-Development Plan

> Business Central AL extension. Publisher **ISE**, app **PurchaseReciept** `1.0.0.1`.
> Runtime 16.0, target **Cloud**, application 27.0, object range **50000–99999**.
> Depends on **InventoryISEMovement** `1.0.0.1` (ISE) for the `ISE Customer Order` tables/pages.

This document is for the next developer. It explains what the app does, how the
pieces fit together, the data model, the known risks/technical debt, and a
prioritized backlog for further development.

---

## 1. What this app does

The extension adds a **custom purchase-receiving and invoicing flow** on top of
standard Purchase Orders, plus a bridge that pushes a Released PO into the ISE
"Receiving" add-on. There are effectively **two parallel features** living in the
same app, distinguished by their object-name prefix and ID range:

| Feature | Prefix | ID range | Purpose |
|---|---|---|---|
| **BVR Custom Receipt / Invoice** | `BVR …` | 50xxx | A bespoke receive→accrue→invoice cycle that posts accrual G/L entries and item ledger quantities manually, with its own approval workflow, posting preview, and reports. |
| **PO → ISE bridge** | `PO→ISE`, `ISE …` | 70xxx | An action on the standard Purchase Order that copies outstanding lines into an `ISE Customer Order` (Adhoc Receipt) and blocks normal posting of that PO. |

The two features overlap conceptually (both are about receiving a PO outside the
standard flow) but are **independent code paths** today.

---

## 2. High-level architecture

### 2.1 BVR Custom Receipt flow

```
Standard Purchase Order(s), Released
        │  (Get Released PO Lines — codeunit 50150)
        ▼
"Custom Receipt" Purchase Order  (Header.BVR Receive PO = true)
        │   • lines carry BVR Source PO No./Line No., Source PO Qty, Remaining Qty
        │   • user fills Qty. to Receive + accrual G/L accounts
        │
        ├─ Posting Preview (codeunit 50250 → page "BVR Posting Preview" / report 50xxx)
        │
        ├─ Approval workflow (codeunit 50240: AP Updated → Send → Approve / Send Back)
        │
        ▼  (Post — codeunit 50123 "BVR Custom Rcpt Post V2")
Posted Purch. Rcpt. Header/Line  (BVR Custom Receipt = true)
        │   • Item Ledger Entry (qty only, Unit Amount 0) for inventory items
        │   • ONE clubbed accrual G/L entry: Dr Expense Accrual / Cr Vendor Accrual
        │   • source PO line Quantity Received updated, Qty. to Receive zeroed
        │   • attachments copied (codeunit 50320)
        │
        ▼  (Create Custom Invoice — codeunit 50140)
"Custom Invoice" Purchase Header (Document Type = Invoice)
        │   • Get Custom Receipt Lines (codeunit 50141) pulls posted-receipt lines
        │
        ▼  (Post — codeunit 50142 "BVR Custom Inv Post")
Posted Purch. Inv. Header/Line
            • Reverse vendor accrual (receipt base) → Payables
            • Post base variance (invoice base − receipt base) → Expense
            • Post Sales/Use tax → Tax Account (Purchases) → Payables
            • mark receipt lines BVR Invoiced Qty
```

Key idea: instead of using BC's native `Purch.-Post`, the receipt and invoice are
posted by **hand-written codeunits** that insert posted records and write G/L /
item-ledger entries via `Gen. Jnl.-Post Line` and `Item Jnl.-Post Line`. The
accrual model is:

- **Receive:** Dr *Expense Accrual* / Cr *Vendor Accrual* for `Direct Unit Cost × Qty`.
- **Invoice:** reverse the *Vendor Accrual* (at receipt cost) into *Payables*, post
  any cost difference to *Expense*, and post tax to the *Tax Account (Purchases)*.

### 2.2 PO → ISE bridge

```
Standard Purchase Order, Released
   │  (action "Send to ISE Receiving" — pageext 70461 → codeunit 70462)
   ▼
ISE Customer Order Header (Order Source = Adhoc, Request Type = Receipt)
   + ISE Customer Order Lines (outstanding qty)         → opens "ISE Receiving Card"
   │
   └─ Purchase Header."Sent to ISE Receiving" = true
        └─ codeunit 70463 "PO Post Guard" subscribes to OnBeforePostPurchaseDoc
           and BLOCKS standard posting of a PO once it's been sent to ISE.
```

---

## 3. Object inventory

### Tables / Table extensions
- **`BVR Purch Header Ext` (50110)** — adds to `Purchase Header`: `BVR Receive PO`,
  `BVR Custom Rcpt Posted`, `BVR Posted Rcpt No.`, `BVR Vendor/Expense Accrual Acc No.`,
  `BVR Custom Inv Posted`, `BVR Posted Inv No.`, `BVR Group No.`, `BVR Batch No.`
  (approval/grouping fields). *(Note: an `OnInsert` default is commented out.)*
- **`BVR Purch Line Ext` (50114)** — adds to `Purchase Line`: `BVR From Custom Receipt`,
  `BVR Source Rcpt No./Line No.`, `BVR Source PO No./Line No.`, `BVR Source PO Qty`,
  `BVR Remaining Qty`.
- **`BVR Purch Rcpt Header/Line Ext`** — posted-receipt markers (`BVR Custom Receipt`,
  accrual accounts, `BVR Accrued Unit Cost/Amount`, `BVR Invoiced Qty`, source PO links).
- **`BVR Purch Header Approval Ext`** — approval-state fields (`BVR Requires Approval`,
  `BVR AP Updated`, `BVR Sent For Approval`, `BVR Approved`).
- **`PO Hdr ISE Flag Ext` (70460)** — adds `Sent to ISE Receiving` to `Purchase Header`.
- **`BVR PO Line Buffer` (50150)** — temporary buffer table for the "select PO lines" dialog.
- **`BVR Posting Preview Line` (50xxx)** — temporary table backing the posting-preview page/report.

### Codeunits
| ID | Name | Role |
|---|---|---|
| 50122 | BVR Custom Rcpt Post | **V1** receipt posting (falls back to remaining qty when Qty-to-Receive = 0). |
| 50123 | BVR Custom Rcpt Post V2 | **V2 "SAFE"** receipt posting — posts only lines with `Qty. to Receive > 0`. *Current path.* |
| 50140 | BVR Create Custom Invoice | Builds a Custom Invoice header/lines from a posted custom receipt. |
| 50141 | BVR Get Custom Receipt Lines | Pulls posted custom-receipt lines into invoice lines. |
| 50142 | BVR Custom Inv Post | Posts the custom invoice (accrual reversal + variance + tax). |
| 50150 | BVR Get Released PO Lines | Collects outstanding released-PO lines into the custom receipt. |
| 50240 | BVR Receipt Approval Mgt | Approval state machine (AP Updated → Send → Approve / Send Back). |
| 50250 | BVR Posting Preview Mgt | Builds receipt & invoice posting previews. |
| 50320 | BVR Copy Attachments | Copies Document Attachments to the posted receipt. |
| 50xxx | BVR Custom Inv Statistics | Invoice statistics calc. |
| 70462 | PO→ISE Orchestrator | Copies a Released PO into an ISE Customer Order. |
| 70463 | PO Post Guard | Blocks standard posting of POs sent to ISE. |

### Pages / Page extensions
Custom Receipt card/list/lines, Custom Invoice card/list/lines, Posted Receipts list,
Approval Card & Queue, Released PO Lines, Posting Preview, Tax/Prepayment FactBoxes,
attachment PageExts, `PO Ext — Send to ISE` (70461), `BVR Purchasing Menu Ext` (Role
Center actions), Custom Invoice statistics.

### Reports
- `BVR Custom Receipt Report` / `BVRCustomReceipt.rdlc`
- `BVR Custom Invoice Report` / `BVRCustomInvoice.rdlc`
- `BVR Custom Purchase Receipt`, `BVR Inv Posting Preview`

### Permission sets
- `GeneratedPermission` (50100) — all BVR objects.
- `ISE.PO2ISE` (70460) — PO→ISE bridge objects + ISE Customer Order tabledata.
- `BVR Custom Receipt` — receipt-feature set.

---

## 4. Configuration & dependencies

**Hard runtime dependencies the code assumes exist (these are not created by the app):**
- Journal **template/batch** `ITEM` / `DEFAULT` (item journal) and `GENERAL` / `DEFAULT`
  (general journal) — hardcoded in the posting codeunits.
- `Purchases & Payables Setup` no. series: `Posted Receipt Nos.`, `Posted Invoice Nos.`,
  `Invoice Nos.`
- `Tax Setup."Tax Account (Purchases)"` and a working **Sales Tax** area/group setup.
- Per-document accrual G/L accounts: `BVR Vendor Accrual Acc No.` and
  `BVR Expense Accrual Acc No.` (entered by the user on the header).
- The **InventoryISEMovement** dependency app, providing `ISE Customer Order Header/Line`
  and `ISE Receiving Card`, plus the `Vendor No`, `Sent From Purchase`,
  `Linked Purchase Order No.` fields the orchestrator probes via `FieldNo(...)`.

**Dev environment:** `.vscode/launch.json` targets a cloud sandbox
(`InventorySandbox`, tenant `a7db…faa`). There is **no `.gitignore` / git repo** and
**no test app** in this folder.

---

## 5. Known issues, risks & technical debt

These are the things to fix or design around before extending the app.

1. **Bypasses standard BC posting.** Receipt/invoice posting is re-implemented by
   hand (manual `Purch. Rcpt. Header/Line` inserts + raw G/L/item-ledger journals).
   This sidesteps native validations, application/costing, dimensions priority,
   number-series-per-doc rules, and undo-receipt. Any BC upgrade or audit needs to
   account for this. Treat it as the single biggest architectural risk.

2. **Two divergent receipt posters (50122 vs 50123).** V1 falls back to "remaining
   quantity" when `Qty. to Receive = 0`; V2 posts only explicit `Qty. to Receive`.
   Only one should survive. Decide, delete the other, and remove it from the
   permission set to avoid accidental wrong-path posting.

3. **Bug in `BVR Get Custom Receipt Lines` (50141), lines ~30–32.** Missing
   `begin…end`: only `BVR Vendor Accrual Acc No.` is inside the `if FindSet()` guard;
   `BVR Expense Accrual Acc No. := …` and `InvHdr.Modify()` run **unconditionally**,
   so an empty receipt still triggers `Modify` and the expense account copy isn't
   guarded. Wrap both assignments + `Modify` in the guard.

4. **Hardcoded journal template/batch names** (`ITEM/DEFAULT`, `GENERAL/DEFAULT`).
   These will fail on any tenant that names batches differently. Move to a setup table.

5. **Header-level accrual dimensions.** Accrual G/L is posted "clubbed" using
   *header* `Dimension Set ID`, even though lines may carry different dimensions —
   the receipt line-level dimensions don't flow to the accrual entry. Confirm this
   is intended for reporting.

6. **No automated tests.** No test codeunits / test app. Given the manual posting
   math, regression tests for the accrual/reversal/tax amounts are high-value.

7. **Defensive `FieldNo(...) <> 0` probing in the orchestrator.** Because the ISE
   fields are in a separate app, the orchestrator checks field existence at runtime.
   `FieldNo` is resolved at compile time against the dependency, so these guards are
   mostly cosmetic — but they signal a fragile coupling to the ISE schema.

8. **Code style.** Many files are densely formatted (multiple statements per line,
   single-line `repeat…until`). It compiles, but it's hard to diff and review.
   A one-time `AL Formatter` pass would help future work.

9. **Naming/spelling.** App name "PurchaseReciept", menu caption "Custom Purcchase
   Invoice", mixed `BVR`/`PO→ISE`/`ISE` prefixes and 50xxx/70xxx ranges. Cosmetic but
   worth normalizing if the app is going to grow.

10. **Not under source control.** Initialize git before further work so changes are
    reviewable and revertible.

---

## 6. Suggested further-development backlog

Ordered by value/risk. Pick from the top.

### P0 — stabilize
- [ ] **`git init`** + `.gitignore` (ignore `.alpackages/`, `*.app`, `.snapshots/`,
      `rad.json`), commit the current state as a baseline.
- [ ] Fix the **50141 `begin…end` guard** bug (§5.3).
- [ ] **Choose one receipt poster** (V1 vs V2), delete the other, update the permission set.
- [ ] Add a **test app** (separate folder, `test` runtime) covering: receive math,
      accrual G/L balance = 0, invoice reversal + variance + tax, idempotency
      (already-posted guards), and the PO Post Guard block.

### P1 — correctness & configurability
- [ ] Move hardcoded **journal template/batch** names into a setup table
      (e.g. "BVR Receiving Setup") with `TestField` validation on first use.
- [ ] Make accrual G/L accounts **defaultable** from setup/vendor instead of manual
      per-document entry; validate they exist and are direct-posting.
- [ ] Decide and implement **line-level vs header-level dimensions** for accruals.
- [ ] Add an **undo / reversal** path for a posted custom receipt (today there's no
      way back once `BVR Custom Rcpt Posted = true`).

### P2 — feature & UX
- [ ] **Unify the two receiving flows** (BVR custom vs PO→ISE) or document clearly
      when each is used; today a PO could be pushed down both.
- [ ] Surface **approval status** and accrual balances on the Role Center / a FactBox.
- [ ] Multi-currency: the invoice tax uses `ExchRate := 1` (LCY only). Add real FX.
- [ ] Telemetry (`Session.LogMessage`) around posting for cloud diagnostics.

### P3 — housekeeping
- [ ] Run **AL Formatter** across all files; enforce via `.editorconfig` / `AppSourceCop`.
- [ ] Normalize object **naming/prefix/ID ranges**; fix user-facing typos.
- [ ] Add `AppSourceCop.json` / `app.json` `internalsVisibleTo` if a test app is added.

---

## 7. How to build & run

1. Open the folder in VS Code with the **AL Language** extension (the build was made
   with AL `17.0.2273547`, compiler `17.0.34.45391`).
2. Ensure the **InventoryISEMovement** symbol app is available in `.alpackages`
   (download symbols: `AL: Download Symbols`).
3. Publish to the sandbox defined in `.vscode/launch.json` (`Microsoft cloud sandbox`,
   environment `InventorySandbox`). Update `tenant`/`environmentName` for your own tenant.
4. Assign permission set **`GeneratedPermission`** (and `ISE.PO2ISE` for the bridge).

### Smoke test (custom flow)
Released PO(s) for a vendor → new Custom Receipt order (`BVR Receive PO` = true) →
**Get Released PO Lines** → enter `Qty. to Receive` + accrual accounts → **Preview** →
**Post** → **Create Custom Invoice** → **Get Receipt Lines** → **Preview** → **Post**.
Verify the accrual G/L nets to zero after invoicing and `Quantity Received` updated on
the source PO.

---

*Generated 2026-06-15 as an onboarding/handoff document. Update it as the code changes.*
