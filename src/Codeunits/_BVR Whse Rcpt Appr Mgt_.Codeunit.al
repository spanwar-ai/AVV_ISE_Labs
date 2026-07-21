codeunit 50130 "BVR Whse Rcpt Appr Mgt"
{
    // Warehouse-Receipt approval flow - management glue.
    //   Part 2A - the status hand-off (Send to AP) and accrual-account editability.
    //   Part 2B - Send for Approval raises the native workflow; Approve / Reject / Delegate /
    //             Cancel drive the STANDARD Approvals engine on table 7316.
    //
    // Status model (maximum-standard): the workflow is built with Microsoft's document-approval
    // builder, so - exactly like Purchase Order approval - the WORKFLOW RESPONSES drive the status.
    // The custom "BVR Receipt Status" simply mirrors the standard document responses via their
    // integration events, so it is correct for manual approval, self/auto-approval on send, approver
    // chains, reject, cancel and delegate:
    //   OnSetStatusToPendingApproval (Set Status to Pending Approval) -> Pending Approval
    //   OnReleaseDocument            (Release Document, all approved) -> Released
    //   OnOpenDocument               (Open Document, reject / cancel) -> Sent to AP Team
    // Release Document / Open Document would otherwise raise "unsupported record type" on this custom
    // table; the subscribers below map them onto our status and set Handled := true. The workflow's
    // own "no pending approvals" condition guarantees Release only fires once the whole chain is
    // approved, so there is no chain bookkeeping to do here.   //AAV.SP
    Permissions = tabledata "Warehouse Receipt Header" = rm;

    // ---------------------------------------------------------------------
    // Part 2A - creator sends the WR to the AP team to update the accrual accounts.
    // ---------------------------------------------------------------------
    procedure SendToAPTeam(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        WhseReceiptHeader.TestField("BVR Receipt Status", WhseReceiptHeader."BVR Receipt Status"::Open);
        CheckHasLines(WhseReceiptHeader);
        WhseReceiptHeader."BVR Requires Approval" := true;   // opts this WR into the flow (drives the posting gate)
        WhseReceiptHeader."BVR Sent To AP Team" := true;
        WhseReceiptHeader."BVR Receipt Status" := WhseReceiptHeader."BVR Receipt Status"::"Sent to AP Team";
        WhseReceiptHeader.Modify(true);
        if not TryNotifyAPTeam(WhseReceiptHeader) then
            Message(NotificationFailedMsg, WhseReceiptHeader."No.", GetLastErrorText());
    end;

    // ---------------------------------------------------------------------
    // Part 2B - the AP team confirms the accruals and submits to the approval workflow.
    // ---------------------------------------------------------------------
    procedure SubmitForApproval(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WhseRcptApprEvents: Codeunit "BVR Whse Rcpt Appr Events";
    begin
        WhseReceiptHeader.TestField("BVR Receipt Status", WhseReceiptHeader."BVR Receipt Status"::"Sent to AP Team");
        if not IsAPTeam() then
            Error(APTeamOnlyErr);
        WhseReceiptHeader.TestField("BVR Vendor Accrual Acc No.");
        WhseReceiptHeader.TestField("BVR Expense Accrual Acc No.");
        CheckWorkflowEnabled(WhseReceiptHeader);

        // Hand off to the native workflow. The document responses set the status: Pending Approval
        // (Set Status to Pending Approval), or straight to Released (Release Document) when the
        // sender is a sufficient approver and the request auto-approves during send.   //AAV.SP
        WhseRcptApprEvents.OnSendWhseReceiptForApproval(WhseReceiptHeader);
        WhseReceiptHeader.Get(WhseReceiptHeader."No.");
    end;

    procedure ApproveRequest(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalsMgmt.ApproveRecordApprovalRequest(WhseReceiptHeader.RecordId);
    end;

    procedure RejectRequest(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalsMgmt.RejectRecordApprovalRequest(WhseReceiptHeader.RecordId);
    end;

    procedure DelegateRequest(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalsMgmt.DelegateRecordApprovalRequest(WhseReceiptHeader.RecordId);
    end;

    // Cancel the pending request and return to Sent to AP Team (so the AP team can resubmit),
    // without going all the way back to Open. Runs the workflow's cancel branch first (like the
    // purchase Cancel Approval Request action), then falls back to the standard record-level cancel
    // if no workflow instance handled it. Either path routes through CancelApprovalRequestsForRecord,
    // so our OnCancel handler resets the status.   //AAV.SP
    procedure CancelApprovalRequest(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WhseRcptApprEvents: Codeunit "BVR Whse Rcpt Appr Events";
    begin
        if ApprovalsMgmt.HasOpenOrPendingApprovalEntries(WhseReceiptHeader.RecordId) then begin
            WhseRcptApprEvents.OnCancelWhseReceiptApproval(WhseReceiptHeader);
            WhseReceiptHeader.Get(WhseReceiptHeader."No.");
        end;
        // Fallback: anything the workflow branch did not cancel (e.g. no active instance).
        if ApprovalsMgmt.HasOpenApprovalEntries(WhseReceiptHeader.RecordId) then begin
            DirectCancelApprovals(WhseReceiptHeader);
            WhseReceiptHeader.Get(WhseReceiptHeader."No.");
        end;
    end;

    // Return the WR to Open. Cancels any open approval first, then drops it all the way to Open.
    procedure Reopen(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        if WhseReceiptHeader."BVR Receipt Status" = WhseReceiptHeader."BVR Receipt Status"::Open then begin
            Message(AlreadyOpenMsg, WhseReceiptHeader."No.");
            exit;
        end;
        DirectCancelApprovals(WhseReceiptHeader);
        WhseReceiptHeader.Get(WhseReceiptHeader."No.");
        WhseReceiptHeader."BVR Receipt Status" := WhseReceiptHeader."BVR Receipt Status"::Open;
        WhseReceiptHeader."BVR Sent To AP Team" := false;
        WhseReceiptHeader.Modify(true);
        Message(ReopenedMsg, WhseReceiptHeader."No.");
    end;

    // Cancel every open approval request for the receipt via the standard framework. Raises
    // OnCancelApprovalRequestsForRecordOnAfterSetApprovalEntryFilters, which our handler uses to
    // reset the status to Sent to AP Team.   //AAV.SP
    local procedure DirectCancelApprovals(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowStepInstance: Record "Workflow Step Instance";
        RecRef: RecordRef;
    begin
        if not ApprovalsMgmt.HasOpenApprovalEntries(WhseReceiptHeader.RecordId) then
            exit;
        RecRef.GetTable(WhseReceiptHeader);
        ApprovalsMgmt.CancelApprovalRequestsForRecord(RecRef, WorkflowStepInstance);
    end;

    // ---------------------------------------------------------------------
    // Raise the workflow when the send integration event fires (decoupled pattern).   //AAV.SP
    // ---------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVR Whse Rcpt Appr Events", 'OnSendWhseReceiptForApproval', '', false, false)]
    local procedure RunWorkflowOnSendWhseReceiptForApproval(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WorkflowManagement: Codeunit "Workflow Management";
        WhseRcptApprEvents: Codeunit "BVR Whse Rcpt Appr Events";
    begin
        WorkflowManagement.HandleEvent(WhseRcptApprEvents.RunWorkflowOnSendWhseReceiptForApprovalCode(), WhseReceiptHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BVR Whse Rcpt Appr Events", 'OnCancelWhseReceiptApproval', '', false, false)]
    local procedure RunWorkflowOnCancelWhseReceiptApproval(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WorkflowManagement: Codeunit "Workflow Management";
        WhseRcptApprEvents: Codeunit "BVR Whse Rcpt Appr Events";
    begin
        WorkflowManagement.HandleEvent(WhseRcptApprEvents.RunWorkflowOnCancelWhseReceiptApprovalRequestCode(), WhseReceiptHeader);
    end;

    // ---------------------------------------------------------------------
    // Status sync - the ONLY place the custom status follows the native approval lifecycle.
    // ---------------------------------------------------------------------

    // Standard "Set Status to Pending Approval" response calls this for tables it does not know
    // natively. Set our status and mark handled.   //AAV.SP
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnSetStatusToPendingApproval', '', false, false)]
    local procedure OnSetStatusToPendingApproval(RecRef: RecordRef; var Variant: Variant; var IsHandled: Boolean)
    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        if RecRef.Number <> Database::"Warehouse Receipt Header" then
            exit;
        RecRef.SetTable(WhseReceiptHeader);
        SetStatus(WhseReceiptHeader, WhseReceiptHeader."BVR Receipt Status"::"Pending Approval");
        IsHandled := true;
    end;

    // The workflow's "Release Document" response fires once every approval is granted (its "no
    // pending approvals" condition covers the whole approver chain). Map it onto Released and mark
    // it handled, since the base app cannot release a Warehouse Receipt itself.   //AAV.SP
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', false, false)]
    local procedure OnReleaseWhseReceipt(RecRef: RecordRef; var Handled: Boolean)
    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        if RecRef.Number <> Database::"Warehouse Receipt Header" then
            exit;
        RecRef.SetTable(WhseReceiptHeader);
        if WhseReceiptHeader.Get(WhseReceiptHeader."No.") then
            SetStatus(WhseReceiptHeader, WhseReceiptHeader."BVR Receipt Status"::Released);
        Handled := true;
    end;

    // The workflow's "Open Document" response fires on reject and on cancel. Return the receipt to
    // Sent to AP Team (keeping the AP accrual work) and mark it handled.   //AAV.SP
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnOpenDocument', '', false, false)]
    local procedure OnOpenWhseReceipt(RecRef: RecordRef; var Handled: Boolean)
    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        if RecRef.Number <> Database::"Warehouse Receipt Header" then
            exit;
        RecRef.SetTable(WhseReceiptHeader);
        if WhseReceiptHeader.Get(WhseReceiptHeader."No.") then
            SetStatus(WhseReceiptHeader, WhseReceiptHeader."BVR Receipt Status"::"Sent to AP Team");
        Handled := true;
    end;

    // Supply Document No. + Amount for the approval entry (Amount drives value-based approver
    // limits). A WR line carries no cost, so the amount is summed from the source purchase lines.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', false, false)]
    local procedure OnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        Amount: Decimal;
    begin
        if RecRef.Number <> Database::"Warehouse Receipt Header" then
            exit;
        RecRef.SetTable(WhseReceiptHeader);
        Amount := CalcWhseReceiptAmount(WhseReceiptHeader);
        ApprovalEntryArgument."Document No." := WhseReceiptHeader."No.";
        ApprovalEntryArgument.Amount := Amount;
        ApprovalEntryArgument."Amount (LCY)" := Amount;
    end;

    // ---------------------------------------------------------------------
    // Status helpers
    // ---------------------------------------------------------------------
    local procedure SetStatus(var WhseReceiptHeader: Record "Warehouse Receipt Header"; NewStatus: Enum "BVR Receipt Status")
    begin
        if WhseReceiptHeader."BVR Receipt Status" = NewStatus then
            exit;
        WhseReceiptHeader."BVR Receipt Status" := NewStatus;
        WhseReceiptHeader.Modify(true);
    end;

    local procedure CalcWhseReceiptAmount(var WhseReceiptHeader: Record "Warehouse Receipt Header"): Decimal
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseLine: Record "Purchase Line";
        Amount: Decimal;
    begin
        WhseReceiptLine.SetRange("No.", WhseReceiptHeader."No.");
        if WhseReceiptLine.FindSet() then
            repeat
                if PurchaseLine.Get(PurchaseLine."Document Type"::Order, WhseReceiptLine."Source No.", WhseReceiptLine."Source Line No.") then
                    Amount += Round(PurchaseLine."Direct Unit Cost" * WhseReceiptLine."Qty. to Receive", 0.01);
            until WhseReceiptLine.Next() = 0;
        exit(Amount);
    end;

    // ---------------------------------------------------------------------
    // Workflow enablement + page helpers
    // ---------------------------------------------------------------------
    procedure IsWhseReceiptApprovalsWorkflowEnabled(var WhseReceiptHeader: Record "Warehouse Receipt Header"): Boolean
    var
        WorkflowManagement: Codeunit "Workflow Management";
        WhseRcptApprEvents: Codeunit "BVR Whse Rcpt Appr Events";
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(WhseReceiptHeader, WhseRcptApprEvents.RunWorkflowOnSendWhseReceiptForApprovalCode()));
    end;

    local procedure CheckWorkflowEnabled(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        if not IsWhseReceiptApprovalsWorkflowEnabled(WhseReceiptHeader) then
            Error(NoWorkflowEnabledErr);
    end;

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
    // Shared helpers (2A)
    // ---------------------------------------------------------------------
    procedure IsAPTeam(): Boolean
    var
        CustApprMgt: Codeunit "BVR Cust Rcpt Appr Mgt";
    begin
        exit(CustApprMgt.IsAPTeam());
    end;

    procedure AccrualAccountsEditable(var WhseReceiptHeader: Record "Warehouse Receipt Header"): Boolean
    begin
        exit((WhseReceiptHeader."BVR Receipt Status" = WhseReceiptHeader."BVR Receipt Status"::"Sent to AP Team") and IsAPTeam());
    end;

    local procedure CheckHasLines(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WhseReceiptLine.SetRange("No.", WhseReceiptHeader."No.");
        if WhseReceiptLine.IsEmpty() then
            Error(NoLinesErr, WhseReceiptHeader."No.");
    end;

    [TryFunction]
    local procedure TryNotifyAPTeam(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        PurchSetup: Record "Purchases & Payables Setup";
        EmailMessage: Codeunit "Email Message";
        Email: Codeunit "Email";
        Recipients: List of [Text];
        Address: Text;
    begin
        PurchSetup.Get();
        PurchSetup.TestField("BVR AP Team Email");
        foreach Address in PurchSetup."BVR AP Team Email".Split(';') do
            if Address.Trim() <> '' then
                Recipients.Add(Address.Trim());
        EmailMessage.Create(
            Recipients,
            StrSubstNo(APMailSubjectTxt, WhseReceiptHeader."No."),
            StrSubstNo(APMailBodyTxt, WhseReceiptHeader."No.", WhseReceiptHeader."Location Code"),
            false);
        Email.Enqueue(EmailMessage);
    end;

    var
        APTeamOnlyErr: Label 'Only AP-team users can update the accrual accounts and submit the receipt for approval.';
        NoLinesErr: Label 'Warehouse Receipt %1 has no lines to receive. Get the source documents first.', Comment = '%1 = Warehouse Receipt No.';
        NoWorkflowEnabledErr: Label 'No approval workflow is enabled for Warehouse Receipts. Run "Enable Warehouse Receipt Approval" on Purchases & Payables Setup first.';
        NotificationFailedMsg: Label 'Warehouse Receipt %1 was sent to the AP team, but the email notification could NOT be sent. Please inform the AP team manually.\\Details: %2', Comment = '%1 = WR No., %2 = error details';
        AlreadyOpenMsg: Label 'Warehouse Receipt %1 is already open.', Comment = '%1 = Warehouse Receipt No.';
        ReopenedMsg: Label 'Warehouse Receipt %1 has been reopened and its status reset to Open.', Comment = '%1 = Warehouse Receipt No.';
        APMailSubjectTxt: Label 'Warehouse Receipt %1 awaiting AP accrual update', Comment = '%1 = Warehouse Receipt No.';
        APMailBodyTxt: Label 'Warehouse Receipt %1 (Location %2) has been sent to the AP team. Please update the Vendor and Expense accrual accounts, then send it for approval.', Comment = '%1 = WR No., %2 = Location Code';
}
