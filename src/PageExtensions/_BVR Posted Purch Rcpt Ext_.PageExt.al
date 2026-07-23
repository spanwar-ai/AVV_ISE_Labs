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
        // Attachments carried over from the Warehouse Receipt when it was posted (and any added here
        // afterwards). Table 122 is not in the base Document Attachment map, so codeunit "BVR Whse
        // Rcpt Doc Attach" registers it - without that, uploads here fail with "record is not open".
        //   //AAV.SP
        addfirst(factboxes)
        {
            part(BVRDocAttach; "Doc. Attachment List Factbox")
            {
                Caption = 'Attachments';
                ApplicationArea = Warehouse;
                SubPageLink = "Table ID" = const(120), "No." = field("No.");
            }
        }
    }
}
