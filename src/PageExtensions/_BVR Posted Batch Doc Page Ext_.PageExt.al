// Shows, on each posted document, the batch it was posted from - so a posted document can be traced
// back to its batch without going the long way round through the batch pages.
//
// Display only. The field is Editable = false on the table; the batch is a property of how the
// document was posted.   //AAV.SP
pageextension 50143 "BVR Posted Purch Cr Memo Ext" extends "Posted Purchase Credit Memo"
{
    layout
    {
        addlast(General)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the batch this credit memo was posted from.';
            }
        }
    }
}

// The sales side ends at the SHIPMENT, so this is where the batch is shown - the exact counterpart of
// the batch on the Posted Purchase Receipt.
//
// The Posted Sales INVOICE deliberately shows nothing. It used to, back when the sales batch sat on
// the sales order; now that the batch sits on the Warehouse Shipment there is nothing to show, and an
// invoice cannot inherit one anyway - it can combine shipments from several different batches.
//   //AAV.SP
pageextension 50144 "BVR Posted Sales Shpt Ext" extends "Posted Sales Shipment"
{
    layout
    {
        addlast(General)
        {
            field("BVR Batch No."; Rec."BVR Batch No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the batch the warehouse shipment behind this posted shipment was posted from.';
            }
        }
    }
}

pageextension 50145 "BVR Posted Sales Cr Memo Ext" extends "Posted Sales Credit Memo"
{
    layout
    {
        addlast(General)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the batch this credit memo was posted from.';
            }
        }
    }
}
