pageextension 50137 "BVR Posted Purch Rcpts List" extends "Posted Purchase Receipts"
{
    // Show the Attachments factbox on the posted-receipt LIST, matching the card. Keyed on
    // Purch. Rcpt. Header (122); codeunit "BVR Whse Rcpt Doc Attach" registers that table with the
    // Document Attachment framework so upload works as well as display.   //AAV.SP
    layout
    {
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
