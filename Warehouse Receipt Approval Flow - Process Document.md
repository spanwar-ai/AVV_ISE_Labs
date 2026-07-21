# Warehouse Receipt Approval Flow — Process Document

Status: **Design / for-build**
Date: 2026-07-18
Author: ISE (PurchaseReceipt app)

---

## 1. Purpose

Move the AP → approval → accrual receiving flow onto the **standard Warehouse
Receipt** document (e.g. `WR0001`), so that:

- the Purchase Order is released normally (no approval, no accrual G/L on the PO),
- the accrual G/L accounts and the approval status flow live on the **Warehouse
  Receipt**,
- receiving is posted through the **standard** pipeline (Whse.-Post Receipt →
  Purch.-Post), which natively gives us a Purchase Receipt, a Posted Warehouse
  Receipt with line data, and the WR-No. linkage — including non-inventory lines.

This replaces the hand-written "Custom Receipt" posting (Flow A) with a
standard-posting design that keeps the same user-facing status flow.

### Target flow

| # | Step | Where |
|---|------|-------|
| 1 | Release Purchase Order — no approval, no accrual G/L on header | Standard PO |
| 2 | Create Warehouse Receipt, select vendor + PO, pull lines (Qty. to Receive blank) | WR `WR0001` |
| 3 | **Send to AP** → AP fills **two accrual G/L accounts** → **Send for Approval** | WR |
| 4 | Status walks **Open → Pending with AP → Pending Approval → Released** | WR |
| 5 | Post the Warehouse Receipt → Purchase Receipt is created | Standard posting |
| 6 | WR is deleted; **WR No. flows to the Purchase Receipt** | Native + stamp |
| 7 | **Posted Warehouse Receipt retains line data** (incl. non-inventory) | Native + CU 50128 |

### Prerequisites & constraints

- The receiving **Location must have "Require Receive" = true** (a WR only exists
  for such locations). The non-inventory subscriber already assumes this.
- **One vendor / one source PO per Warehouse Receipt** — the two accrual accounts
  sit on the WR *header*, so a single WR must not mix vendors. (If mixed vendors
  are ever required, the accounts move to the WR *line* — out of scope here.)
- Reuses existing objects: `BVR Whse Rcpt Non-Inv` (CU 50128, non-inventory lines),
  `BVR Std Rcpt Accrual` (CU 50125, accrual posting), `BVR Std Get Receipt Lines`
  (CU 50127, invoicing), and the `BVR Receipt Status` enum (50101).
- **Decision to confirm before Step 2:** retire the legacy PO-based "Custom
  Receipt" (Flow A) so the app carries one receiving flow, not three.

---

## Step 1 — Warehouse Receipt foundation (data, UI, posting gate)

**Objective:** Make the Warehouse Receipt carry the accrual accounts and a visible
status, block posting until it is Released, and stamp the WR No. onto the Purchase
Receipt. No approval logic yet — everything is testable by setting status manually.

**Tasks**
1. **TableExt on "Whse. Receipt Header" (7316)** — add:
   - `BVR Vendor Accrual Acc No.` (G/L account)
   - `BVR Expense Accrual Acc No.` (G/L account)
   - `BVR Receipt Status` (reuse enum 50101)
   - `BVR Sent To AP Team` (Boolean marker)
2. **TableExt on "Purch. Rcpt. Header"** — add `BVR Source Whse Receipt No.`
   (carries the WR No. onto the posted Purchase Receipt).
3. **PageExt on "Warehouse Receipt" (7316)** — show Status + the two accrual
   accounts; make the accounts editable only while `Sent to AP Team` and only for
   AP-team users (mirror `AccrualAccountsEditable`).
4. **Qty. to Receive blank** — subscriber on Get Source Documents to zero
   `Qty. to Receive` after lines are pulled, so the user enters it.
5. **Posting gate** — subscribe to the Whse.-Post Receipt pre-post event and
   `Error` unless `BVR Receipt Status = Released` (pattern: `_PO Post Guard_`).
6. **WR No. → Purchase Receipt** — subscribe to `OnAfterPostWhseReceipt`; write the
   WR No. into `Purch. Rcpt. Header."BVR Source Whse Receipt No."`.

**Objects:** 2 tableexts, 1 pageext, 1–2 small subscriber codeunits.
(`BVR Whse Rcpt Non-Inv` CU 50128 already covers non-inventory lines — no change.)

