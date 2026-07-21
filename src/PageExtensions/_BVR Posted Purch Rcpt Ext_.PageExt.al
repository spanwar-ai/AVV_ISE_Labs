pageextension 50116 "BVR Posted Purch Rcpt Ext" extends "Posted Purchase Receipt"
{
    // Surface the source Warehouse Receipt No. on the posted receipt, right after Order No., so the
    // WR that produced this receipt is visible/traceable.   //AAV
    layout
    {
        addafter("Order No.")
        {
            field("BVR Source Whse Receipt No."; Rec."BVR Source Whse Receipt No.")   //AAV
            {
                ApplicationArea = Warehouse;
                Editable = false;
                ToolTip = 'Specifies the Warehouse Receipt this Purchase Receipt was posted from.';
            }
        }
    }
}
