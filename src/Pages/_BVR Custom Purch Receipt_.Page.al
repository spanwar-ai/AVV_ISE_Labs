page 50120 "BVR Custom Purch Receipt"
{
    PageType = Document;
    SourceTable = "Purchase Header";
    Caption = 'Custom Purchase Receipt';
    ApplicationArea = All;
    UsageCategory = Documents;
    SourceTableView = where("Document Type" = const(Order), "BVR Receive PO" = const(true));
    PromotedActionCategoriesML = ENU = 'New,Process,Report,Approval';   //AAV.SP - adds the "Approval" ribbon tab (Category4)

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
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
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
                field("BVR Vendor Accrual Acc No."; Rec."BVR Vendor Accrual Acc No.")
                {
                    ApplicationArea = All;
                    Editable = AccrualAcctEditable;   //AAV.SP - locked once AP Updated, except AP team
                }
                field("BVR Expense Accrual Acc No."; Rec."BVR Expense Accrual Acc No.")
                {
                    ApplicationArea = All;
                    Editable = AccrualAcctEditable;   //AAV.SP - locked once AP Updated, except AP team
                }
                field("BVR Group No."; Rec."BVR Group No.")
                {
                    ApplicationArea = All;
                }
                field("BVR Batch No."; Rec."BVR Batch No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                // Approval booleans
                field("BVR Requires Approval"; Rec."BVR Requires Approval")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("BVR AP Updated"; Rec."BVR AP Updated")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
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
                SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
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
            action("Get PO Lines")
            {
                ApplicationArea = All;
                Caption = 'Get Purchase Order Lines';
                Image = GetLines;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    GetCU: Codeunit "BVR Get Released PO Lines";
                    H: Record "Purchase Header";
                begin
                    H.Get(Rec."Document Type", Rec."No.");
                    GetCU.GetIntoCustomReceipt(H);
                    CurrPage.Update(false);
                end;
            }
            action(Release)
            {
                ApplicationArea = All;
                Caption = 'Release';
                Image = ReleaseDoc;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Rel: Codeunit "Release Purchase Document";
                begin
                    Rel.Run(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Reopen)
            {
                ApplicationArea = All;
                Caption = 'Reopen';
                Image = ReOpen;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    Reop: Codeunit "Purchase Manual Reopen";
                begin
                    Reop.Run(Rec);
                    CurrPage.Update(false);
                end;
            }
            // >>> AAV.SP - OLD approval process (manual boolean flow) commented out.
            //            Replaced by the native workflow approval tab below.  //AAV.SP

            action("Mark AP Updated")
            {
                ApplicationArea = All;
                Caption = 'AP Updated';
                Image = UpdateDescription;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = (Rec.Status = Rec.Status::Released) and (not Rec."BVR Sent For Approval") and (not Rec."BVR Custom Rcpt Posted");

                trigger OnAction()
                var
                    Mgt: Codeunit "BVR Receipt Approval Mgt";
                    H: Record "Purchase Header";
                begin
                    H.Get(Rec."Document Type", Rec."No.");
                    Mgt.MarkAPUpdated(H);
                    CurrPage.Update(false);
                end;
            }
            /*action("Send for Approval")
            {
                ApplicationArea = All;
                Caption = 'Send for Approval';
                Image = SendApprovalRequest;
                Promoted = true;
                PromotedCategory = Process;
                Enabled = (Rec.Status = Rec.Status::Released) and (not Rec."BVR Sent For Approval") and (not Rec."BVR Custom Rcpt Posted");

                trigger OnAction()
                var
                    Mgt: Codeunit "BVR Receipt Approval Mgt";
                    H: Record "Purchase Header";
                begin
                    H.Get(Rec."Document Type", Rec."No.");
                    Mgt.SendForApproval(H);
                    CurrPage.Update(false);
                end;
            }
            */
            // <<< AAV.SP - end of old approval process

            // >>> AAV.SP - Native workflow approval (standard-style tabs)
            group("Request Approval")                                                           //AAV.SP
            {                                                                                    //AAV.SP
                Caption = 'Request Approval';                                                    //AAV.SP
                Image = SendApprovalRequest;                                                     //AAV.SP

                action(SendApprovalRequest)                                                      //AAV.SP
                {                                                                                //AAV.SP
                    ApplicationArea = All;                                                       //AAV.SP
                    Caption = 'Send A&pproval Request';                                          //AAV.SP
                    Image = SendApprovalRequest;                                                 //AAV.SP
                    Promoted = true;                                                             //AAV.SP
                    PromotedCategory = Category4;                                                 //AAV.SP
                    Enabled = not OpenApprovalEntriesExist;                                       //AAV.SP
                    ToolTip = 'Send the Custom Purchase Receipt for approval through the native workflow.'; //AAV.SP

                    trigger OnAction()                                                           //AAV.SP
                    var                                                                          //AAV.SP
                        ApprMgt: Codeunit "BVR Cust Rcpt Appr Mgt";                              //AAV.SP
                        ApprEvents: Codeunit "BVR Cust Rcpt Appr Events";                        //AAV.SP
                    begin                                                                        //AAV.SP
                        ApprMgt.CheckCustomReceiptApprovalsWorkflowEnabled(Rec);                 //AAV.SP
                        ApprEvents.OnSendCustomReceiptForApproval(Rec);                          //AAV.SP
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
            }                                                                                    //AAV.SP
            action("AP Updated")                                                                 //AAV.SP
            {                                                                                    //AAV.SP
                ApplicationArea = All;                                                           //AAV.SP
                Caption = 'AP Updated';                                                          //AAV.SP
                Image = UpdateDescription;                                                       //AAV.SP
                Promoted = true;                                                                 //AAV.SP
                PromotedCategory = Category4;                                                    //AAV.SP
                Enabled = Rec."BVR Approved" and (not Rec."BVR AP Updated") and (not Rec."BVR Custom Rcpt Posted"); //AAV.SP
                ToolTip = 'Confirm the accrual accounts have been updated in AP. Locks the accrual accounts for everyone except the AP team.'; //AAV.SP

                trigger OnAction()                                                               //AAV.SP
                var                                                                              //AAV.SP
                    ApprMgt: Codeunit "BVR Cust Rcpt Appr Mgt";                                  //AAV.SP
                begin                                                                            //AAV.SP
                    ApprMgt.MarkAPUpdated(Rec);                                                  //AAV.SP
                    CurrPage.Update(false);                                                      //AAV.SP
                end;                                                                             //AAV.SP
            }                                                                                    //AAV.SP
            // <<< AAV.SP - end of native workflow approval
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
            action("Approval Queue")
            {
                ApplicationArea = All;
                Caption = 'Approval Queue';
                Image = Approvals;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    H: Record "Purchase Header";
                begin
                    Page.Run(Page::"BVR Receipt Approval Queue", H);
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
                    rec.SetRecFilter();
                    //Report.RunModal(Report::"BVR Custom Purchase Receipt", true, true, H);
                    Report.RunModal(Report::"BVR Custom Purchase Receipt", true, true, rec);
                end;
            }
            // IMPORTANT: Posting is not available on this page (P3 only)
        }
        area(navigation)
        {
            action("Open Posted Receipt")
            {
                ApplicationArea = All;
                Caption = 'Posted Receipt';
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
            action("Custom Invoice")
            {
                ApplicationArea = All;
                Caption = 'Create Custom Invoice';
                Image = Invoice;
                Promoted = true;
                PromotedCategory = New;

                trigger OnAction()
                var
                    CU: Codeunit "BVR Create Custom Invoice";
                begin
                    CU.CreateFromReceipt(Rec);
                end;
            }
        }
    }
    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."BVR Receive PO" := true;
        rec."BVR Requires Approval" := True;
    end;

    trigger OnAfterGetCurrRecord()
    var
        ApprMgt: Codeunit "BVR Cust Rcpt Appr Mgt";
    begin
        OpenApprovalEntriesExist := ApprMgt.HasOpenApprovalEntries(Rec.RecordId);
        OpenApprovalEntriesExistForCurrUser := ApprMgt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);
        AccrualAcctEditable := ApprMgt.AccrualAccountsEditable(Rec);   //AAV.SP
    end;

    var
        OpenApprovalEntriesExist: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        AccrualAcctEditable: Boolean;   //AAV.SP
}
