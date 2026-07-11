// // Extends the standard NA "Purchase Receipt" report (ID 10124) to expose the custom
// // accrual accounts on the printout. The values come from the posted receipt header
// // (table 122) fields added by tableextension 50115 "BVR Purch Rcpt Header Ext":
// //   - BVR Expense Accrual Acc No. -> "Expense Account (Dr.)"
// //   - BVR Vendor Accrual Acc No.  -> "Accrual G/L (Cr.)"
// // BVRIsCustomReceipt drives layout visibility so the accounts print ONLY for custom
// // receipts (Purch. Rcpt. Header."BVR Custom Receipt" = true).
// //
// // PREREQUISITES / VERIFY against your localized symbols before compiling:
// //   1. Report 10124's object NAME  -> assumed "Purchase Receipt" (in `extends`).
// //   2. The header DATAITEM name    -> assumed "Purch. Rcpt. Header" (in `add(...)`).
// //   Report 10124 is not in the W1 Base Application symbols shipped in .alpackages;
// //   download symbols from your (localized) environment so this report resolves.
// reportextension 50145 "BVR Purch Receipt Rep Ext" extends "Purchase Receipt"
// {
//     dataset
//     {
//         add("Purch. Rcpt. Header")
//         {
//             column(BVRIsCustomReceipt; "BVR Custom Receipt")
//             {
//             }
//             column(BVRExpenseAccrualAcc; "BVR Expense Accrual Acc No.")
//             {
//             }
//             column(BVRVendorAccrualAcc; "BVR Vendor Accrual Acc No.")
//             {
//             }
//         }
//     }
// }
