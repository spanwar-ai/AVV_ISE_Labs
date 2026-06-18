codeunit 50242 "BVR Cust Rcpt Appr Events"
{
    // The Custom Purchase Receipt approval REUSES the standard purchase-document
    // workflow events instead of registering its own. That way the standard
    // approve / reject / delegate / cancel branches and the value-based approver
    // limits are all available in the Workflow editor, and the standard Approvals
    // Mgmt. engine handles the requests unchanged.
    //
    // The flow is scoped to custom receipts (vs. ordinary purchase orders) by a
    // "Document Type = Order, BVR Receive PO = Yes" event condition baked into the
    // template — see codeunit "BVR Cust Rcpt Appr WF Setup".
    //
    // These wrapper functions keep a single, named entry point for the rest of the
    // app (page actions, mgt glue) so the underlying event codes are not hardcoded.

    procedure RunWorkflowOnSendCustomReceiptForApprovalCode(): Code[128]
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        exit(WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
    end;

    procedure RunWorkflowOnCancelCustomReceiptApprovalRequestCode(): Code[128]
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        exit(WorkflowEventHandling.RunWorkflowOnCancelPurchaseApprovalRequestCode());
    end;

    // ---------------------------------------------------------------------
    // Integration events fired by the page / approval management codeunit
    // ---------------------------------------------------------------------
    [IntegrationEvent(false, false)]
    procedure OnSendCustomReceiptForApproval(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelCustomReceiptApprovalRequest(var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}
