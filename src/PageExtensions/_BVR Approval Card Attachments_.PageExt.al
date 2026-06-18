pageextension 50311 "BVR Approval Card Attachments" extends "BVR Receipt Approval Card"
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
