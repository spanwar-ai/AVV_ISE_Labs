pageextension 50310 "BVR Custom Rcpt Attachments" extends "BVR Custom Purch Receipt"
{
    layout
    {
        addlast(factboxes)
        {
            part(DocAttach; "Doc. Attachment List Factbox")
            {
                Caption = 'Attachments';
                ApplicationArea = All;
                SubPageLink = "Table ID"=CONST(38), "No."=FIELD("No.");
            }
        }
    }
}
