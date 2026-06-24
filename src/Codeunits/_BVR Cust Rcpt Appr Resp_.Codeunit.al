codeunit 50243 "BVR Cust Rcpt Appr Resp"
{
    // Registers and executes the custom workflow RESPONSE that marks a Custom
    // Purchase Receipt as approved once the approval chain completes. This lights
    // up the existing "Post Receipt" action (enabled by BVR Approved), keeping the
    // native flow side-by-side with the original boolean flow.

    procedure SetCustomReceiptApprovedCode(): Code[128]
    begin
        exit('BVRSETCUSTRCPTAPPROVED');
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
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnExecuteWorkflowResponse', '', false, false)]
    local procedure OnExecuteWorkflowResponse(var ResponseExecuted: Boolean; var Variant: Variant; xVariant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance")
    var
        PurchaseHeader: Record "Purchase Header";
        RecRef: RecordRef;
    begin
        if ResponseWorkflowStepInstance."Function Name" <> SetCustomReceiptApprovedCode() then
            exit;

        if not Variant.IsRecord() then
            exit;
        RecRef.GetTable(Variant);
        if RecRef.Number <> Database::"Purchase Header" then
            exit;

        RecRef.SetTable(PurchaseHeader);
        if not PurchaseHeader."BVR Receive PO" then
            exit;

        PurchaseHeader."BVR Approved" := true;
        PurchaseHeader."BVR Sent For Approval" := true;
        PurchaseHeader."BVR Receipt Status" := PurchaseHeader."BVR Receipt Status"::Released;   //AAV.SP
        PurchaseHeader.Modify(true);
        ResponseExecuted := true;
    end;

    var
        SetCustomReceiptApprovedTxt: Label 'Mark the Custom Purchase Receipt as approved.';
}
