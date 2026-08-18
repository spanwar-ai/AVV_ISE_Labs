// The Sales Invoice, card and list, brought into the document-batch process on exactly the terms the
// Purchase Invoice already is:
//   * "Batch No." on the document, so it can be put into a batch,
//   * the posting buttons greyed out while a batch is assigned, because a batched invoice is posted
//     from its batch together with the rest of it. Clearing the Batch No. brings them back.
//
// The list is extended as well as the card. Disabling Post on the card alone leaves the way open:
// the Sales Invoice List carries its own Post, Post and Send and Post Batch, and Post Batch is the
// dangerous one - it runs the standard batch-posting report over whatever is filtered, which would
// post batched and unbatched invoices together and could empty a batch by accident.
//
// Preview Posting is deliberately left alone on both: it posts nothing, and it is the most useful way
// to check an invoice before its batch goes.   //AAV.SP
pageextension 50147 "BVR Sales Invoice Ext" extends "Sales Invoice"
{
    layout
    {
        addlast(General)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the batch this invoice belongs to. Only Sales Invoice batches can be chosen. The batch is posted from the Sales Invoice Batches page.';
            }
        }
    }

    actions
    {
        modify(Post)
        {
            Enabled = BVRPostAllowed;
        }
        modify(PostAndNew)
        {
            Enabled = BVRPostAllowed;
        }
        modify(PostAndSend)
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

pageextension 50148 "BVR Sales Invoices List Ext" extends "Sales Invoice List"
{
    layout
    {
        addlast(Control1)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the batch this invoice belongs to. A batched invoice is posted from the Sales Invoice Batches page, not from here.';
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
