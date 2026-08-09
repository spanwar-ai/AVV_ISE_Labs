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
            field(BVRAmount; BVRAmount)   //AAV.SP
            {
                ApplicationArea = Warehouse;
                Caption = 'Amount (LCY)';
                Editable = false;
                AutoFormatType = 1;
                ToolTip = 'Specifies the value of what this receipt is about to bring in: the quantity to receive on each line at the purchase order''s unit cost, less any line discount. Excludes VAT, which is not calculated until the invoice.';
            }
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
            // Same gate as the accrual accounts: AP team only, while the receipt is Sent to AP Team.
            // The lookup allows insert, so a new batch can be created here without leaving the
            // receipt.   //AAV.SP
            field("BVR Batch No."; Rec."BVR Batch No.")   //AAV.SP
            {
                ApplicationArea = Warehouse;
                Editable = AccrualEditable;
                ToolTip = 'Specifies the batch this Warehouse Receipt belongs to. Choose an existing batch or create a new one from the lookup. Editable only by the AP team while the receipt is Sent to AP Team. It is carried onto the Posted Purchase Receipt when this receipt is posted.';
            }
            field("BVR Shortcut Dimension 1 Code"; Rec."BVR Shortcut Dimension 1 Code")   //AAV.SP
            {
                ApplicationArea = Dimensions;
                Editable = AccrualEditable;   //AAV.SP
                ToolTip = 'Specifies the global dimension 1 code applied to the source Purchase Order - and so to the posted receipt and its G/L entries - when this Warehouse Receipt is posted. Leave blank to keep the dimension already on the order.';
            }
            field("BVR Shortcut Dimension 2 Code"; Rec."BVR Shortcut Dimension 2 Code")   //AAV.SP
            {
                ApplicationArea = Dimensions;
                Editable = AccrualEditable;   //AAV.SP
                ToolTip = 'Specifies the global dimension 2 code applied to the source Purchase Order - and so to the posted receipt and its G/L entries - when this Warehouse Receipt is posted. Leave blank to keep the dimension already on the order.';
            }
        }
        // Attachments on the Warehouse Receipt. The AP team / warehouse can attach the supplier
        // packing slip, delivery note etc. here; codeunit "BVR Copy Attachments" copies them onto
        // the posted Purchase Receipt(s) when the WR is posted (the WR itself is deleted after
        // posting, so this is a MOVE - see "BVR Whse Receipt Mgt"). Same standard factbox the
        // custom-receipt flow uses, keyed on table 7316.   //AAV.SP
        addfirst(factboxes)
        {
            part(BVRDocAttach; "Doc. Attachment List Factbox")
            {
                Caption = 'Attachments';
                ApplicationArea = Warehouse;
                SubPageLink = "Table ID" = const(7316), "No." = field("No.");
            }
        }
    }

    actions
    {
        // A receipt that has been put into a batch is posted from the batch, together with the rest
        // of it - so the posting buttons on this page are switched off while a Batch No. is filled
        // in. Clearing the Batch No. brings them back.
        //
        // Preview Posting is deliberately left alone: it posts nothing, and it is the most useful way
        // to check a receipt before its batch goes.   //AAV.SP
        modify("Post Receipt")
        {
            Enabled = BVRPostAllowed;
        }
        modify("Post and &Print")
        {
            Enabled = BVRPostAllowed;
        }
        modify("Post and Print P&ut-away")
        {
            Enabled = BVRPostAllowed;
        }
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
        BVRPostAllowed := Rec."BVR Batch No." = '';   //AAV.SP
        BVRAmount := Rec.BVRCalcAmount();   //AAV.SP
    end;

    var
        AccrualEditable: Boolean;   //AAV
        IsAPTeamUser: Boolean;   //AAV.SP
        OpenApprovalEntriesForCurrUser: Boolean;   //AAV.SP
        BVRPostAllowed: Boolean;   //AAV.SP
        BVRAmount: Decimal;   //AAV.SP
}
