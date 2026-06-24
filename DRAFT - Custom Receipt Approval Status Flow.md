# DRAFT — Custom Receipt Approval Status Flow

Status: **DRAFT for review** — no code written yet.
Date: 2026-06-22

## Goal

Replace the current boolean-driven ordering with a single, visible **Status** on the
Custom Purchase Receipt, and **reorder** the flow so the AP team updates the accrual
accounts *before* the approval process runs.

### Requested flow

1. Custom receipt (Order with `BVR Receive PO`) is created → **Open**.
2. User sends it to the AP team to update the accrual accounts → **Sent to AP Team**.
3. AP team updates the accrual accounts, then submits to approval → **Pending Approval**.
4. All approvals complete → **Released** (ready to post).

> This is the reverse of today's flow, where approval happens first and *AP Updated*
> happens after approval.

## Current flow (for contrast)

`Released PO → Send Approval Request → workflow approves (BVR Approved) → AP team marks
"AP Updated" → Post Receipt`

Driven by booleans on `Purchase Header`: `BVR Sent For Approval`, `BVR Approved`,
`BVR AP Updated`, `BVR Requires Approval`.

## Proposed design

### 1. New status enum

New file `src/Enums/_BVR Receipt Status_.Enum.al`:

```al
enum 50100 "BVR Receipt Status"
{
    Extensible = true;
    value(0; Open)            { Caption = 'Open'; }
    value(1; "Sent to AP Team") { Caption = 'Sent to AP Team'; }
    value(2; "Pending Approval") { Caption = 'Pending Approval'; }
    value(3; Released)        { Caption = 'Released'; }
    value(4; Posted)          { Caption = 'Posted'; }   // optional, after custom receipt posts
}
```

### 2. New field on Purchase Header

In `_BVR Purch Header Approval Ext_.TableExt.al`:

```al
field(50205; "BVR Receipt Status"; Enum "BVR Receipt Status")
{
    Caption = 'Receipt Status';
    DataClassification = CustomerContent;
    Editable = false;
}
```

The existing booleans (`BVR Sent For Approval`, `BVR Approved`, `BVR AP Updated`) are
**kept** and stay in sync with the status, so existing posting/preview logic that reads
them keeps working. `BVR Receipt Status` becomes the single thing shown to users.

| Status            | BVR AP Updated | BVR Sent For Approval | BVR Approved |
|-------------------|:--:|:--:|:--:|
| Open              |  -  |  -  |  -  |
| Sent to AP Team   |  -  |  -  |  -  |
| Pending Approval  | yes | yes |  -  |
| Released          | yes | yes | yes |
| Posted            | yes | yes | yes |

### 3. State transitions & who triggers them

| Action | From → To | Who | Notes |
|--------|-----------|-----|-------|
| **Send to AP Team** | Open → Sent to AP Team | Creator | Requires lines + `BVR Requires Approval`. Unlocks accrual accounts for AP team. |
| **AP Updated & Submit for Approval** | Sent to AP Team → Pending Approval | AP team only | AP team edits accrual accounts first, then this raises the native workflow (`OnSendCustomReceiptForApproval`). Sets `BVR AP Updated = true`, `BVR Sent For Approval = true`. |
| Approve / Reject / Delegate | (workflow) | Approvers | Standard `Approvals Mgmt.` |
| **Approval complete** | Pending Approval → Released | Workflow response | `BVRSETCUSTRCPTAPPROVED` response sets `BVR Approved = true` **and** status = Released. |
| Reject / Cancel | Pending Approval → Sent to AP Team | Workflow / user | Reset `BVR Approved`/`BVR Sent For Approval`; keep AP Updated so AP team need not redo. |
| **Post Receipt** | Released → Posted | User | Enabled only when status = Released. |

### 4. Accrual-account editability (revised)

Editable **only while status = Sent to AP Team, and only by AP team users** (plus the
existing rule that nothing is editable once the custom receipt is posted). This matches
"send to AP team for update the accrual account."

`AccrualAccountsEditable` in `BVR Cust Rcpt Appr Mgt` becomes:

```al
if PurchaseHeader."BVR Custom Rcpt Posted" then exit(false);
exit((PurchaseHeader."BVR Receipt Status" = "BVR Receipt Status"::"Sent to AP Team") and IsAPTeam());
```

(Open for discussion: should the creator also be able to set accruals while Open? Default
proposal: no — accruals are the AP team's job.)

## Objects to add / change

**New**
- `src/Enums/_BVR Receipt Status_.Enum.al` (enum 50100)

**Changed**
- `src/TableExtensions/_BVR Purch Header Approval Ext_.TableExt.al` — add `BVR Receipt Status`.
- `src/Codeunits/_BVR Cust Rcpt Appr Mgt_.Codeunit.al`
  - new `SendToAPTeam()` (Open → Sent to AP Team)
  - rework `MarkAPUpdated()` → `MarkAPUpdatedAndSubmit()` (Sent to AP Team → Pending Approval; raises workflow)
  - update `ResetCustomReceiptFlags` to drop status back to Sent to AP Team
  - update `AccrualAccountsEditable`
- `src/Codeunits/_BVR Cust Rcpt Appr Resp_.Codeunit.al` — set status = Released on approval.
- `src/Pages/_BVR Custom Purch Receipt_.Page.al`
  - show `BVR Receipt Status`
  - add **Send to AP Team** action (status = Open)
  - relabel/regate the AP-team action to **AP Updated & Submit for Approval** (status = Sent to AP Team, AP team)
  - gate the existing Approve/Reject/Delegate & Post on the new status
- `src/Pages/_BVR Receipt Approval Queue_.Page.al` / `_BVR Receipt Approval Card_.Page.al` — show status, adjust filters.

## Open questions

1. Should the standard purchase **Release** still happen (and when), or is the new
   "Released" status the only release concept the user sees?
2. Does the AP team submit to approval in one click (**AP Updated & Submit**), or two
   separate clicks (mark AP Updated, then a separate Send for Approval)?
3. On reject, drop back to **Sent to AP Team** (AP work preserved) or all the way to
   **Open**?
4. Keep the legacy boolean-flow pages/codeunit (`BVR Receipt Approval Mgt`) or retire them?
