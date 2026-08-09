// Puts the document-batch process on the three document types that were added after the purchase
// invoice: Purchase Credit Memo, Sales Order and Sales Credit Memo.
//
// Each does the same two things, exactly as "BVR Purchase Invoice Ext" does for the invoice:
//   * surfaces "Batch No." so the document can be put into a batch,
//   * greys out the posting buttons while a batch is assigned, because a batched document is posted
//     from its batch together with the rest of it. Clearing the Batch No. brings them back.
//
// Preview Posting is deliberately left alone throughout: it posts nothing, and it is the most useful
// way to check a document before its batch goes.   //AAV.SP
pageextension 50140 "BVR Purch Cr Memo Ext" extends "Purchase Credit Memo"
{
    layout
    {
        addlast(General)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the batch this credit memo belongs to. Only Purchase Credit Memo batches can be chosen. The batch is posted from the Purchase Credit Memo Batches page.';
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
        modify(PostAndNew)
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

pageextension 50141 "BVR Sales Order Ext" extends "Sales Order"
{
    layout
    {
        addlast(General)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the batch this order belongs to. Only Sales Order batches can be chosen. The batch is shipped and invoiced from the Sales Order Batches page.';
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

pageextension 50142 "BVR Sales Cr Memo Ext" extends "Sales Credit Memo"
{
    layout
    {
        addlast(General)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the batch this credit memo belongs to. Only Sales Credit Memo batches can be chosen. The batch is posted from the Sales Credit Memo Batches page.';
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
    }

    trigger OnAfterGetCurrRecord()
    begin
        BVRPostAllowed := Rec."BVR Doc Batch No." = '';
    end;

    var
        BVRPostAllowed: Boolean;
}
