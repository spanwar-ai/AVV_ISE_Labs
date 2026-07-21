tableextension 50115 "BVR Purch Rcpt Header Ext" extends "Purch. Rcpt. Header"
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
        // Source Warehouse Receipt No. stamped onto the posted receipt when it is posted from
        // a Warehouse Receipt, so the WR No. flows to the Purchase Receipt.   //AAV
        // NOTE: must NOT reuse a field number that exists on "Purchase Header" with a different
        // type - Purch.-Post does PurchRcptHeader.TransferFields(PurchHeader), which copies fields
        // by number and fails on a type mismatch. 50105 is Boolean ("BVR Custom Inv Posted") on
        // Purchase Header, so this field lives at 50107 (unused on Purchase Header).   //AAV
        field(50107; "BVR Source Whse Receipt No."; Code[20])
        {
            Caption = 'Source Warehouse Receipt No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