**Acceptance criteria**
- A WR can be created from a released PO; lines appear with Qty. to Receive blank.
- The two accrual accounts and Status are visible on the WR.
- Posting is blocked with a clear error unless Status = Released (set manually for
  this step's test).
- After posting: a Purchase Receipt exists, carries the WR No., and the Posted
  Warehouse Receipt shows line data (inventory **and** non-inventory).

**Risk / notes:** Low risk — additive, no approval framework yet. Confirm the exact
Get-Source-Documents event used for the "Qty. to Receive blank" tweak on your BC 28
base app.

---

## Step 2 — Approval & AP flow on the Warehouse Receipt

A Warehouse Receipt is **not** natively approvable, so this is the largest piece.
It is split into two parts so the whole status/UI/AP experience is proven **before**
the tricky native-approval plumbing is added.

- **Part 2A — Status machine + AP hand-off** (self-contained; manual Release).
- **Part 2B — Native approval engine** (replaces the manual Release with real approvals).

Each part compiles and is testable on its own. 2A carries no dependency on the
Workflow/Approvals setup, so it de-risks 2B.

### Part 2A — "Send to AP" action, then reveal "Send for Approval"

**Objective:** Add the hand-off buttons and status/editability UI. The creator clicks
**Send to AP** (visible only at Open), which moves the WR to **Sent to AP Team** and
notifies the AP team. Once at Sent to AP Team, the **Send for Approval** button
becomes **visible** and the AP team can edit the accrual accounts. The engine behind
Send for Approval is wired in 2B — in 2A the button is present and correctly gated.
No native Workflow dependency.

**Tasks**
1. **WR management codeunit** (`BVR Whse Rcpt Appr Mgt`, template: the Purchase-Header
   `BVR Cust Rcpt Appr Mgt`, retargeted to table 7316):
   - `SendToAPTeam` (Open → Sent to AP Team) — set `BVR Requires Approval` +
     `BVR Sent To AP Team`, email the AP team (reuse `GetAPRecipients`).
   - `IsAPTeam()` + `AccrualAccountsEditable()` (Sent to AP Team **and** AP-team user).
   - `Reopen` (any → Open) — clear markers/status.
2. **WR page actions & gating** (extend pageext 50114):
   - **Send to AP** — Visible/Enabled only when Status = Open.
   - **Send for Approval** — Visible only when Status = Sent to AP Team; Enabled once
     both accrual accounts are filled and the user is AP team. (Action stub in 2A; its
     workflow call is added in 2B.)
   - **Reopen** — visible once past Open.
   - Accrual accounts editable only via `AccrualAccountsEditable` (replaces the Step 1
     "editable until Released" placeholder).
3. **Vendor/PO selection UX (F5)** — a **Get PO Lines** action that filters *Get
   Source Documents* by the chosen vendor / purchase order.

**Objects:** 1 management codeunit, pageext 50114 (actions + editability), reuse of
AP-email helpers and User Setup `BVR AP Team`.

**Acceptance criteria**
- **Send to AP** shows at Open; clicking it sets Status = Sent to AP Team and notifies AP.
- After that, **Send for Approval** is visible; it enables only when both accrual
  accounts are filled and the user is AP team.
- Only AP-team users can edit the accrual accounts at Sent to AP Team; others cannot.
- Reopen returns the WR to Open and clears the markers.

**Risk / notes:** Low–medium. Pure status/field/visibility logic; no Workflow engine yet.

### Part 2B — Approval process behind "Send for Approval"

**Objective:** Wire **Send for Approval** to the native Approvals/Workflow. The AP team
updates the accrual accounts, then clicks Send for Approval → the workflow raises
approval entries (Status → **Pending Approval**) → approvers approve → Status =
**Released** (Step 1's posting gate opens). Reject/cancel → back to Sent to AP Team.

**Tasks**
1. **Approval glue for table 7316** (template: `BVR Cust Rcpt Appr WF Setup / Events /
   Resp`, retargeted — not reused):
   - WF-setup codeunit registering `OnSendWhseReceiptForApproval`.
   - Events codeunit (`OnSendWhseReceiptForApproval` / `OnCancel…`).
   - Response codeunit that sets Status = Released on approval completion.
   - `OnPopulateApprovalEntryArgument` for the WR (Amount = Σ line Direct Unit Cost ×
     Qty, to drive approver limits).
   - Because 7316 is not a purchase document, send/cancel use the generic
     `Approvals Mgmt.` RecordId path, not the purchase helpers.
2. **Wire `Send for Approval`** → `MarkAPUpdatedAndSubmit`: AP-team only, `TestField`
   both accrual accounts, raise the workflow, Status → Pending Approval.
3. **Approve / Reject / Delegate** actions on the WR page (standard approval actions).
4. **State sync on reject/cancel** — drop Pending Approval back to Sent to AP Team so
   AP work isn't lost (mirror `ResetCustomReceiptFlags`).

**Objects:** 3 approval codeunits, pageext 50114 (approve/reject/delegate actions),
Workflow setup data.

**Acceptance criteria**
- AP updates accruals then Send for Approval → Status = Pending Approval, approval
  entries created and routed.
- Approval completion sets Status = Released; reject/cancel returns to Sent to AP Team.
- Posting (Step 1's gate) succeeds only after real approval reaches Released.

**Risk / notes:** **Highest-risk part.** The generic-table approval branch needs
careful testing against your Workflow setup. Budget the bulk of the schedule here.

---

## Step 3 — Accrual posting, invoicing & posted-data integration

**Objective:** Book the two-account accrual at receipt post using the WR's accounts,
verify the full standard-posting outputs, and connect the invoicing side.

**Tasks**
1. **Feed accrual accounts from the WR to the poster** — at WR post, copy the WR's
   `BVR Vendor/Expense Accrual Acc No.` onto the PO lines being received **and** onto
   the resulting `Purch. Rcpt. Header` accrual fields, so:
   - `BVR Std Rcpt Accrual` (CU 50125) books Dr Expense Accrual / Cr Vendor Accrual
     with no change to its logic, and
   - the downstream invoice reads the same accounts.
2. **Verify posted outputs end-to-end** — Purchase Receipt created, WR No. stamped
   (Step 1), Posted Whse Receipt line data present incl. non-inventory (CU 50128),
   accrual G/L entry balanced.
3. **Invoicing** — `BVR Std Get Receipt Lines` (CU 50127) pulls the posted accrual
   receipt onto an invoice; standard invoice posting reverses Vendor Accrual → Vendor
   so the accrual nets to zero. Confirm accounts flow from the posted receipt.
4. **Retire Flow A** (if approved in prerequisites) — remove/disable the PO-based
   custom-receipt posting path and its permission-set entries.

**Objects:** 1 subscriber (accrual-account propagation at WR post); reuse CU 50125,
50127, 50128; permission-set / cleanup edits.

**Acceptance criteria**
- Posting a WR books exactly one accrual entry (Dr Expense / Cr Vendor) for the
  receipt's item lines at Direct Unit Cost; no double-posting.
- Creating and posting the invoice reverses the Vendor Accrual to Payables and the
  accrual account nets to zero after invoicing.
- Non-inventory and inventory lines both behave correctly through receipt and invoice.
- Only one receiving flow remains active (if Flow A retired).

**Risk / notes:** Watch the combined Receive+Invoice case (CU 50125 already skips it),
and confirm accrual accounts are present before posting (both `TestField`ed at Step 2
submit, so a posted WR always has them).

---

## Summary

| Step | Focus | Effort | Risk |
|------|-------|--------|------|
| 1 | WR data + UI + posting gate + WR-No. linkage | Small | Low | ✅ done |
| 2A | Status machine + AP hand-off + editability (manual Release) | Medium | Low–Med |
| 2B | Native approval engine (auto Release, approve/reject/delegate) | **Large** | Medium |
| 3 | Accrual posting + invoicing + integration/cleanup | Small–Med | Low–Med |

Steps 1 and 3 are largely wiring around machinery that already exists in the app.
Step 2 is the one substantial build (custom approval on a non-purchase document),
split so 2A proves the status/UI/AP flow before 2B adds the native approval engine.

### Open decisions
1. Retire the legacy PO-based Custom Receipt (Flow A)? *(recommended: yes)*
2. One vendor per WR enforced, or accrual accounts on the WR line for mixed vendors?
   *(recommended: one vendor per WR)*
3. AP submit in one click (AP Updated & Submit) or two? *(recommended: one)*
