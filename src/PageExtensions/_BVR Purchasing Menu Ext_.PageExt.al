pageextension 50130 "BVR Purchasing Menu Ext" extends "Business Manager Role Center"
{
    actions
    {
        addafter("<Page Purchase Orders>")
        {
            action("Custom Purchase Receipts")
            {
                ApplicationArea = All;
                Caption = 'Custom Purchase Receipts';
                Image = Receipt;
                RunObject = page "BVR Custom Purch Receipt List";
            }
            action("BVR Receipt Approval Queue")
            {
                ApplicationArea = All;
                Caption = 'Receipt Approvals';
                Image = Receipt;
                RunObject = page "BVR Receipt Approval Queue";
            }
        }
        addafter("<Page Purchase Invoices>")
        {
            action("Custom Purcchase Invoice")
            {
                ApplicationArea = All;
                Caption = 'Custom Purchase Invoices';
                Image = Receipt;
                RunObject = page "BVR Custom Purch Invoice List";
            }
        }
    }
}
