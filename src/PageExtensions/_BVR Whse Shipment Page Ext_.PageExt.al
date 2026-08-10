// Sales mirror of the Warehouse Receipt extensions: the batch is assigned on the Warehouse Shipment,
// and while one is assigned the shipment is posted from its batch rather than from here, so the
// posting buttons are switched off. Clearing the Batch No. brings them back.
//
// Preview Posting is deliberately left alone on both pages: it posts nothing, and it is the most
// useful way to check a shipment before its batch goes.   //AAV.SP
pageextension 50147 "BVR Whse Shipment Ext" extends "Warehouse Shipment"
{
    layout
    {
        addlast(General)
        {
            field("BVR Batch No."; Rec."BVR Batch No.")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the batch this warehouse shipment belongs to. Choose an existing Sales Shipment batch or create a new one from the lookup. The batch is posted from the Sales Shipment Batches page.';
            }
            field(BVRAmount; BVRAmount)
            {
                ApplicationArea = Warehouse;
                Caption = 'Amount (LCY)';
                Editable = false;
                AutoFormatType = 1;
                ToolTip = 'Specifies the value of what this shipment is about to send out: the quantity to ship on each line at the sales order unit price, less any line discount.';
            }
        }
    }

    actions
    {
        modify("P&ost Shipment")
        {
            Enabled = BVRPostAllowed;
        }
        modify("Post and &Print")
        {
            Enabled = BVRPostAllowed;
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        BVRPostAllowed := Rec."BVR Batch No." = '';
        BVRAmount := Rec.BVRCalcAmount();
    end;

    var
        BVRPostAllowed: Boolean;
        BVRAmount: Decimal;
}

pageextension 50148 "BVR Whse Shipment List Ext" extends "Warehouse Shipment List"
{
    layout
    {
        addafter("Document Status")
        {
            field("BVR Batch No."; Rec."BVR Batch No.")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the batch this warehouse shipment belongs to.';
            }
        }
    }

    actions
    {
        modify("Post Shipment")
        {
            Enabled = BVRPostAllowed;
        }
        modify("Post and Print")
        {
            Enabled = BVRPostAllowed;
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        BVRPostAllowed := Rec."BVR Batch No." = '';
    end;

    var
        BVRPostAllowed: Boolean;
}
