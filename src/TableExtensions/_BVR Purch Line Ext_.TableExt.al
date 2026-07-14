tableextension 50114 "BVR Purch Line Ext" extends "Purchase Line"
{
    fields
    {
        field(50100; "BVR From Custom Receipt"; Boolean)
        {
            Caption = 'From Custom Receipt';
            DataClassification = CustomerContent;
        }
        // Renumbered out of the 50100-50103 range to avoid a TransferFields type
        // collision with "Purch. Rcpt. Line" (50101 Decimal / 50102 Decimal) during posting. //AAV
        field(50120; "BVR Source Rcpt No."; Code[20])
        {
            Caption = 'Source Receipt No.';
            DataClassification = CustomerContent;
            TableRelation = "Purch. Rcpt. Header"."No.";
        }
        field(50121; "BVR Source Rcpt Line No."; Integer)
        {
            Caption = 'Source Receipt Line No.';
            DataClassification = CustomerContent;
        }
        // Link Custom Receipt line to released PO line
        field(50110; "BVR Source PO No."; Code[20])
        {
            Caption = 'Source PO No.';
            DataClassification = CustomerContent;
            TableRelation = "Purchase Header"."No." where("Document Type"=const(Order));
        }
        field(50111; "BVR Source PO Line No."; Integer)
        {
            Caption = 'Source PO Line No.';
            DataClassification = CustomerContent;
        }
        field(50112; "BVR Source PO Qty"; Decimal)
        {
            Caption = 'PO Quantity';
            DataClassification = CustomerContent;
            Editable = false;
            DecimalPlaces = 0: 5;
        }
        field(50113; "BVR Remaining Qty"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DataClassification = CustomerContent;
            Editable = false;
            DecimalPlaces = 0: 5;
        }
        // Line-level accrual accounts copied from the source receipt by Get Receipt Lines
        // (Accrual). "BVR Std Get Receipt Lines" redirects this line's cost debit to the
        // Vendor Accrual account at invoice posting (OnPrepareLineOnBeforeSetAccount), so the
        // invoice books Dr Vendor Accrual / Cr Vendor and clears the receipt GRNI.   //AAV
        field(50122; "BVR Vendor Accrual Acc No."; Code[20])
        {
            Caption = 'Vendor Accrual Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
            Editable = false;
        }
        field(50123; "BVR Expense Accrual Acc No."; Code[20])
        {
            Caption = 'Expense Accrual Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
            Editable = false;
        }
    }
}
