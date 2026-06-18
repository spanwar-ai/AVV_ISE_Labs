pageextension 50253 "BVR Custom Purch InvPreviewExt" extends "BVR Custom Purch Invoice"
{
    actions
    {
        addlast(Processing)
        {
            action("Preview Posting")
            {
                ApplicationArea = All;
                Caption = 'Preview Posting';
                Image = ViewPostedOrder;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PrevMgt: Codeunit "BVR Posting Preview Mgt";
                    H: Record "Purchase Header";
                begin
                    H.Get(Rec."Document Type", Rec."No.");
                    PrevMgt.PreviewCustomInvoice(H);
                end;
            }
            action("Posting Preview Report")
            {
                ApplicationArea = All;
                Caption = 'Posting Preview Report';
                Image = Print;
                Promoted = true;
                PromotedCategory = Report;

                trigger OnAction()
                begin
                    rec.SetRecFilter();
                    // Processing-only report with dataset; attach RDLC from your end.
                    //Purchase Document - Test (402, Report Request)
                    //Report.RunModal(Report::"BVR Inv Posting Preview", true, true, Rec);
                    Report.RunModal(Report::"Purchase Document - Test", true, true, Rec);
                end;
            }
        }
    }
}
