pageextension 50137 "BVR Posted Purch Rcpts List" extends "Posted Purchase Receipts"
{
    // Show the Attachments factbox on the posted-receipt LIST, matching the card. Keyed on
    // Purch. Rcpt. Header (122); codeunit "BVR Whse Rcpt Doc Attach" registers that table with the
    // Document Attachment framework so upload works as well as display.   //AAV.SP
    layout
    {
        // Base page 145 does not show Order No. at all, so it is added here as a drillable column
        // that opens the source purchase order.   //AAV.SP
        addafter("No.")
        {
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
            field("BVR Source Whse Receipt No."; Rec."BVR Source Whse Receipt No.") //AAV.SP
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
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
