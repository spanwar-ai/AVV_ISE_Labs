codeunit 50245 "BVR Cust Rcpt Appr WF Setup"
{
    // Workflow setup for the Custom Purchase Receipt approval.
    //
    // 1. Registers a Workflow Category ('BVRCRA') so the workflow can be grouped and
    //    found on the standard Workflow page.
    // 2. Registers a ready-made Workflow TEMPLATE. On the Workflows page the admin
    //    chooses "New Workflow from Template" -> "Custom Purchase Receipt Approval
    //    Workflow" and BC copies every step below into a new, editable workflow.
    //
    // The template is built on the STANDARD purchase-document approval events so the
    // full approve / reject / delegate / cancel branch set and value-based approver
    // limits are all available. It is scoped to custom receipts (vs. ordinary
    // purchase orders) by the entry event condition:
    //     Document Type = Order  AND  BVR Receive PO = Yes
    //
    // Template shape:
    //   When  event   = Approval of a Purchase Document is requested
    //                   (condition: Document Type = Order, BVR Receive PO = Yes)
    //   Then  response = Create approval requests (Approver / Approver Chain => the
    //                    approver hierarchy is walked until someone's approval limit
    //                    covers the receipt amount  -> value-based approval)
    //                  + Set status to Pending Approval
    //                  + Send approval request
    //   On approve     -> "Mark the Custom Purchase Receipt as approved"
    //                     (BVRSETCUSTRCPTAPPROVED)  [our custom response]
    //   On reject      -> Reject all approval requests + Open the document
    //   On delegate    -> (engine reassigns; no extra response)
    //   On cancel      -> Cancel all approval requests + Open the document
    //
    // NOTE: because this reuses the standard "send purchase doc for approval" event,
    // only ONE workflow should be enabled for an order that is a custom receipt.
    // If a generic Purchase Order approval workflow is also enabled, give it a
    // matching "BVR Receive PO = No" condition so the two never both fire.

    procedure CategoryCode(): Code[20]
    begin
        exit('BVRCRA');
    end;

    procedure WorkflowCode(): Code[17]
    begin
        exit('BVRCRAAPPR');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", 'OnInsertWorkflowTemplates', '', false, false)]
    local procedure OnInsertWorkflowTemplates()
    begin
        EnsureCategory();
        InsertCustomReceiptApprovalWorkflowTemplate();
    end;

    local procedure EnsureCategory()
    var
        WorkflowCategory: Record "Workflow Category";
    begin
        if WorkflowCategory.Get(CategoryCode()) then
            exit;
        WorkflowCategory.Init();
        WorkflowCategory.Code := CategoryCode();
        WorkflowCategory.Description := CategoryDescTxt;
        WorkflowCategory.Insert(true);
    end;

    local procedure InsertCustomReceiptApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // Re-creating a template that already exists would duplicate the code key.
        if Workflow.Get(WorkflowSetup.GetWorkflowTemplateCode(WorkflowCode())) then
            exit;

        WorkflowSetup.InsertWorkflowTemplate(Workflow, WorkflowCode(), WorkflowDescTxt, CategoryCode());
        InsertWorkflowSteps(Workflow);
        WorkflowSetup.MarkWorkflowAsTemplate(Workflow);
    end;

    local procedure InsertWorkflowSteps(var Workflow: Record Workflow)
    var
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        CustRcptApprResp: Codeunit "BVR Cust Rcpt Appr Resp";
        EmptyDateFormula: DateFormula;
        SendStepID: Integer;
        CreateApprovalStepID: Integer;
        SendApprovalStepID: Integer;
        ApproveEventStepID: Integer;
        SetApprovedStepID: Integer;   //AAV.SP
        RejectEventStepID: Integer;
        RejectResponseStepID: Integer;
        CancelEventStepID: Integer;
        CancelResponseStepID: Integer;
    begin
        // Entry point: standard "send purchase doc for approval" event, scoped to
        // custom receipts by the event condition.
        SendStepID := WorkflowSetup.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
        WorkflowSetup.InsertEventArgument(SendStepID, BuildCustomReceiptConditions());

        // Create approval requests; value-based approver chain lives on this step.
        CreateApprovalStepID := WorkflowSetup.InsertResponseStep(Workflow, WorkflowResponseHandling.CreateApprovalRequestsCode(), SendStepID);
        WorkflowSetup.InsertApprovalArgument(
            CreateApprovalStepID,
            "Workflow Approver Type"::Approver,
            "Workflow Approver Limit Type"::"Approver Chain",
            '', '', EmptyDateFormula, true);

        // Set status to pending approval, then send the approval request.
        WorkflowSetup.InsertResponseStep(Workflow, WorkflowResponseHandling.SetStatusToPendingApprovalCode(), CreateApprovalStepID);
        SendApprovalStepID := WorkflowSetup.InsertResponseStep(Workflow, WorkflowResponseHandling.SendApprovalRequestForApprovalCode(), CreateApprovalStepID);

        // On approve -> mark the custom receipt approved, then auto-post it.   //AAV.SP
        ApproveEventStepID := WorkflowSetup.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnApproveApprovalRequestCode(), SendApprovalStepID);
        SetApprovedStepID := WorkflowSetup.InsertResponseStep(Workflow, CustRcptApprResp.SetCustomReceiptApprovedCode(), ApproveEventStepID);
        WorkflowSetup.InsertResponseStep(Workflow, CustRcptApprResp.PostCustomReceiptCode(), SetApprovedStepID);

        // On reject -> reject all requests + reopen the document.
        RejectEventStepID := WorkflowSetup.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnRejectApprovalRequestCode(), SendApprovalStepID);
        RejectResponseStepID := WorkflowSetup.InsertResponseStep(Workflow, WorkflowResponseHandling.RejectAllApprovalRequestsCode(), RejectEventStepID);
        WorkflowSetup.InsertResponseStep(Workflow, WorkflowResponseHandling.OpenDocumentCode(), RejectResponseStepID);

        // On delegate -> engine reassigns the request; no extra response needed.
        WorkflowSetup.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnDelegateApprovalRequestCode(), SendApprovalStepID);

        // On cancel -> cancel all requests + reopen the document.
        CancelEventStepID := WorkflowSetup.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnCancelPurchaseApprovalRequestCode(), SendApprovalStepID);
        CancelResponseStepID := WorkflowSetup.InsertResponseStep(Workflow, WorkflowResponseHandling.CancelAllApprovalRequestsCode(), CancelEventStepID);
        WorkflowSetup.InsertResponseStep(Workflow, WorkflowResponseHandling.OpenDocumentCode(), CancelResponseStepID);
    end;

    // Builds the entry-event condition "Document Type = Order, BVR Receive PO = Yes"
    // in the request-page-parameters format that the workflow engine expects.
    local procedure BuildCustomReceiptConditions(): Text
    var
        PurchaseHeader: Record "Purchase Header";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FilterPageBuilder: FilterPageBuilder;
        EntityName: Code[20];
    begin
        EntityName := PurchaseHeaderTxt;
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("BVR Receive PO", true);

        RequestPageParametersHelper.BuildDynamicRequestPage(FilterPageBuilder, EntityName, Database::"Purchase Header");
        RequestPageParametersHelper.SetViewOnDynamicRequestPage(FilterPageBuilder, PurchaseHeader.GetView(false), EntityName, Database::"Purchase Header");
        exit(RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPageBuilder, EntityName, Database::"Purchase Header"));
    end;

    var
        CategoryDescTxt: Label 'Custom Receipt Approval';
        WorkflowDescTxt: Label 'Custom Purchase Receipt Approval Workflow';
        PurchaseHeaderTxt: Label 'Purchase Header', Locked = true;
}
