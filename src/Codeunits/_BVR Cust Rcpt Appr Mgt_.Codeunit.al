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
    // AP-team stage — only available after the receipt is approved.   //AAV.SP
    // ---------------------------------------------------------------------
    procedure MarkAPUpdated(var PurchaseHeader: Record "Purchase Header")   //AAV.SP
    begin
        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Order);   //AAV.SP
        PurchaseHeader.TestField("BVR Receive PO", true);                                   //AAV.SP
        PurchaseHeader.TestField("BVR Approved", true);                                     //AAV.SP
        PurchaseHeader."BVR AP Updated" := true;                                            //AAV.SP
        PurchaseHeader.Modify(true);                                                        //AAV.SP
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

    // True when the accrual accounts may be edited: freely before "AP Updated",
    // and only by AP-team users afterwards.   //AAV.SP
    procedure AccrualAccountsEditable(var PurchaseHeader: Record "Purchase Header"): Boolean   //AAV.SP
    begin
        if PurchaseHeader."BVR Custom Rcpt Posted" then   //AAV.SP
            exit(false);                                  //AAV.SP
        exit((not PurchaseHeader."BVR AP Updated") or IsAPTeam());   //AAV.SP
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
}
