# Sales Invoice API — Integration Guide

Status: **For integration / built**
Date: 2026-08-25
Author: ISE (PurchaseReceipt app)

---

## 1. Purpose

A custom OData v4 API for creating draft **Sales Invoices** in Business Central from
an external system.

It exists because Microsoft's standard `/api/v2.0/salesInvoices` endpoint **cannot be
extended with custom fields**. This endpoint is a separate, wholly owned surface, so
fields such as the posting batch number can be carried on it — and more can be added
later without waiting on Microsoft.

The field names deliberately follow **Microsoft's own vocabulary** (`number`,
`customerNumber`, `invoiceDate`, `lineType`, …). A client already written against the
standard API needs only its base path changed to point here.

### What it does not do

The invoice is created **Open, not posted**. Posting is a separate decision with its
own approval and its own batch. An integration that posts as a side effect of
receiving a document is an integration nobody can stop once it is wrong.

---

## 2. Objects

| Object | ID | File |
|---|---|---|
| Page `BVR Sales Invoice API` | 50170 | [_BVR Sales Invoice API_.Page.al](src/Pages/_BVR%20Sales%20Invoice%20API_.Page.al) |
| Page `BVR Sales Invoice Line API` | 50171 | [_BVR Sales Invoice Line API_.Page.al](src/Pages/_BVR%20Sales%20Invoice%20Line%20API_.Page.al) |
| Enum `BVR API Sales Line Type` | 50170 | [_BVR API Sales Line Type_.Enum.al](src/Enums/_BVR%20API%20Sales%20Line%20Type_.Enum.al) |

Source tables are the standard `Sales Header` and `Sales Line`, filtered to
`Document Type = Invoice`.

---

## 3. Endpoint

```
/api/ise/integration/v1.0/companies({companyId})/iseSalesInvoices
```

Assembled from the page properties `APIPublisher = 'ise'`, `APIGroup = 'integration'`,
`APIVersion = 'v1.0'`, `EntitySetName = 'iseSalesInvoices'`.

**BC cloud (SaaS)**

```
https://api.businesscentral.dynamics.com/v2.0/{tenantId}/{environment}/api/ise/integration/v1.0/companies({companyId})/iseSalesInvoices
```

**BC on-premises**

```
https://{server}:7048/{instance}/api/ise/integration/v1.0/companies({companyId})/iseSalesInvoices
```

### Placeholders

| Placeholder | How to get it |
|---|---|
| `{tenantId}` | Azure AD tenant GUID (SaaS only) |
| `{environment}` | Environment name — `Production`, `Sandbox`, … (SaaS only) |
| `{companyId}` | **GUID**, not the company name — from `GET .../v1.0/companies` |

`{companyId}` goes in parentheses, unquoted: `companies(a1b2c3d4-e5f6-…)`.

### Operations

| Purpose | Method and path |
|---|---|
| List companies | `GET .../v1.0/companies` |
| Schema / reachability check | `GET .../v1.0/$metadata` |
| Create invoice with lines | `POST .../companies({companyId})/iseSalesInvoices` |
| Add a line to an invoice | `POST .../companies({companyId})/iseSalesInvoices({id})/iseSalesInvoiceLines` |
| Read invoices with lines | `GET .../companies({companyId})/iseSalesInvoices?$expand=iseSalesInvoiceLines` |
| Update an invoice | `PATCH .../iseSalesInvoices({id})` — requires `If-Match` |
| Delete an invoice | `DELETE .../iseSalesInvoices({id})` — requires `If-Match` |

`{id}` is the invoice's `SystemId` GUID, returned as `id` on every response.

Have the external system call `$metadata` first. It confirms the extension is
installed and the endpoint is reachable before anyone tries to post real data.

---

## 4. Authentication

Standard Business Central API authentication — nothing specific to this endpoint.

- **SaaS**: OAuth 2.0 client credentials against Azure AD, scope
  `https://api.businesscentral.dynamics.com/.default`. The app registration needs an
  Entra application user in BC with a permission set granting the objects above.
