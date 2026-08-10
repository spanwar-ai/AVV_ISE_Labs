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
        // Same numbers and types as on Purchase Header (50108/50109), so Purch.-Post's
        // TransferFields carries the warehouse dimensions onto the posted receipt. Codeunit
        // "BVR Undo Receipt Accrual" reads them from here to reverse the accrual with exactly the
        // dimensions it was posted under - otherwise accrual and reversal net to zero in total but
        // leave phantom balances per dimension.   //AAV.SP
        field(50108; "BVR WH Shortcut Dim 1 Code"; Code[20])
        {
            Caption = 'Warehouse Shortcut Dimension 1 Code';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50109; "BVR WH Shortcut Dim 2 Code"; Code[20])
        {
            Caption = 'Warehouse Shortcut Dimension 2 Code';
            DataClassification = CustomerContent;
            Editable = false;
        }
        // The batch the source Warehouse Receipt was assigned to, stamped by codeunit
        // "BVR Whse Receipt Mgt" right after the receipt is posted.
        // 50110 is deliberately a number that does NOT exist on "Purchase Header": this value comes
        // from the Warehouse Receipt, and if the number were shared, Purch.-Post's
        // TransferFields(PurchHeader) would overwrite it with whatever the source PO happened to
        // hold. Do not add 50110 to "Purchase Header".   //AAV.SP
        field(50110; "BVR Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "BVR Purch Rcpt Batch"."Code";
        }
        // Same number and type as on "Purchase Header" (50123), so the blanket order the receipt
        // ultimately originates from is carried here by TransferFields when the receipt is posted -
        // by Purch.-Post for the standard flow and by "BVR Custom Rcpt Post V2" for the custom
        // one.   //AAV.SP
        field(50123; "BVR Blanket Order No."; Code[20])
        {
            Caption = 'Blanket Order No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
