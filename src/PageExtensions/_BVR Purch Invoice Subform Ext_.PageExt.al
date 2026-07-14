pageextension 50113 "BVR Purch Invoice Subform Ext" extends "Purch. Invoice Subform"
{
    // Show the line-level accrual accounts pulled by Get Receipt Lines (Accrual). The Vendor
    // Accrual account drives the invoice-post redirect (Dr Vendor Accrual / Cr Vendor) done by
    // "BVR Std Get Receipt Lines"; the Expense account is shown for reference.   //AAV
    layout
    {
        addlast(PurchDetailLine)
        {
            field("BVR Vendor Accrual Acc No."; Rec."BVR Vendor Accrual Acc No.")   //AAV
            {
                ApplicationArea = All;
                ToolTip = 'Vendor Accrual (GRNI) account this line posts to at invoicing, reversing the receipt accrual. Copied from the source receipt by Get Receipt Lines (Accrual).';
            }
            field("BVR Expense Accrual Acc No."; Rec."BVR Expense Accrual Acc No.")   //AAV
            {
                ApplicationArea = All;
                ToolTip = 'Expense Accrual account booked for this line at receipt. Shown for reference.';
            }
        }
    }
}
