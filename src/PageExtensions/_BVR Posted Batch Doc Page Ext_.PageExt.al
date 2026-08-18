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

// The Posted Sales Shipment deliberately shows nothing - the sales batch is on the invoice, and a
// shipment can be invoiced later, in part, or across several invoices, so there is no one batch it
// belongs to. Its old batch fields are obsolete and never written.   //AAV.SP
pageextension 50144 "BVR Posted Sales Invoice Ext" extends "Posted Sales Invoice"
{
    layout
    {
        addlast(General)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the batch this invoice was posted from.';
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
