tableextension 50110 "BVR Purch Header Ext" extends "Purchase Header"
{
    fields
    {
        field(50100; "BVR Receive PO"; Boolean)
        {
            Caption = 'Receive PO';
            DataClassification = CustomerContent;
        }
        field(50101; "BVR Custom Rcpt Posted"; Boolean)
        {
            Caption = 'Custom Receipt Posted';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50102; "BVR Posted Rcpt No."; Code[20])
        {
            Caption = 'Posted Receipt No.';
            DataClassification = CustomerContent;
            Editable = false;
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
        field(50105; "BVR Custom Inv Posted"; Boolean)
        {
            Caption = 'Custom Invoice Posted';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50106; "BVR Posted Inv No."; Code[20])
        {
            Caption = 'Posted Invoice No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        // P2: Grouping + batch
        field(50120; "BVR Group No."; Code[20])
        {
            Caption = 'Group Number';
            DataClassification = CustomerContent;
        }
        field(50121; "BVR Batch No."; Code[20])
        {
            Caption = 'Batch Number';
            DataClassification = CustomerContent;
            Editable = false;
        }

    }
    /*  trigger OnInsert()
         begin
             // Only default for Custom Receipt Orders
             if ("Document Type" = "Document Type"::Order) then begin
                 if not "BVR Receive PO" then
                     "BVR Receive PO" := true;
             end
         end; */
}
