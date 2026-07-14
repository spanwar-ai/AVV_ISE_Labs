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
    }
}
