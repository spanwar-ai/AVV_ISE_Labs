tableextension 50122 "BVR Whse Receipt Header Ext" extends "Warehouse Receipt Header"
{
    // Step 1 of the Warehouse-Receipt approval flow. Carries the accrual accounts and the
    // single user-facing status onto the standard Warehouse Receipt document, so the AP /
    // approval flow (Open -> Sent to AP Team -> Pending Approval -> Released) can run on the
    // WR itself and posting can be gated until it is Released.   //AAV
    //
    // "BVR Requires Approval" marks a WR as belonging to this flow. Standard warehouse
    // receipts leave it false and post exactly as before - the posting gate only bites on
    // flow documents.   //AAV
    fields
    {
        field(50100; "BVR Vendor Accrual Acc No."; Code[20])
        {
            Caption = 'Vendor Accrual Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }
        field(50101; "BVR Expense Accrual Acc No."; Code[20])
        {
            Caption = 'Expense Accrual Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }
        // Reuses the same enum as the PO-based custom receipt flow (enum 50101).   //AAV
        field(50102; "BVR Receipt Status"; Enum "BVR Receipt Status")
        {
            Caption = 'Receipt Status';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50103; "BVR Requires Approval"; Boolean)
        {
            Caption = 'Requires Approval';
            DataClassification = CustomerContent;
        }
        field(50104; "BVR Sent To AP Team"; Boolean)
        {
            Caption = 'Sent To AP Team';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
