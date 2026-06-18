page 50231 "BVR Receipt Approval Card"
{
    PageType = Document;
    SourceTable = "Purchase Header";
    Caption = 'Approve & Post Custom Receipt';
    ApplicationArea = All;
    UsageCategory = Documents;
    SourceTableView = where("Document Type"=const(Order), "BVR Receive PO"=const(true));

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("BVR Vendor Accrual Acc No."; Rec."BVR Vendor Accrual Acc No.")
                {
                    ApplicationArea = All;
                } //; Editable = false; }
                field("BVR Expense Accrual Acc No."; Rec."BVR Expense Accrual Acc No.")
                {
                    ApplicationArea = All;
                } // Editable = false; }
                field("BVR Sent For Approval"; Rec."BVR Sent For Approval")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("BVR Approved"; Rec."BVR Approved")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("BVR Custom Rcpt Posted"; Rec."BVR Custom Rcpt Posted")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("BVR Posted Rcpt No."; Rec."BVR Posted Rcpt No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            part(Lines; "BVR Custom Purch Rcpt Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document Type"=field("Document Type"), "Document No."=field("No.");
            }
        }
        area(factboxes)
        {
            systempart(Notes; Notes)
            {
                ApplicationArea = All;
            }
            systempart(Links; Links)
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(Approve)
            {
                ApplicationArea = All;
                Caption = 'Approve';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec."BVR Sent For Approval" and (not Rec."BVR Approved") and (not Rec."BVR Custom Rcpt Posted");

                trigger OnAction()
                var
                    Mgt: Codeunit "BVR Receipt Approval Mgt";
                    H: Record "Purchase Header";
                begin
                    H.Get(Rec."Document Type", Rec."No.");
                    Mgt.Approve(H);
                    CurrPage.Update(false);
                end;
            }
            /*  action("Send Back")
             {
                 ApplicationArea = All;
                 Caption = 'Send Back';
                 Image = Reject;
                 Promoted = true;
                 PromotedCategory = Process;
                 Enabled = Rec."BVR Sent For Approval" and (not Rec."BVR Custom Rcpt Posted");
                 trigger OnAction()
                 var
                     Mgt: Codeunit "BVR Receipt Approval Mgt";
                     H: Record "Purchase Header";
                 begin
                     H.Get(Rec."Document Type", Rec."No.");
                     Mgt.SendBack(H);
                     Message('Receipt was sent back for changes.');
                     CurrPage.Close();
                 end;
             } */
            action("Preview Posting")
            {
                ApplicationArea = All;
                Caption = 'Preview Posting';
                Image = ViewPostedOrder;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = not Rec."BVR Custom Rcpt Posted";

                trigger OnAction()
                var
                    Prev: Codeunit "BVR Posting Preview Mgt";
                    H: Record "Purchase Header";
                begin
                    H.Get(Rec."Document Type", Rec."No.");
                    Prev.PreviewCustomReceiptSafeV2(H);
                end;
            }
            action("Post Receipt")
            {
                ApplicationArea = All;
                Caption = 'Post Receipt';
                Image = Post;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec."BVR Approved" and (not Rec."BVR Custom Rcpt Posted");

                trigger OnAction()
                var
                    PostV2: Codeunit "BVR Custom Rcpt Post V2";
                    H: Record "Purchase Header";
                begin
                    H.Get(Rec."Document Type", Rec."No.");
                    PostV2.Post(H);
                    CurrPage.Update(false);
                end;
            }
            action("Open Posted Receipt")
            {
                ApplicationArea = All;
                Caption = 'Open Posted Receipt';
                Image = PostedReceipt;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = Rec."BVR Custom Rcpt Posted";

                trigger OnAction()
                var
                    PRH: Record "Purch. Rcpt. Header";
                begin
                    Rec.TestField("BVR Posted Rcpt No.");
                    PRH.Get(Rec."BVR Posted Rcpt No.");
                    Page.Run(Page::"Posted Purchase Receipt", PRH);
                end;
            }
            action("Print Receipt")
            {
                ApplicationArea = All;
                Caption = 'Print Receipt';
                Image = Print;
                Promoted = true;
                PromotedCategory = Report;

                trigger OnAction()
                var
                    H: Record "Purchase Header";
                begin
                    //H.Get(Rec."Document Type", Rec."No.");
                    Rec.SetRecFilter();
                    //Report.RunModal(Report::"BVR Custom Purchase Receipt", true, true, H);
                    Report.RunModal(Report::"BVR Custom Purchase Receipt", true, true, Rec);
                end;
            }
        }
    }
}