- **On-premises**: OAuth 2.0, or NavUserPassword / Windows depending on the service
  instance's configured credential type.

The calling user needs permission to insert `Sales Header` and `Sales Line`.

---

## 5. Request body

`POST .../companies({companyId})/iseSalesInvoices`

```
Content-Type: application/json
```

```json
{
  "number": "PIN20251200000",
  "customerNumber": "CS2018040003",
  "externalDocumentNumber": "MES_2026FEB",
  "invoiceDate": "2026-02-26",
  "postingDate": "2026-02-26",
  "dueDate": "2026-04-26",
  "customerPurchaseOrderReference": "PO-013435",
  "currencyCode": "USD",
  "shortcutDimension1Code": "ADMIN",
  "shortcutDimension2Code": "SITE-A",
  "batchNumber": "SIB-0001",
  "iseSalesInvoiceLines": [
    {
      "lineType": "Item",
      "lineObjectNumber": "1000",
      "description": "Bicycle",
      "quantity": 5,
      "unitPrice": 100.0,
      "shipmentDate": "2026-02-26",
      "shortcutDimension1Code": "ADMIN",
      "shortcutDimension2Code": "SITE-A"
    }
  ]
}
```

### 5.1 Header fields

| JSON field | BC field | Required | Notes |
|---|---|---|---|
| `number` | No. | No | Omit and the number series assigns one. Sent twice, the second POST fails on the primary key rather than quietly creating a duplicate — which is what an integration wants. |
| `customerNumber` | Sell-to Customer No. | **Yes** | Blank is rejected with an explicit error. |
| `externalDocumentNumber` | External Document No. | No | The sending system's own reference. |
| `invoiceDate` | Document Date | No | `yyyy-MM-dd` |
| `postingDate` | Posting Date | No | `yyyy-MM-dd` |
| `dueDate` | Due Date | No | Derived from the customer's payment terms if omitted. |
| `customerPurchaseOrderReference` | Your Reference | No | |
| `currencyCode` | Currency Code | No | Blank means local currency. |
| `shortcutDimension1Code` | Shortcut Dimension 1 Code | No | Blank means "keep the customer's default", not "clear it". |
| `shortcutDimension2Code` | Shortcut Dimension 2 Code | No | As above. |
| `batchNumber` | BVR Doc Batch No. | No | Drops the invoice straight into an open posting batch, so an integrated invoice is reviewed and posted with the rest of the run instead of on its own. |

### 5.2 Line fields

| JSON field | BC field | Notes |
|---|---|---|
| `lineType` | Type | See 5.3 |
| `lineObjectNumber` | No. | Item / G/L account / resource number — must match `lineType` |
| `description` | Description | Defaults from the item or account; a value sent by the caller wins |
| `quantity` | Quantity | |
| `unitPrice` | Unit Price | Defaults from the price list; a value sent by the caller wins |
| `shipmentDate` | Shipment Date | |
| `shortcutDimension1Code` | Shortcut Dimension 1 Code | Blank inherits the invoice's |
| `shortcutDimension2Code` | Shortcut Dimension 2 Code | Blank inherits the invoice's |

### 5.3 Line types

`lineType` uses **the caller's vocabulary, not Business Central's**, and is translated
on the way in. This is Microsoft's own API wording, so a client written against the
standard API needs no changes.

| `lineType` sent | Sales Line Type used |
|---|---|
| `Comment` | ` ` (blank) |
| `Account` | G/L Account |
| `Item` | Item |
| `Resource` | Resource |
| `Fixed Asset` | Fixed Asset |
| `Charge` | Charge (Item) |

### 5.4 Read-only fields — never send these

| Level | Fields |
|---|---|
| Header | `id`, `status`, `lastModifiedDateTime` |
| Line | `id`, `documentNumber`, `sequence`, `amountExcludingTax`, `amountIncludingTax` |

`amountExcludingTax` and `amountIncludingTax` are **calculated** by BC from quantity ×
price. The amounts in the response are BC's own, and should be treated as the answer,
not as an echo of what was sent.

