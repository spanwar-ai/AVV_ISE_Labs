pageextension 50101 "Posted Purchase Invoice Ext" extends "Posted Purchase Invoice"
{
    layout
    {
        addlast(General)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")   //AAV.SP
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the batch this invoice was posted from.';
            }
            field("BVR Vendor Accrual Acc No."; Rec."BVR Vendor Accrual Acc No.")   //AAV
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Vendor Accrual (GRNI) account this invoice reverses. Copied from the source receipt by Get Receipt Lines (Accrual).';
            }
            field("BVR Expense Accrual Acc No."; Rec."BVR Expense Accrual Acc No.")   //AAV
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Expense Accrual account booked at receipt. Copied from the source receipt for reference.';
            }
        }

    }
}
