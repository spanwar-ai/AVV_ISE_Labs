pageextension 50114 "BVR Warehouse Receipt Ext" extends "Warehouse Receipt"
{
    // Warehouse-Receipt approval flow.
    //   Step 1  - surface Status + accrual accounts, gate posting until Released.
    //   Part 2A - Send to AP -> reveal Send for Approval; AP-team-only accrual editing.   //AAV.SP
    // The Send for Approval engine and Approve/Reject/Delegate come in Part 2B.
    layout
    {
        addlast(General)
        {
            field("BVR Receipt Status"; Rec."BVR Receipt Status")   //AAV
            {
                ApplicationArea = Warehouse;
                Editable = false;
                ToolTip = 'Specifies where this Warehouse Receipt is in the AP / approval flow: Open, Sent to AP Team, Pending Approval, Released, or Posted.';
            }
            field("BVR Requires Approval"; Rec."BVR Requires Approval")   //AAV
            {
                ApplicationArea = Warehouse;
                Editable = false;
                ToolTip = 'Specifies that this Warehouse Receipt must go through the AP / approval flow and can only be posted once Released. Set when it is sent to the AP team.';
            }
            field("BVR Sent To AP Team"; Rec."BVR Sent To AP Team")   //AAV
            {
                ApplicationArea = Warehouse;
                Editable = false;
                ToolTip = 'Specifies that this Warehouse Receipt has been sent to the AP team to update the accrual accounts.';
            }
            field("BVR Expense Accrual Acc No."; Rec."BVR Expense Accrual Acc No.")   //AAV
            {
                ApplicationArea = Warehouse;
                Editable = AccrualEditable;   //AAV.SP
                ToolTip = 'G/L account debited (Expense Accrual) when this Warehouse Receipt is posted. Editable only by the AP team while the receipt is Sent to AP Team.';
            }
            field("BVR Vendor Accrual Acc No."; Rec."BVR Vendor Accrual Acc No.")   //AAV
            {
                ApplicationArea = Warehouse;
                Editable = AccrualEditable;   //AAV.SP
                ToolTip = 'G/L account credited (Vendor Accrual / GRNI liability) when this Warehouse Receipt is posted. Editable only by the AP team while the receipt is Sent to AP Team.';
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            // Step 1: creator sends the receipt to the AP team. Visible only at Open.   //AAV.SP
            action("BVR Send to AP")   //AAV.SP
            {
                ApplicationArea = Warehouse;
                Caption = 'Send to AP';
                Image = SendTo;
                Visible = Rec."BVR Receipt Status" = Rec."BVR Receipt Status"::Open;
                ToolTip = 'Send this Warehouse Receipt to the AP team to update the accrual accounts. The AP team is notified by email and can then send it for approval.';

                trigger OnAction()
                var
                    ApprMgt: Codeunit "BVR Whse Rcpt Appr Mgt";
                begin
                    ApprMgt.SendToAPTeam(Rec);
                    CurrPage.Update(false);
                end;
            }
            // Part 2A: becomes visible once sent to AP; enabled only for AP-team users after
            // both accrual accounts are filled. The workflow behind it is wired in Part 2B.   //AAV.SP
            action("BVR Send for Approval")   //AAV.SP
            {
                ApplicationArea = Warehouse;
                Caption = 'Send for Approval';
                Image = SendApprovalRequest;
                Visible = Rec."BVR Receipt Status" = Rec."BVR Receipt Status"::"Sent to AP Team";
                Enabled = IsAPTeamUser
                          and (Rec."BVR Expense Accrual Acc No." <> '')
                          and (Rec."BVR Vendor Accrual Acc No." <> '');
                ToolTip = 'Confirm the accrual accounts are updated and send this Warehouse Receipt for approval. Available to AP-team users once both accrual accounts are filled.';

                trigger OnAction()
                var
                    ApprMgt: Codeunit "BVR Whse Rcpt Appr Mgt";
                begin
                    ApprMgt.SubmitForApproval(Rec);
                    CurrPage.Update(false);
                end;
            }
            // Return the receipt to Open. Visible once past Open.   //AAV.SP
            action("BVR Reopen Receipt")   //AAV.SP
            {
                ApplicationArea = Warehouse;
                Caption = 'Reopen';
                Image = ReOpen;
                Visible = Rec."BVR Receipt Status" <> Rec."BVR Receipt Status"::Open;
                ToolTip = 'Reopen this Warehouse Receipt and reset its status to Open.';

                trigger OnAction()
                var
                    ApprMgt: Codeunit "BVR Whse Rcpt Appr Mgt";
                begin
                    ApprMgt.Reopen(Rec);
                    CurrPage.Update(false);
                end;
            }
            // Part 2B: approval actions - visible only to a user with an open approval request
            // on this receipt.   //AAV.SP
            action("BVR Approve")   //AAV.SP
            {
                ApplicationArea = Warehouse;
                Caption = 'Approve';
                Image = Approve;
                Visible = OpenApprovalEntriesForCurrUser;
                ToolTip = 'Approve the pending approval request for this Warehouse Receipt.';

                trigger OnAction()
                var
                    ApprMgt: Codeunit "BVR Whse Rcpt Appr Mgt";
                begin
                    ApprMgt.ApproveRequest(Rec);
                    CurrPage.Update(false);
                end;
            }
            action("BVR Reject")   //AAV.SP
            {
                ApplicationArea = Warehouse;
                Caption = 'Reject';
                Image = Reject;
                Visible = OpenApprovalEntriesForCurrUser;
                ToolTip = 'Reject the pending approval request for this Warehouse Receipt.';

                trigger OnAction()
                var
                    ApprMgt: Codeunit "BVR Whse Rcpt Appr Mgt";
                begin
                    ApprMgt.RejectRequest(Rec);
                    CurrPage.Update(false);
                end;
            }
            action("BVR Delegate")   //AAV.SP
            {
                ApplicationArea = Warehouse;
                Caption = 'Delegate';
                Image = Delegate;
                Visible = OpenApprovalEntriesForCurrUser;
                ToolTip = 'Delegate the pending approval request for this Warehouse Receipt to the substitute approver.';

                trigger OnAction()
                var
                    ApprMgt: Codeunit "BVR Whse Rcpt Appr Mgt";
                begin
                    ApprMgt.DelegateRequest(Rec);
                    CurrPage.Update(false);
                end;
            }
            // Cancel the pending request and return to Sent to AP Team (the sender's undo).   //AAV.SP
            action("BVR Cancel Approval Request")   //AAV.SP
            {
                ApplicationArea = Warehouse;
                Caption = 'Cancel Approval Request';
                Image = Cancel;
                Visible = Rec."BVR Receipt Status" = Rec."BVR Receipt Status"::"Pending Approval";
                ToolTip = 'Cancel the pending approval request and return this Warehouse Receipt to Sent to AP Team.';

                trigger OnAction()
                var
                    ApprMgt: Codeunit "BVR Whse Rcpt Appr Mgt";
                begin
                    ApprMgt.CancelApprovalRequest(Rec);
                    CurrPage.Update(false);
                end;
            }
            // View the native approval requests / history for this receipt.   //AAV.SP
            action("BVR Approvals")   //AAV.SP
            {
                ApplicationArea = Warehouse;
                Caption = 'Approvals';
                Image = Approvals;
                ToolTip = 'View the approval requests and approval history for this Warehouse Receipt.';

                trigger OnAction()
                var
                    ApprovalEntry: Record "Approval Entry";
                begin
                    ApprovalEntry.SetRange("Table ID", Database::"Warehouse Receipt Header");
                    ApprovalEntry.SetRange("Record ID to Approve", Rec.RecordId);
                    Page.Run(Page::"Approval Entries", ApprovalEntry);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        ApprMgt: Codeunit "BVR Whse Rcpt Appr Mgt";
    begin
        IsAPTeamUser := ApprMgt.IsAPTeam();
        AccrualEditable := ApprMgt.AccrualAccountsEditable(Rec);
        OpenApprovalEntriesForCurrUser := ApprMgt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);
    end;

    var
        AccrualEditable: Boolean;   //AAV
        IsAPTeamUser: Boolean;   //AAV.SP
        OpenApprovalEntriesForCurrUser: Boolean;   //AAV.SP
}
