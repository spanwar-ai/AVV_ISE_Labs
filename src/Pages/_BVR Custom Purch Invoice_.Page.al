page 50130 "BVR Custom Purch Invoice"
{
    PageType = Document;
    SourceTable = "Purchase Header";
    Caption = 'Custom Purchase Invoice';
    ApplicationArea = All;
    UsageCategory = Documents;
    SourceTableView = where("Document Type" = const(Invoice));
    PromotedActionCategoriesML = ENU = 'New,Process,Report,Approval';
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
                field(status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            part(Lines; "BVR Custom Purch Inv Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
            }
        }
        area(factboxes)
        {
            part("TaxAreaFactBox"; "BVR Tax FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
            part(Vendor; "Vendor Details FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("Buy-from Vendor No.");
            }
            part(Prepayment; "BVR Prepayment FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Document Type" = field("Document Type"), "No." = field("No.");
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
                    // PostCU: Codeunit "BVR Custom Inv Post";
                    PostCU: Codeunit "BVR Custom Inv Post V2";
                    H: Record "Purchase Header";
                begin
                    Rec.TestField("BVR Vendor Accrual Acc No.");
                    Rec.TestField("BVR Expense Accrual Acc No.");
                    rec.TestField(Status, rec.Status::released);
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
            action(Reopen)
            {
                ApplicationArea = All;
                Caption = 'Reopen';
                Image = ReOpen;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = not Rec."BVR Custom Rcpt Posted";   //AAV.SP - posted receipts cannot be reopened

                trigger OnAction()
                var
                    ReopenCU: Codeunit "Purchase Manual Reopen";                //AAV.SP
                begin
                    if Rec.Status <> Rec.Status::Open then                        //AAV.SP
                        ReopenCU.Run(Rec);                                                   //AAV.SP
                    CurrPage.Update(false);
                end;
            }
            group("Request Approval")                                                           //AAV.SP
            {                                                                                    //AAV.SP
                Caption = 'Request Approval';                                                    //AAV.SP
                Image = SendApprovalRequest;                                                     //AAV.SP

                action(SubmitForApproval)                                                        //AAV.SP
                {                                                                                //AAV.SP
                    ApplicationArea = All;                                                       //AAV.SP
                    Caption = 'Send for Approval';                                               //AAV.SP
                    Image = SendApprovalRequest;                                                 //AAV.SP
                    Promoted = true;                                                             //AAV.SP
                    PromotedCategory = Category4;                                                 //AAV.SP
                    Enabled = (Rec.Status = Rec.Status::Open) and (not OpenApprovalEntriesExist); //AAV.SP
                    ToolTip = 'Confirm the accrual accounts are updated and submit the Custom Purchase Receipt for approval. AP team only.'; //AAV.SP

                    trigger OnAction()                                                           //AAV.SP
                    var                                                                          //AAV.SP
                        ApprMgt: Codeunit "BVR Cust Rcpt Appr Mgt";                              //AAV.SP
                    begin                                                                        //AAV.SP
                        ApprMgt.MarkAPUpdatedAndSubmit(Rec);                                     //AAV.SP
                        CurrPage.Update(false);                                                  //AAV.SP
                    end;                                                                         //AAV.SP
                }                                                                                //AAV.SP
                action(CancelApprovalRequest)                                                    //AAV.SP
                {                                                                                //AAV.SP
                    ApplicationArea = All;                                                       //AAV.SP
                    Caption = 'Cancel Approval Re&quest';                                        //AAV.SP
                    Image = CancelApprovalRequest;                                               //AAV.SP
                    Promoted = true;                                                             //AAV.SP
                    PromotedCategory = Category4;                                                 //AAV.SP
                    Enabled = OpenApprovalEntriesExist;                                          //AAV.SP
                    ToolTip = 'Cancel the open approval request for this Custom Purchase Receipt.'; //AAV.SP

                    trigger OnAction()                                                           //AAV.SP
                    var                                                                          //AAV.SP
                        ApprEvents: Codeunit "BVR Cust Rcpt Appr Events";                        //AAV.SP
                    begin                                                                        //AAV.SP
                        ApprEvents.OnCancelCustomReceiptApprovalRequest(Rec);                    //AAV.SP
                        CurrPage.Update(false);                                                  //AAV.SP
                    end;                                                                         //AAV.SP
                }                                                                                //AAV.SP
            }                                                                                    //AAV.SP
            group(Approval)                                                                      //AAV.SP
            {                                                                                    //AAV.SP
                Caption = 'Approval';                                                            //AAV.SP
                Image = Approvals;                                                               //AAV.SP

                action(Approve)                                                                  //AAV.SP
                {                                                                                //AAV.SP
                    ApplicationArea = All;                                                       //AAV.SP
                    Caption = 'Approve';                                                         //AAV.SP
                    Image = Approve;                                                             //AAV.SP
                    Promoted = true;                                                             //AAV.SP
                    PromotedCategory = Category4;                                                 //AAV.SP
                    Visible = OpenApprovalEntriesExistForCurrUser;                               //AAV.SP
                    ToolTip = 'Approve the open approval request assigned to you.';              //AAV.SP

                    trigger OnAction()                                                           //AAV.SP
                    var                                                                          //AAV.SP
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";                               //AAV.SP
                    begin                                                                        //AAV.SP
                        ApprovalsMgmt.ApproveRecordApprovalRequest(Rec.RecordId);               //AAV.SP
                        CurrPage.Update(false);                                                  //AAV.SP
                    end;                                                                         //AAV.SP
                }                                                                                //AAV.SP
                action(Reject)                                                                   //AAV.SP
                {                                                                                //AAV.SP
                    ApplicationArea = All;                                                       //AAV.SP
                    Caption = 'Reject';                                                          //AAV.SP
                    Image = Reject;                                                              //AAV.SP
                    Promoted = true;                                                             //AAV.SP
                    PromotedCategory = Category4;                                                 //AAV.SP
                    Visible = OpenApprovalEntriesExistForCurrUser;                               //AAV.SP
                    ToolTip = 'Reject the open approval request assigned to you.';               //AAV.SP

                    trigger OnAction()                                                           //AAV.SP
                    var                                                                          //AAV.SP
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";                               //AAV.SP
                    begin                                                                        //AAV.SP
                        ApprovalsMgmt.RejectRecordApprovalRequest(Rec.RecordId);                //AAV.SP
                        CurrPage.Update(false);                                                  //AAV.SP
                    end;                                                                         //AAV.SP
                }                                                                                //AAV.SP
                action(Delegate)                                                                 //AAV.SP
                {                                                                                //AAV.SP
                    ApplicationArea = All;                                                       //AAV.SP
                    Caption = 'Delegate';                                                        //AAV.SP
                    Image = Delegate;                                                            //AAV.SP
                    Promoted = true;                                                             //AAV.SP
                    PromotedCategory = Category4;                                                 //AAV.SP
                    Visible = OpenApprovalEntriesExistForCurrUser;                               //AAV.SP
                    ToolTip = 'Delegate the open approval request to your substitute.';          //AAV.SP

                    trigger OnAction()                                                           //AAV.SP
                    var                                                                          //AAV.SP
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";                               //AAV.SP
                    begin                                                                        //AAV.SP
                        ApprovalsMgmt.DelegateRecordApprovalRequest(Rec.RecordId);              //AAV.SP
                        CurrPage.Update(false);                                                  //AAV.SP
                    end;                                                                         //AAV.SP
                }                                                                                //AAV.SP
                action(Approvals)                                                                //AAV.SP
                {                                                                                //AAV.SP
                    ApplicationArea = All;                                                       //AAV.SP
                    Caption = 'Approvals';                                                       //AAV.SP
                    Image = Approvals;                                                           //AAV.SP
                    ToolTip = 'View the approval entries for this Custom Purchase Receipt.';     //AAV.SP

                    trigger OnAction()                                                           //AAV.SP
                    var                                                                          //AAV.SP
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";                               //AAV.SP
                    begin                                                                        //AAV.SP
                        ApprovalsMgmt.OpenApprovalEntriesPage(Rec.RecordId);                     //AAV.SP
                    end;                                                                         //AAV.SP
                }                                                                                //AAV.SP
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        CurrPage.TaxAreaFactBox.Page.Show(Rec);
    end;

    trigger OnAfterGetCurrRecord()
    var
        ApprMgt: Codeunit "BVR Cust Rcpt Appr Mgt";
    begin
        OpenApprovalEntriesExist := ApprMgt.HasOpenApprovalEntries(Rec.RecordId);
        OpenApprovalEntriesExistForCurrUser := ApprMgt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);
    end;

    var
        OpenApprovalEntriesExist: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
}
