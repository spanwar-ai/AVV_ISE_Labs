codeunit 50131 "BVR Whse Rcpt Appr Events"
{
    // Part 2B - registers the Warehouse Receipt's OWN "send for approval" workflow event. Unlike
    // the custom purchase-receipt flow (which reuses the standard purchase-document events because
    // it is a Purchase Header), a Warehouse Receipt is not a purchase document, so it needs its own
    // event registered against table 7316.
    //
    // Only the SEND event is a workflow event: the workflow creates and routes the request, while
    // Approve / Reject / Delegate / Cancel are performed by the app through the standard
    // record-level Approvals engine (see codeunit "BVR Whse Rcpt Appr Mgt").   //AAV.SP

    procedure RunWorkflowOnSendWhseReceiptForApprovalCode(): Code[128]
    begin
        exit('BVRSENDWHSERCPTAPPR');
    end;

    // The "cancel" workflow event. The base-app record-approval builder
    // (WorkflowSetup.InsertRecApprovalWorkflowSteps) needs a dedicated cancel event to wire the
    // cancel branch - exactly as Customer/Vendor/Item approvals use
    // RunWorkflowOnCancelXApprovalRequestCode.   //AAV.SP
    procedure RunWorkflowOnCancelWhseReceiptApprovalRequestCode(): Code[128]
    begin
        exit('BVRCANCELWHSERCPTAPPR');
    end;

    // Publish our send + cancel events into the Workflow event library so they can be used as the
    // entry / cancel events of a workflow (and of our ready-made template).   //AAV.SP
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Event Handling", 'OnAddWorkflowEventsToLibrary', '', false, false)]
    local procedure OnAddWorkflowEventsToLibrary()
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        WorkflowEventHandling.AddEventToLibrary(
            RunWorkflowOnSendWhseReceiptForApprovalCode(),
            Database::"Warehouse Receipt Header",
            SendForApprovalEventDescTxt, 0, false);
        WorkflowEventHandling.AddEventToLibrary(
            RunWorkflowOnCancelWhseReceiptApprovalRequestCode(),
            Database::"Warehouse Receipt Header",
            CancelForApprovalEventDescTxt, 0, false);
    end;

    // Raised by the approval management codeunit to hand the receipt to the workflow engine.
    [IntegrationEvent(false, false)]
    procedure OnSendWhseReceiptForApproval(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    // Raised by the approval management codeunit to run the workflow's cancel branch.   //AAV.SP
    [IntegrationEvent(false, false)]
    procedure OnCancelWhseReceiptApproval(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    var
        SendForApprovalEventDescTxt: Label 'Approval of a Warehouse Receipt is requested';
        CancelForApprovalEventDescTxt: Label 'A Warehouse Receipt approval request is cancelled';
}
