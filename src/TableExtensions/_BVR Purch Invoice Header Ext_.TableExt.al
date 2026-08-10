tableextension 50120 "BVR Purch Invoice Header Ext" extends "Purch. Inv. Header"
{
    fields
    {
        field(50100; "BVR Custom Receipt"; Boolean)
        {
            Caption = 'Custom Receipt';
            DataClassification = CustomerContent;
        }
        field(50103; "BVR Vendor Accrual Acc No."; Code[20])
        {
            Caption = 'Vendor Accrual Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }
        field(50104; "BVR Expense Accrual Acc No."; Code[20])
        {
            Caption = 'Expense Accrual Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }
        // Same number and type as on "Purchase Header" (50124), so the batch the invoice was posted
        // from is carried here by Purch.-Post's TransferFields with no extra posting code.   //AAV.SP
        field(50124; "BVR Doc Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "BVR Purch Inv Batch"."Code";
        }
    }
}
