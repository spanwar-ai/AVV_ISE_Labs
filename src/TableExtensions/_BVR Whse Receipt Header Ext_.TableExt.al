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
        // The two GLOBAL dimensions, captured on the Warehouse Receipt and pushed onto the source
        // Purchase Order header(s) when the receipt is posted (see codeunit "BVR Whse Receipt Mgt").
        // Plain shortcut codes - the Warehouse Receipt has no Dimension Set ID of its own, so the
        // TableRelation (filtered on the global dimension no., blocked values excluded) is the whole
        // validation. The real dimension set is built on the PO, by standard code.
        // CaptionClass '1,2,n' makes the captions follow the dimension names configured in General
        // Ledger Setup, exactly as on the Purchase Order.   //AAV.SP
        field(50105; "BVR Shortcut Dimension 1 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 1 Code';
            CaptionClass = '1,2,1';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
        }
        field(50106; "BVR Shortcut Dimension 2 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 2 Code';
            CaptionClass = '1,2,2';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
        }
        // Set by the AP team while the receipt is Sent to AP Team, from the batch lookup (which also
        // allows creating a new batch inline). Carried onto the Posted Purchase Receipt by codeunit
        // "BVR Whse Receipt Mgt" when the WR posts.   //AAV.SP
        field(50107; "BVR Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            DataClassification = CustomerContent;
            TableRelation = "BVR Doc Batch"."Code";
        }
    }
}
