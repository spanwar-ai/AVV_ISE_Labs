// The document LISTS, closing the gap the card extensions left open.
//
// Disabling Post on the Purchase Invoice card is only half the job: the Purchase Invoices list carries
// its own Post, Post and Print and Post Batch actions, and a batched invoice could be posted from
// there without ever going near its batch. Same on the two credit memo lists. The batch fields are
// shown here as well, so it is visible at a glance which documents belong to a batch.
//
// Post Batch matters most of the three. It runs the standard batch-posting report over whatever is
// filtered, which would post batched and unbatched documents together in one go - the one action that
// could empty a batch entirely by accident.
//
// A limit worth knowing: Enabled is evaluated against the row the cursor is on, so a multi-selection
// mixing batched and unbatched documents is only stopped when the focused row is a batched one. This
// is the same deterrent the Warehouse Receipts list has, and it is a deterrent rather than a
// guarantee - a guarantee would mean a check inside the posting codeunit itself, which was
// deliberately not the approach taken here.   //AAV.SP
pageextension 50141 "BVR Purch Invoices List Ext" extends "Purchase Invoices"
{
    layout
    {
        addlast(Control1)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the batch this invoice belongs to. A batched invoice is posted from the Purchase Invoice Batches page, not from here.';
            }
        }
    }

    actions
    {
        modify(PostSelected)
        {
            Enabled = BVRPostAllowed;
        }
        modify(PostAndPrint)
        {
            Enabled = BVRPostAllowed;
        }
        modify(PostBatch)
        {
            Enabled = BVRPostAllowed;
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        BVRPostAllowed := Rec."BVR Doc Batch No." = '';
    end;

    var
        BVRPostAllowed: Boolean;
}

pageextension 50149 "BVR Purch CrMemos List Ext" extends "Purchase Credit Memos"
{
    layout
    {
        addlast(Control1)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the batch this credit memo belongs to. A batched credit memo is posted from the Purchase Credit Memo Batches page, not from here.';
            }
        }
    }

    actions
    {
        modify(Post)
        {
            Enabled = BVRPostAllowed;
        }
        modify(PostAndPrint)
        {
            Enabled = BVRPostAllowed;
        }
        modify(PostBatch)
        {
            Enabled = BVRPostAllowed;
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        BVRPostAllowed := Rec."BVR Doc Batch No." = '';
    end;

    var
        BVRPostAllowed: Boolean;
}

pageextension 50150 "BVR Sales CrMemos List Ext" extends "Sales Credit Memos"
{
    layout
    {
        addlast(Control1)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the batch this credit memo belongs to. A batched credit memo is posted from the Sales Credit Memo Batches page, not from here.';
            }
        }
    }

    actions
    {
        modify(Post)
        {
            Enabled = BVRPostAllowed;
        }
        modify(PostAndSend)
        {
            Enabled = BVRPostAllowed;
        }
        modify("Post &Batch")
        {
            Enabled = BVRPostAllowed;
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        BVRPostAllowed := Rec."BVR Doc Batch No." = '';
    end;

    var
        BVRPostAllowed: Boolean;
}
