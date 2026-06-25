tableextension 50116 "BVR Purch Rcpt Line Ext" extends "Purch. Rcpt. Line"
{
    fields
    {
        field(50100; "BVR Custom Receipt"; Boolean)
        {
            Caption = 'Custom Receipt';
            DataClassification = CustomerContent;
        }
        field(50101; "BVR Accrued Unit Cost"; Decimal)
        {
            Caption = 'Accrued Unit Cost';
            DataClassification = CustomerContent;
            DecimalPlaces = 0: 5;
        }
        field(50102; "BVR Accrued Amount"; Decimal)
        {
            Caption = 'Accrued Amount';
            DataClassification = CustomerContent;
        }
        field(50103; "BVR Invoiced Qty"; Decimal)
        {
            Caption = 'Invoiced Quantity (Custom)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0: 5;
        }
        field(50203; "BVR Source PO No."; Code[20])
        {
            Caption = 'Source PO No.';
            DataClassification = CustomerContent;
        }
        field(50204; "BVR Source PO Line No."; Integer)
        {
            Caption = 'Source PO Line No.';
            DataClassification = CustomerContent;
        }
        // Set once the custom accrual G/L entry for this line has been reversed by an
        // Undo Receipt, so the reversal can never be posted twice.   //AAV.SP
        field(50205; "BVR Accrual Reversed"; Boolean)   //AAV.SP
        {
            Caption = 'Accrual Reversed';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
