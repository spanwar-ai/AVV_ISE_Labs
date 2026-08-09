pageextension 50139 "BVR Whse Receipts List Ext" extends "Warehouse Receipts"
{
    // Shows the AP batch on the Warehouse Receipt LIST so receipts can be reviewed and filtered by
    // batch. Display only - base page 7332 is declared Editable = false, and a page extension cannot
    // change a base page's Editable property, so the batch is still assigned on the Warehouse Receipt
    // card (pageextension "BVR Warehouse Receipt Ext").   //AAV.SP
    layout
    {
        addafter("Document Status")
        {
            field("BVR Batch No."; Rec."BVR Batch No.")   //AAV.SP
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the batch this Warehouse Receipt belongs to. The AP team assigns it on the receipt itself.';
            }
        }
    }

    actions
    {
        // Same rule as the card: a receipt in a batch is posted from its batch, so the posting
        // buttons are off while a Batch No. is filled in. Preview Posting stays available.   //AAV.SP
        modify("Post Receipt")
        {
            Enabled = BVRPostAllowed;
        }
        modify("Post and Print")
        {
            Enabled = BVRPostAllowed;
        }
        modify("Post and Print Put-away")
        {
            Enabled = BVRPostAllowed;
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        BVRPostAllowed := Rec."BVR Batch No." = '';   //AAV.SP
    end;

    var
        BVRPostAllowed: Boolean;   //AAV.SP
}
