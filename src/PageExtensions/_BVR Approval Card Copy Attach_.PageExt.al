pageextension 50312 "BVR Approval Card Copy Attach" extends "BVR Receipt Approval Card"
{
    actions
    {
        modify("Post Receipt")
        {
            trigger OnAfterAction()
            var
                CopyCU: Codeunit "BVR Copy Attachments";
                PH: Record "Purchase Header";
                PRH: Record "Purch. Rcpt. Header";
            begin
                PH.Get(Rec."Document Type", Rec."No.");
                PH.TestField("BVR Posted Rcpt No.");
                PRH.Get(PH."BVR Posted Rcpt No.");
                CopyCU.CopyReceiptAttachments(PH, PRH);
            end;
        }
    }
}
