page 50130 "BVR Custom Purch Invoice"
{
    PageType = Document;
    SourceTable = "Purchase Header";
    Caption = 'Custom Purchase Invoice';
    ApplicationArea = All;
    UsageCategory = Documents;
    SourceTableView = where("Document Type"=const(Invoice));

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
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                }
                field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                {
                    ApplicationArea = All;
                }
                //field("External Document No."; Rec."External Document No.") { ApplicationArea = All; }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = All;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = All;
                }
                field("BVR Vendor Accrual Acc No."; Rec."BVR Vendor Accrual Acc No.")
                {
                    ApplicationArea = All;
                }
                field("BVR Expense Accrual Acc No."; Rec."BVR Expense Accrual Acc No.")
                {
                    ApplicationArea = All;
                }
                field("BVR Custom Inv Posted"; Rec."BVR Custom Inv Posted")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("BVR Posted Inv No."; Rec."BVR Posted Inv No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Prepayment %"; Rec."Prepayment %")
                {
                    ApplicationArea = All;
                }
                field("Prepayment Due Date"; Rec."Prepayment Due Date")
                {
                    ApplicationArea = All;
                }
                field("Prepmt. Payment Terms Code"; Rec."Prepmt. Payment Terms Code")
                {
                    ApplicationArea = All;
                }
                field("Prepmt. Posting Description"; Rec."Prepmt. Posting Description")
                {
                    ApplicationArea = All;
                }
                field("Prepayment No. Series"; Rec."Prepayment No. Series")
                {
                    ApplicationArea = All;
                }
            }
            part(Lines; "BVR Custom Purch Inv Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document Type"=field("Document Type"), "Document No."=field("No.");
            }
        }
        area(factboxes)
        {
            part("TaxAreaFactBox"; "BVR Tax FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "No."=field("No.");
            }
            part(Vendor; "Vendor Details FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "No."=field("Buy-from Vendor No.");
            }
            part(Prepayment; "BVR Prepayment FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Document Type"=field("Document Type"), "No."=field("No.");
            }
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
            action("Get Receipt (Custom)")
            {
                ApplicationArea = All;
                Caption = 'Get Receipt (Custom)';
                Image = GetLines;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    GetCU: Codeunit "BVR Get Custom Receipt Lines";
                    H: Record "Purchase Header";
                begin
                    H.Get(Rec."Document Type", Rec."No.");
                    GetCU.GetLinesInteractive(H);
                    CurrPage.Update(false);
                end;
            }
            action(Statistics)
            {
                ApplicationArea = All;
                Caption = 'Statistics';
                Image = Statistics;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    StatsMgt: Codeunit "BVR Custom Inv Statistics";
                    H: Record "Purchase Header";
                begin
                    H.Get(Rec."Document Type", Rec."No.");
                    StatsMgt.Show(H);
                end;
            }
            action("Post (Custom Invoice)")
            {
                ApplicationArea = All;
                Caption = 'Post (Custom Invoice)';
                Image = Post;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PostCU: Codeunit "BVR Custom Inv Post";
                    H: Record "Purchase Header";
                begin
                    Rec.TestField("BVR Vendor Accrual Acc No.");
                    Rec.TestField("BVR Expense Accrual Acc No.");
                    H.Get(Rec."Document Type", Rec."No.");
                    PostCU.Post(H);
                    CurrPage.Update(false);
                end;
            }
            action("Open Posted Invoice")
            {
                ApplicationArea = All;
                Caption = 'Posted Invoice';
                Image = Invoice;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PIH: Record "Purch. Inv. Header";
                begin
                    Rec.TestField("BVR Posted Inv No.");
                    PIH.Get(Rec."BVR Posted Inv No.");
                    Page.Run(Page::"Posted Purchase Invoice", PIH);
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        CurrPage.TaxAreaFactBox.Page.Show(Rec);
    end;
}
