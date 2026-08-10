pageextension 50116 "BVR Posted Purch Rcpt Ext" extends "Posted Purchase Receipt"
{
    // Surface the source Warehouse Receipt No. on the posted receipt, right after Order No., so the
    // WR that produced this receipt is visible/traceable.   //AAV
    layout
    {
        // A page extension can only change PROPERTIES of a base control - it cannot add an
        // OnDrillDown trigger to it. So the base "Order No." is hidden and replaced by a drillable
        // copy that opens the source purchase order.   //AAV.SP
        modify("Order No.")
        {
            Visible = false;
        }
        addafter("Order No.")
        {
            // The standard field, carried here from the Warehouse Receipt: it is set on the source
            // order by codeunit "BVR Whse Receipt Mgt" before posting, and Purch.-Post's
            // TransferFields brings it across - "Posting Description" is field 22 on both tables.
            // Microsoft leaves it off this page, so it is added rather than unhidden.   //AAV.SP
            field("Posting Description"; Rec."Posting Description")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the posting description this receipt was posted with. It comes from the Posting Description on the warehouse receipt, when one was entered there.';
            }
            field("BVR Order No."; Rec."Order No.")   //AAV.SP
            {
                ApplicationArea = All;
                Caption = 'Order No.';
                Editable = false;
                DrillDown = true;
                ToolTip = 'Specifies the purchase order this receipt was posted from. Choose the value to open the order.';

                trigger OnDrillDown()
                var
                    PurchDocMgt: Codeunit "BVR Purch Doc Mgt";
                begin
                    PurchDocMgt.ShowPurchaseOrder(Rec."Order No.");
                end;
            }
            field("BVR Blanket Order No."; Rec."BVR Blanket Order No.")   //AAV.SP
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the blanket purchase order the order behind this receipt was created from.';
            }
            field("BVR Batch No."; Rec."BVR Batch No.")   //AAV.SP
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the batch the source Warehouse Receipt was assigned to by the AP team.';
            }
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
