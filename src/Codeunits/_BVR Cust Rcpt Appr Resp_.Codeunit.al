codeunit 50243 "BVR Cust Rcpt Appr Resp"
{
    // Registers and executes the custom workflow RESPONSES for a Custom Purchase
    // Receipt approval:
    //   * BVRSETCUSTRCPTAPPROVED - mark the receipt approved / status Released.
    //   * BVRPOSTCUSTRCPT        - automatically POST the receipt once approved.
    // Both are added to the approve branch of the workflow template (see WF Setup),
    // so on full approval the receipt is marked approved and then posted.   //AAV.SP

    procedure SetCustomReceiptApprovedCode(): Code[128]
    begin
        exit('BVRSETCUSTRCPTAPPROVED');
    end;

    procedure PostCustomReceiptCode(): Code[128]
    begin
        exit('BVRPOSTCUSTRCPT');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsesToLibrary', '', false, false)]
    local procedure OnAddWorkflowResponsesToLibrary()
    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowResponseHandling.AddResponseToLibrary(
            SetCustomReceiptApprovedCode(),
            Database::"Purchase Header",
            SetCustomReceiptApprovedTxt,
            'GROUP 0');

        WorkflowResponseHandling.AddResponseToLibrary(
            PostCustomReceiptCode(),
            Database::"Purchase Header",
            PostCustomReceiptTxt,
            'GROUP 0');
    end;

    // Declares which event/response each custom response may follow. Without this the
    // engine rejects the response with "... is not supported in the workflow".   //AAV.SP
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsePredecessorsToLibrary', '', false, false)]
    local procedure OnAddWorkflowResponsePredecessorsToLibrary(ResponseFunctionName: Code[128])
    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        if ResponseFunctionName = SetCustomReceiptApprovedCode() then
            WorkflowResponseHandling.AddResponsePredecessor(
                SetCustomReceiptApprovedCode(),
                WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());

        if ResponseFunctionName = PostCustomReceiptCode() then begin
            // Valid after the approve event and after the "mark approved" response.
            WorkflowResponseHandling.AddResponsePredecessor(
                PostCustomReceiptCode(),
                WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
            WorkflowResponseHandling.AddResponsePredecessor(
                PostCustomReceiptCode(),
                SetCustomReceiptApprovedCode());
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnExecuteWorkflowResponse', '', false, false)]
    local procedure OnExecuteWorkflowResponse(var ResponseExecuted: Boolean; var Variant: Variant; xVariant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance")
    var
        PurchaseHeader: Record "Purchase Header";
        PostV2: Codeunit "BVR Custom Rcpt Post V2";
    begin
        if ResponseWorkflowStepInstance."Function Name" = SetCustomReceiptApprovedCode() then begin
            // Claim the response first so the engine never reports "not supported".
            ResponseExecuted := true;
            if GetCustomReceipt(Variant, PurchaseHeader) then begin
                PurchaseHeader."BVR Approved" := true;
                PurchaseHeader."BVR Sent For Approval" := true;
                PurchaseHeader."BVR Receipt Status" := PurchaseHeader."BVR Receipt Status"::Released;
                PurchaseHeader.Modify(true);
            end;
            exit;
        end;

        if ResponseWorkflowStepInstance."Function Name" = PostCustomReceiptCode() then begin
            ResponseExecuted := true;
            if GetCustomReceipt(Variant, PurchaseHeader) then
                // Idempotent. The approve branch only runs on full approval, so post
                // through PostApproved (bypasses the still-open-request guard).   //AAV.SP
                if not PurchaseHeader."BVR Custom Rcpt Posted" then
                    PostV2.PostApproved(PurchaseHeader);
            exit;
        end;
    end;

    // Resolves the workflow variant to a fresh Custom Purchase Receipt record. The
    // variant may be the Purchase Header (send branch) or the Approval Entry pointing
    // at it (approve branch), so handle both.   //AAV.SP
    local procedure GetCustomReceipt(var Variant: Variant; var PurchaseHeader: Record "Purchase Header"): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
        RecRef: RecordRef;
        DocRecRef: RecordRef;
    begin
        // if not Variant.IsRecord() then
        //     exit(false);
        RecRef.GetTable(Variant);

        case RecRef.Number of
            Database::"Purchase Header":
                RecRef.SetTable(PurchaseHeader);
            Database::"Approval Entry":
                begin
                    RecRef.SetTable(ApprovalEntry);
                    if ApprovalEntry."Table ID" <> Database::"Purchase Header" then
                        exit(false);
                    if not DocRecRef.Get(ApprovalEntry."Record ID to Approve") then
                        exit(false);
                    DocRecRef.SetTable(PurchaseHeader);
                end;
            else
                exit(false);
        end;

        if not PurchaseHeader."BVR Receive PO" then
            exit(false);
        // Re-read so we see the flags set by earlier responses in this branch.
        exit(PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    var
        SetCustomReceiptApprovedTxt: Label 'Mark the Custom Purchase Receipt as approved.';
        PostCustomReceiptTxt: Label 'Post the Custom Purchase Receipt.';
}
