codeunit 50134 "BVR Whse Rcpt Post Response"
{
    // Custom WORKFLOW RESPONSE: "Post the Warehouse Receipt".
    //
    // Registered in the standard workflow response library, so it can be used as a step in any
    // Warehouse Receipt workflow. The Warehouse Receipt approval workflow (codeunit "BVR Whse Rcpt
    // Appr WF Setup") chains it directly AFTER the Release Document response in the "all approvals
    // granted" branch, so the flow is:
    //
    //   approve (last approver) -> allow record usage -> release document (status = Released)
    //                           -> POST THE WAREHOUSE RECEIPT   <- this codeunit
    //
    // Because it runs after Release Document, the receipt is already Released, which is what the
    // posting gate in codeunit "BVR Whse Receipt Mgt" requires. It only fires on the FINAL approval
    // (that branch carries the "no pending approvals" condition), never mid-chain.   //AAV.SP

    procedure PostWhseReceiptResponseCode(): Code[128]
    begin
        exit('BVRPOSTWHSERCPT');
    end;

    // Publish the response into the standard library so it is selectable in the workflow editor.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsesToLibrary', '', false, false)]
    local procedure OnAddWorkflowResponsesToLibrary()
    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowResponseHandling.AddResponseToLibrary(
            PostWhseReceiptResponseCode(),
            Database::"Warehouse Receipt Header",
            PostResponseDescTxt,
            'GROUP 0');
    end;

    // Allow the response to follow an approval being granted (so the editor accepts the step).
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsePredecessorsToLibrary', '', false, false)]
    local procedure OnAddWorkflowResponsePredecessorsToLibrary(ResponseFunctionName: Code[128])
    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        if ResponseFunctionName <> PostWhseReceiptResponseCode() then
            exit;
        WorkflowResponseHandling.AddResponsePredecessor(
            PostWhseReceiptResponseCode(),
            WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode());
    end;

    // Execute the response.   //AAV.SP
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnExecuteWorkflowResponse', '', false, false)]
    local procedure OnExecuteWorkflowResponse(var ResponseExecuted: Boolean; var Variant: Variant; xVariant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance")
    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        if ResponseExecuted then
            exit;
        if ResponseWorkflowStepInstance."Function Name" <> PostWhseReceiptResponseCode() then
            exit;
        if not TryGetWhseReceipt(Variant, WhseReceiptHeader) then
            exit;
        PostWhseReceipt(WhseReceiptHeader);
        ResponseExecuted := true;
    end;

    // The workflow hands the response either the Warehouse Receipt itself or the Approval Entry that
    // was just approved - resolve both to the receipt, exactly as the standard responses do.  //AAV.SP
    local procedure TryGetWhseReceipt(var Variant: Variant; var WhseReceiptHeader: Record "Warehouse Receipt Header"): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
        RecRef: RecordRef;
        TargetRecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        if RecRef.Number = Database::"Approval Entry" then begin
            RecRef.SetTable(ApprovalEntry);
            if not TargetRecRef.Get(ApprovalEntry."Record ID to Approve") then
                exit(false);
            RecRef := TargetRecRef;
        end;
        if RecRef.Number <> Database::"Warehouse Receipt Header" then
            exit(false);
        RecRef.SetTable(WhseReceiptHeader);
        exit(WhseReceiptHeader.Get(WhseReceiptHeader."No."));
    end;

    // Post through the standard "Whse.-Post Receipt" codeunit (not the Yes/No variant), so no
    // confirmation dialog is shown to the approver. Nothing to receive -> nothing to post.  //AAV.SP
    local procedure PostWhseReceipt(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
    begin
        WhseReceiptLine.SetRange("No.", WhseReceiptHeader."No.");
        WhseReceiptLine.SetFilter("Qty. to Receive", '<>%1', 0);
        if not WhseReceiptLine.FindFirst() then
            exit;
        WhsePostReceipt.SetHideValidationDialog(true);
        WhsePostReceipt.Run(WhseReceiptLine);
    end;

    var
        PostResponseDescTxt: Label 'Post the Warehouse Receipt';
}