---

## 6. Response

`201 Created`, with the created invoice — including the fields BC defaulted or
calculated, and the lines it wrote.

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "number": "PIN20251200000",
  "customerNumber": "CS2018040003",
  "externalDocumentNumber": "MES_2026FEB",
  "invoiceDate": "2026-02-26",
  "postingDate": "2026-02-26",
  "dueDate": "2026-04-26",
  "currencyCode": "USD",
  "status": "Open",
  "shortcutDimension1Code": "ADMIN",
  "shortcutDimension2Code": "SITE-A",
  "batchNumber": "SIB-0001",
  "lastModifiedDateTime": "2026-08-25T09:14:22.123Z"
}
```

Store the returned `id`. It is the key for every later `GET`, `PATCH`, `DELETE` and
line-level POST.

---

## 7. Deep insert — and the fallback

Sending header and lines in **one** POST relies on Business Central's deep insert. The
header page carries `DelayedInsert = true` so the framework can hold the children until
it has a parent to link them to.

> **This has not yet been verified against the target environment.** Test it before go-live.

If the single call errors, split it into a two-step sequence:

1. `POST .../iseSalesInvoices` with the header only — drop `iseSalesInvoiceLines`
2. Read `id` from the response
3. `POST .../iseSalesInvoices({id})/iseSalesInvoiceLines` once per line

The single call is one round trip instead of N+1, so it is worth trying first.

---

## 8. Why the API rebuilds the record instead of letting the framework write it

Worth knowing, because it explains behaviour a caller will otherwise find surprising.

The OData framework fills the record straight from the JSON, **field by field, in
arbitrary order, with no validation**. A `Sales Header` will not tolerate that:

- validating the customer resets the dates, the currency and the prices,
- validating the posting date re-reads the exchange rate,
- a due date written before the customer is silently replaced by the payment terms',
- and validating the customer rebuilds the dimension set from the customer's defaults,
  discarding any dimension code written before it.

So both pages take the values off the incoming record, insert a clean one, and then
**validate** each value back on **in the order the table expects** — customer, posting
date, document date, currency, due date, references, then the two global dimensions,
then the batch. On the lines: type, number, description, quantity, unit price, then
dimensions.

Two consequences the caller should know:

- **Dimensions are validated, not assigned.** `Validate` applies the code as a delta to
  the `Dimension Set ID`, which is what the posting routines and every dimension-based
  report actually read. A bare assignment would leave the set behind, and the invoice
  would post on the customer's dimensions instead of the caller's.
- **Omitted is not the same as blank.** Every assignment is guarded, so anything the
  caller does not send is left for Business Central to default. A caller that genuinely
  wants *no* dimension has to clear it on the customer, not send an empty string.

`PATCH` follows the same rule: only fields that actually changed are re-validated, so a
PATCH that moves the posting date re-reads the exchange rate exactly as a POST does.

---

## 9. Naming

The entity is `iseSalesInvoice` / `iseSalesInvoices`, prefixed to be unmistakable in
logs and in the external team's configuration.

There was never a technical collision with Microsoft's `salesInvoices` —
`APIPublisher = 'ise'` and `APIGroup = 'integration'` already place this endpoint on a
wholly separate path from `/api/v2.0/`. The prefix is for readability.

**The nested array renames with the entity**: the lines collection in the request body
is `iseSalesInvoiceLines`, not `salesInvoiceLines`. Anything pointed at the earlier,
unprefixed name must be updated.

---

## 10. Adding custom fields later

This is the reason the endpoint exists, so the path is short:

1. Add the field to `Sales Header` / `Sales Line` via a table extension.
2. Add a `field(camelCaseName; Rec."Field Name")` to the API page, inside the repeater.
3. If it needs validating in a particular order, lift it off `Rec` in `OnInsertRecord`
   and `Validate` it in the right place in the sequence — see section 8.
4. Mirror it in `OnModifyRecord` if `PATCH` should accept it.
5. Bump `APIVersion` only if the change breaks existing callers. Adding a field does
   not.
