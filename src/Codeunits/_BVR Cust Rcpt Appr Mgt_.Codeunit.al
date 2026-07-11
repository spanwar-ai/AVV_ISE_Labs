codeunit 50244 "BVR Cust Rcpt Appr Mgt"
{
    // Native approval glue for the Custom Purchase Receipt. Mirrors the purchase-document
    // methods of codeunit 1535 "Approvals Mgmt." but keyed to our custom workflow events.
    // Because the document is a Purchase Header, the standard workflow responses and
    // Approvals Mgmt. already create/approve/reject/delegate the approval entries.

    // ---------------------------------------------------------------------
    // Workflow enablement
    // ---------------------------------------------------------------------
    procedure CheckCustomReceiptApprovalsWorkflowEnabled(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if purchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then
            exit(true);
        if not IsCustomReceiptApprovalsWorkflowEnabled(PurchaseHeader) then
            Error(NoWorkflowEnabledErr);
        exit(true);
    end;

    procedure IsCustomReceiptApprovalsWorkflowEnabled(var PurchaseHeader: Record "Purchase Header"): Boolean
    var
        WorkflowManagement: Codeunit "Workflow Management";
        CustRcptApprEvents: Codeunit "BVR Cust Rcpt Appr Events";
    begin
        if not IsCustomReceipt(PurchaseHeader) then
            exit(false);
        exit(WorkflowManagement.CanExecuteWorkflow(
            PurchaseHeader, CustRcptApprEvents.RunWorkflowOnSendCustomReceiptForApprovalCode()));
    end;

    // ---------------------------------------------------------------------
    // Send / Cancel — driven by the integration events on codeunit 50242,
    // which the page raises. This mirrors the standard decoupled pattern.
    // ---------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVR Cust Rcpt Appr Events", 'OnSendCustomReceiptForApproval', '', false, false)]
    local procedure RunWorkflowOnSendCustomReceiptForApproval(var PurchaseHeader: Record "Purchase Header")
    var
        WorkflowManagement: Codeunit "Workflow Management";
        CustRcptApprEvents: Codeunit "BVR Cust Rcpt Appr Events";
    begin
        WorkflowManagement.HandleEvent(
            CustRcptApprEvents.RunWorkflowOnSendCustomReceiptForApprovalCode(), PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVR Cust Rcpt Appr Events", 'OnCancelCustomReceiptApprovalRequest', '', false, false)]
    local procedure RunWorkflowOnCancelCustomReceiptApprovalRequest(var PurchaseHeader: Record "Purchase Header")
    var
        WorkflowManagement: Codeunit "Workflow Management";
        CustRcptApprEvents: Codeunit "BVR Cust Rcpt Appr Events";
    begin
        WorkflowManagement.HandleEvent(
            CustRcptApprEvents.RunWorkflowOnCancelCustomReceiptApprovalRequestCode(), PurchaseHeader);
    end;

    // ---------------------------------------------------------------------
    // Populate the approval entry argument (amount drives approver limits)
    // ---------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', false, false)]
    local procedure OnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        PurchaseHeader: Record "Purchase Header";
        Amount: Decimal;
    begin
        if RecRef.Number <> Database::"Purchase Header" then
            exit;
        RecRef.SetTable(PurchaseHeader);
        if not IsCustomReceipt(PurchaseHeader) then
            exit;

        Amount := CalcCustomReceiptAmount(PurchaseHeader);
        ApprovalEntryArgument."Document No." := PurchaseHeader."No.";
        ApprovalEntryArgument.Amount := Amount;
        ApprovalEntryArgument."Amount (LCY)" := Amount;
        ApprovalEntryArgument."Currency Code" := PurchaseHeader."Currency Code";
    end;

    // ---------------------------------------------------------------------
    // Drive the custom status to Released when the document is released by the
    // approval engine. This is workflow-agnostic: it fires whether the enabled
    // workflow uses our custom response or a standard purchase-approval release,
    // so the custom status never lags behind the standard Status.   //AAV.SP
    // ---------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterReleasePurchaseDoc', '', false, false)]
    local procedure OnAfterReleaseSetCustomStatusReleased(var PurchaseHeader: Record "Purchase Header")
    begin
        if not IsCustomReceipt(PurchaseHeader) then
            exit;
        // Only promote from the approval stage — never from a manual release at Open.
        if PurchaseHeader."BVR Receipt Status" <> PurchaseHeader."BVR Receipt Status"::"Pending Approval" then
            exit;

        PurchaseHeader."BVR Approved" := true;
        PurchaseHeader."BVR Sent For Approval" := true;
        PurchaseHeader."BVR Receipt Status" := PurchaseHeader."BVR Receipt Status"::Released;
        PurchaseHeader.Modify(true);
    end;

    // ---------------------------------------------------------------------
    // Reset our flags when the request is rejected or cancelled
    // ---------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnRejectApprovalRequest', '', false, false)]
    local procedure OnRejectApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
        ResetCustomReceiptFlags(ApprovalEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnCancelApprovalRequestsForRecordOnAfterSetApprovalEntryFilters', '', false, false)]
    local procedure OnCancelApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
        ResetCustomReceiptFlags(ApprovalEntry);
    end;

    local procedure ResetCustomReceiptFlags(var ApprovalEntry: Record "Approval Entry")
    var
        PurchaseHeader: Record "Purchase Header";
        RecRef: RecordRef;
    begin
        if ApprovalEntry."Table ID" <> Database::"Purchase Header" then
            exit;
        if not RecRef.Get(ApprovalEntry."Record ID to Approve") then
            exit;
        RecRef.SetTable(PurchaseHeader);
        if not IsCustomReceipt(PurchaseHeader) then
            exit;

        PurchaseHeader."BVR Approved" := false;
        PurchaseHeader."BVR Sent For Approval" := false;
        // Drop back to the AP-team stage so the AP work isn't lost on reject/cancel.   //AAV.SP
        if PurchaseHeader."BVR Receipt Status" = PurchaseHeader."BVR Receipt Status"::"Pending Approval" then   //AAV.SP
            PurchaseHeader."BVR Receipt Status" := PurchaseHeader."BVR Receipt Status"::"Sent to AP Team";       //AAV.SP
        PurchaseHeader.Modify(true);
    end;

    // ---------------------------------------------------------------------
    // Page helpers (drive Enabled/Visible)
    // ---------------------------------------------------------------------
    procedure HasOpenApprovalEntries(RecID: RecordId): Boolean
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        exit(ApprovalsMgmt.HasOpenApprovalEntries(RecID));
    end;

    procedure HasOpenApprovalEntriesForCurrentUser(RecID: RecordId): Boolean
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        exit(ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(RecID));
    end;

    // ---------------------------------------------------------------------
    // Stage 1 — creator sends the receipt to the AP team to update the accrual
    // accounts, and the AP team is notified by email.   //AAV.SP
    // ---------------------------------------------------------------------
    procedure SendToAPTeam(var PurchaseHeader: Record "Purchase Header")   //AAV.SP
    begin
        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Order);   //AAV.SP
        PurchaseHeader.TestField("BVR Receive PO", true);                                   //AAV.SP
        PurchaseHeader.TestField("BVR Requires Approval", true);                            //AAV.SP
        PurchaseHeader.TestField("BVR Receipt Status", PurchaseHeader."BVR Receipt Status"::Open);   //AAV.SP
        PurchaseHeader."BVR Receipt Status" := PurchaseHeader."BVR Receipt Status"::"Sent to AP Team";   //AAV.SP
        PurchaseHeader.Modify(true);                                                        //AAV.SP
        // The status change must stand even if the mail fails. A try function catches
        // the email error (and rolls back only the outbox write), so we can warn the
        // user to notify the AP team manually instead of aborting the whole step.   //AAV.SP
        if not TryNotifyAPTeam(PurchaseHeader) then                                         //AAV.SP
            Message(NotificationFailedMsg, PurchaseHeader."No.", GetLastErrorText());       //AAV.SP
    end;

    // Stage 2 — an AP-team user confirms the accrual accounts are updated and submits
    // the receipt to the approval workflow in one step.   //AAV.SP
    procedure MarkAPUpdatedAndSubmit(var PurchaseHeader: Record "Purchase Header")   //AAV.SP
    var
        CustRcptApprEvents: Codeunit "BVR Cust Rcpt Appr Events";   //AAV.SP
    begin
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then begin
            PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Order);   //AAV.SP
            PurchaseHeader.TestField("BVR Receive PO", true);                                   //AAV.SP
            PurchaseHeader.TestField("Vendor Invoice No.");                            //AAV.SP
            PurchaseHeader.TestField("BVR Receipt Status", PurchaseHeader."BVR Receipt Status"::"Sent to AP Team");   //AAV.SP
            if not IsAPTeam() then                                                              //AAV.SP
                Error(APTeamOnlyErr);                                                           //AAV.SP
                                                                                                // Both accrual accounts are mandatory before the receipt can go for approval.   //AAV.SP
            PurchaseHeader.TestField("BVR Vendor Accrual Acc No.");                             //AAV.SP
            PurchaseHeader.TestField("BVR Expense Accrual Acc No.");                            //AAV.SP
            CheckCustomReceiptApprovalsWorkflowEnabled(PurchaseHeader);                         //AAV.SP

            PurchaseHeader."BVR AP Updated" := true;                                            //AAV.SP
            PurchaseHeader."BVR Sent For Approval" := true;                                     //AAV.SP - keep the old boolean in sync
            PurchaseHeader."BVR Approved" := false;                                             //AAV.SP
            PurchaseHeader."BVR Receipt Status" := PurchaseHeader."BVR Receipt Status"::"Pending Approval";   //AAV.SP
            PurchaseHeader.Modify(true);                                                        //AAV.SP
        end;
        if purchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then begin
            PurchaseHeader.TestField("Vendor Invoice No.");
            PurchaseHeader.TestField(Status, PurchaseHeader.status::Open);
            CheckCustomReceiptApprovalsWorkflowEnabled(PurchaseHeader);
        end;
        // Hand off to the native workflow (creates approval entries, sends requests).   //AAV.SP
        CustRcptApprEvents.OnSendCustomReceiptForApproval(PurchaseHeader);                  //AAV.SP
    end;

    // Reopen — cancels any pending approval and resets the custom status flow back to
    // Open after a confirmation. Mirrors the standard "reopen" but for our status.   //AAV.SP
    procedure ReopenCustomReceipt(var PurchaseHeader: Record "Purchase Header")   //AAV.SP
    var
        CustRcptApprEvents: Codeunit "BVR Cust Rcpt Appr Events";   //AAV.SP
        ReopenCU: Codeunit "Purchase Manual Reopen";                //AAV.SP
    begin
        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Order);   //AAV.SP
        PurchaseHeader.TestField("BVR Receive PO", true);                                   //AAV.SP
        if PurchaseHeader."BVR Custom Rcpt Posted" then                                     //AAV.SP
            Error(CannotReopenPostedErr, PurchaseHeader."No.");                             //AAV.SP

        // Nothing to do if already fully Open.   //AAV.SP
        if (PurchaseHeader."BVR Receipt Status" = PurchaseHeader."BVR Receipt Status"::Open)   //AAV.SP
            and (PurchaseHeader.Status = PurchaseHeader.Status::Open) then begin               //AAV.SP
            Message(AlreadyOpenMsg, PurchaseHeader."No.");                                  //AAV.SP
            exit;                                                                           //AAV.SP
        end;

        if not Confirm(ConfirmReopenQst, false, PurchaseHeader."No.") then                  //AAV.SP
            exit;                                                                           //AAV.SP

        // Cancel any open approval request first (resets the standard status to Open).   //AAV.SP
        if HasOpenApprovalEntries(PurchaseHeader.RecordId) then begin                       //AAV.SP
            CustRcptApprEvents.OnCancelCustomReceiptApprovalRequest(PurchaseHeader);        //AAV.SP
            PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");       //AAV.SP
        end;

        // Reset the custom status flow completely.   //AAV.SP
        PurchaseHeader."BVR Receipt Status" := PurchaseHeader."BVR Receipt Status"::Open;   //AAV.SP
        PurchaseHeader."BVR Approved" := false;                                             //AAV.SP
        PurchaseHeader."BVR Sent For Approval" := false;                                    //AAV.SP
        PurchaseHeader."BVR AP Updated" := false;                                           //AAV.SP
        PurchaseHeader.Modify(true);                                                        //AAV.SP

        // Reopen the underlying purchase document if it is still Released.   //AAV.SP
        if PurchaseHeader.Status <> PurchaseHeader.Status::Open then                        //AAV.SP
            ReopenCU.Run(PurchaseHeader);                                                   //AAV.SP

        Message(ReopenedMsg, PurchaseHeader."No.");                                         //AAV.SP
    end;

    // Legacy single-step mark (kept for the old boolean flow / batch pages).   //AAV.SP
    procedure MarkAPUpdated(var PurchaseHeader: Record "Purchase Header")   //AAV.SP
    begin
        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Order);   //AAV.SP
        PurchaseHeader.TestField("BVR Receive PO", true);                                   //AAV.SP
        PurchaseHeader."BVR AP Updated" := true;                                            //AAV.SP
        PurchaseHeader.Modify(true);                                                        //AAV.SP
    end;

    // Email the AP team that a receipt is waiting for accrual-account updates.
    // Try function: any failure (no AP email configured, no email account, send error)
    // is returned as false to the caller instead of aborting the status change.   //AAV.SP
    [TryFunction]
    local procedure TryNotifyAPTeam(var PurchaseHeader: Record "Purchase Header")   //AAV.SP
    var
        EmailMessage: Codeunit "Email Message";            //AAV.SP
        Email: Codeunit "Email";                           //AAV.SP
        Recipients: List of [Text];                        //AAV.SP
    begin
        GetAPRecipients(Recipients);                                                        //AAV.SP
        EmailMessage.Create(                                                                //AAV.SP
            Recipients,                                                                     //AAV.SP
            StrSubstNo(APMailSubjectTxt, PurchaseHeader."No."),                             //AAV.SP
            StrSubstNo(APMailBodyTxt, PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor Name"), //AAV.SP
            false);                                                                         //AAV.SP
        Email.Enqueue(EmailMessage);                                                        //AAV.SP
    end;

    // Notify the AP team that a custom receipt has been POSTED, with posting details.
    // Try-wrapped so a mail failure never rolls back the posting.   //AAV.SP
    procedure NotifyAPTeamReceiptPosted(PostedReceiptNo: Code[20])   //AAV.SP
    begin
        if not TryNotifyAPTeamPosted(PostedReceiptNo) then                                  //AAV.SP
            Message(PostNotificationFailedMsg, PostedReceiptNo, GetLastErrorText());        //AAV.SP
    end;

    [TryFunction]
    local procedure TryNotifyAPTeamPosted(PostedReceiptNo: Code[20])   //AAV.SP
    var
        RcptHdr: Record "Purch. Rcpt. Header";             //AAV.SP
        RcptLine: Record "Purch. Rcpt. Line";              //AAV.SP
        EmailMessage: Codeunit "Email Message";            //AAV.SP
        Email: Codeunit "Email";                           //AAV.SP
        Recipients: List of [Text];                        //AAV.SP
        TotalAccrued: Decimal;                             //AAV.SP
    begin
        RcptHdr.Get(PostedReceiptNo);                                                       //AAV.SP

        RcptLine.SetRange("Document No.", PostedReceiptNo);                                 //AAV.SP
        RcptLine.SetRange("BVR Custom Receipt", true);                                      //AAV.SP
        if RcptLine.FindSet() then                                                          //AAV.SP
            repeat                                                                          //AAV.SP
                TotalAccrued += RcptLine."BVR Accrued Amount";                              //AAV.SP
            until RcptLine.Next() = 0;                                                       //AAV.SP

        GetAPRecipients(Recipients);                                                        //AAV.SP
        EmailMessage.Create(                                                                //AAV.SP
            Recipients,                                                                     //AAV.SP
            StrSubstNo(APPostedSubjectTxt, RcptHdr."No."),                                  //AAV.SP
            StrSubstNo(                                                                     //AAV.SP
                APPostedBodyTxt,                                                            //AAV.SP
                RcptHdr."No.",                                                              //AAV.SP
                RcptHdr."Order No.",                                                        //AAV.SP
                RcptHdr."Buy-from Vendor No.",                                              //AAV.SP
                RcptHdr."Buy-from Vendor Name",                                             //AAV.SP
                Format(RcptHdr."Posting Date"),                                             //AAV.SP
                Format(TotalAccrued, 0, '<Precision,2:2><Standard Format,0>'),              //AAV.SP
                RcptHdr."BVR Expense Accrual Acc No.",                                       //AAV.SP
                RcptHdr."BVR Vendor Accrual Acc No."),                                       //AAV.SP
            true);                                                                          //AAV.SP
        Email.Enqueue(EmailMessage);                                                        //AAV.SP
    end;

    // Shared recipient list from the AP Team Email on Purchases & Payables Setup.   //AAV.SP
    local procedure GetAPRecipients(var Recipients: List of [Text])   //AAV.SP
    var
        PurchSetup: Record "Purchases & Payables Setup";   //AAV.SP
        Address: Text;                                     //AAV.SP
    begin
        PurchSetup.Get();                                                                   //AAV.SP
        PurchSetup.TestField("BVR AP Team Email");                                          //AAV.SP
        foreach Address in PurchSetup."BVR AP Team Email".Split(';') do                     //AAV.SP
            if Address.Trim() <> '' then                                                    //AAV.SP
                Recipients.Add(Address.Trim());                                             //AAV.SP
    end;

    // True when the current user is flagged as AP team on User Setup. Such users
    // may still edit the accrual accounts after the receipt is "AP Updated".   //AAV.SP
    procedure IsAPTeam(): Boolean   //AAV.SP
    var
        UserSetup: Record "User Setup";   //AAV.SP
    begin
        if not UserSetup.Get(UserId()) then   //AAV.SP
            exit(false);                       //AAV.SP
        exit(UserSetup."BVR AP Team");         //AAV.SP
    end;

    // True when the accrual accounts may be edited. In the status flow the accruals
    // are the AP team's job: editable only while the receipt sits at "Sent to AP Team"
    // and only by an AP-team user (never once posted).   //AAV.SP
    procedure AccrualAccountsEditable(var PurchaseHeader: Record "Purchase Header"): Boolean   //AAV.SP
    begin
        if PurchaseHeader."BVR Custom Rcpt Posted" then   //AAV.SP
            exit(false);                                  //AAV.SP
        exit((PurchaseHeader."BVR Receipt Status" = PurchaseHeader."BVR Receipt Status"::"Sent to AP Team") and IsAPTeam());   //AAV.SP
    end;

    // ---------------------------------------------------------------------
    // Internals
    // ---------------------------------------------------------------------
    local procedure IsCustomReceipt(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        exit((PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order) and PurchaseHeader."BVR Receive PO");
    end;

    local procedure CalcCustomReceiptAmount(var PurchaseHeader: Record "Purchase Header"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        Amount: Decimal;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                Amount += Round(PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity, 0.01);
            until PurchaseLine.Next() = 0;
        exit(Amount);
    end;

    var
        NoWorkflowEnabledErr: Label 'No approval workflow is enabled for Custom Purchase Receipts. Enable the "Custom Receipt Approval Workflow" first.';
        APTeamOnlyErr: Label 'Only AP-team users can update the accrual accounts and submit the receipt for approval.';   //AAV.SP
        APMailSubjectTxt: Label 'Custom Receipt %1 awaiting AP accrual update', Comment = '%1 = Custom Receipt No.';   //AAV.SP
        APMailBodyTxt: Label 'Custom Purchase Receipt %1 (Vendor %2 - %3) has been sent to the AP team to update the accrual accounts. Please update the Vendor and Expense accrual accounts, then submit it for approval.', Comment = '%1 = Receipt No., %2 = Vendor No., %3 = Vendor Name';   //AAV.SP
        NotificationFailedMsg: Label 'Receipt %1 was sent to the AP team, but the email notification could NOT be sent. Please inform the AP team manually.\\Details: %2', Comment = '%1 = Receipt No., %2 = error details';   //AAV.SP
        APPostedSubjectTxt: Label 'Custom Receipt %1 posted', Comment = '%1 = Posted Receipt No.';   //AAV.SP
        APPostedBodyTxt: Label 'Custom Purchase Receipt <b>%1</b> (Order %2) has been posted.<br>Vendor: %3 - %4<br>Posting Date: %5<br>Total Accrued Amount: %6<br>Expense Accrual Account: %7<br>Vendor Accrual Account: %8', Comment = '%1=Receipt No,%2=Order No,%3=Vendor No,%4=Vendor Name,%5=Posting Date,%6=Total Accrued,%7=Expense Acc,%8=Vendor Acc';   //AAV.SP
        PostNotificationFailedMsg: Label 'Custom Receipt %1 was posted, but the AP posting notification could NOT be sent. Please inform the AP team manually.\\Details: %2', Comment = '%1 = Receipt No., %2 = error details';   //AAV.SP
        ConfirmReopenQst: Label 'Reopen Custom Receipt %1?\\This cancels any pending approval and resets the status back to Open.', Comment = '%1 = Receipt No.';   //AAV.SP
        ReopenedMsg: Label 'Custom Receipt %1 has been reopened and its status reset to Open.', Comment = '%1 = Receipt No.';   //AAV.SP
        AlreadyOpenMsg: Label 'Custom Receipt %1 is already open.', Comment = '%1 = Receipt No.';   //AAV.SP
        CannotReopenPostedErr: Label 'Custom Receipt %1 has already been posted and cannot be reopened.', Comment = '%1 = Receipt No.';   //AAV.SP
}
