codeunit 50133 "BVR Whse Rcpt Appr WF Setup"
{
    // Part 2B - workflow setup for the Warehouse Receipt approval.
    //
    // Builds a COMPLETE approval workflow (send / create / approve / reject / cancel / delegate),
    // structurally identical to the standard Purchase / Sales document approval, using Microsoft's
    // own builder Codeunit "Workflow Setup".InsertDocApprovalWorkflowSteps (see InsertWorkflowSteps
    // below). The Warehouse Receipt's own "send" and "cancel" events (codeunit "BVR Whse Rcpt Appr
    // Events") drive the entry and cancel branches; every other branch uses standard responses.
    //
    // Delivery: the workflow is offered two ways - (1) a workflow TEMPLATE the admin can pick under
    // Workflow Templates -> "New Workflow from Template", and (2) a one-click "Enable Warehouse
    // Receipt Approval" action that creates + enables it directly. Both are self-upgrading: an
    // out-of-date structure left by an earlier version is rebuilt to the full step set.   //AAV.SP

    procedure CategoryCode(): Code[20]
    begin
        exit('BVRWRA');
    end;

    procedure WorkflowCode(): Code[17]
    begin
        exit('BVRWRAAPPR');
    end;

    procedure EnabledWorkflowCode(): Code[20]
    begin
        exit('BVRWHSERCPTAPPR');
    end;

    // One-click setup: create a ready-to-use approval workflow and enable it. Self-upgrading:
    //   - missing            -> create with the full step set + enable.
    //   - exists, outdated   -> rebuild to the full step set + enable (only if no approval is
    //                           in-flight; an active workflow step instance blocks the rebuild, so
    //                           the user is asked to finish/cancel open approvals first).
    //   - exists, current    -> just make sure it is enabled.   //AAV.SP
    procedure CreateAndEnableWorkflow()
    var
        Workflow: Record Workflow;
    begin
        EnsureCategory();
        EnsureTableRelations();
        if Workflow.Get(EnabledWorkflowCode()) then begin
            if not WorkflowHasFullSteps(Workflow) then
                RebuildWorkflowSteps(Workflow);
            if not Workflow.Enabled then begin
                Workflow.Validate(Enabled, true);
                Workflow.Modify(true);
            end;
            Message(AlreadyEnabledMsg, Workflow.Code);
            exit;
        end;
        Workflow.Init();
        Workflow.Code := EnabledWorkflowCode();
        Workflow.Description := WorkflowDescTxt;
        Workflow.Category := CategoryCode();
        Workflow.Insert(true);
        InsertWorkflowSteps(Workflow);
        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
        Message(CreatedEnabledMsg, Workflow.Code);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", 'OnInsertWorkflowTemplates', '', false, false)]
    local procedure OnInsertWorkflowTemplates()
    begin
        EnsureCategory();
        InsertWhseReceiptApprovalWorkflowTemplate();
    end;

    // Register the table relation the workflow engine needs to navigate between the events on the
    // Warehouse Receipt (send/cancel) and the events on the Approval Entry (approve/reject/delegate).
    // Without it, enabling the workflow fails with "You must define a table relation between all
    // records used in events". Registered here alongside the base app's own approval relations so it
    // survives "Restore Default Workflows".   //AAV.SP
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", 'OnAfterInsertApprovalsTableRelations', '', false, false)]
    local procedure OnAfterInsertApprovalsTableRelations()
    begin
        EnsureTableRelations();
    end;

    local procedure EnsureTableRelations()
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // Warehouse Receipt Header -> Approval Entry (via Record ID to Approve), exactly the relation
        // the base app registers for Customer / Vendor / Item / Purchase Header. Idempotent.   //AAV.SP
        WorkflowSetup.InsertTableRelation(
            Database::"Warehouse Receipt Header", 0,
            Database::"Approval Entry", ApprovalEntry.FieldNo("Record ID to Approve"));
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

    local procedure InsertWhseReceiptApprovalWorkflowTemplate()
    var
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        if Workflow.Get(WorkflowSetup.GetWorkflowTemplateCode(WorkflowCode())) then begin
            // Upgrade an out-of-date template in place. A template is never executed, so it has no
            // active step instances - deleting and rebuilding its steps is always safe.   //AAV.SP
            if not WorkflowHasFullSteps(Workflow) then begin
                DeleteWorkflowSteps(Workflow);
                InsertWorkflowSteps(Workflow);
                WorkflowSetup.MarkWorkflowAsTemplate(Workflow);
            end;
            exit;
        end;
        WorkflowSetup.InsertWorkflowTemplate(Workflow, WorkflowCode(), WorkflowDescTxt, CategoryCode());
        InsertWorkflowSteps(Workflow);
        WorkflowSetup.MarkWorkflowAsTemplate(Workflow);
    end;

    // Decide whether the existing workflow is exactly the structure the current InsertWorkflowSteps
    // produces. It must contain the document-builder markers (Release Document response + our cancel
    // event) AND be free of leftovers from earlier versions / manual edits (an old custom "set
    // released" response, or the Purchase/Sales cancel events that can never fire for a Warehouse
    // Receipt). Anything else is treated as outdated/corrupt and rebuilt.   //AAV.SP
    local procedure WorkflowHasFullSteps(var Workflow: Record Workflow): Boolean
    var
        WhseRcptApprEvents: Codeunit "BVR Whse Rcpt Appr Events";
        WhseRcptPostResponse: Codeunit "BVR Whse Rcpt Post Response";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        if not HasStep(Workflow, WorkflowResponseHandling.ReleaseDocumentCode()) then
            exit(false);
        if not HasStep(Workflow, WhseRcptApprEvents.RunWorkflowOnCancelWhseReceiptApprovalRequestCode()) then
            exit(false);
        // Auto-post step - a workflow built before it existed must be rebuilt.   //AAV.SP
        if not HasStep(Workflow, WhseRcptPostResponse.PostWhseReceiptResponseCode()) then
            exit(false);
        // Foreign / obsolete steps -> not our clean structure.
        if HasStep(Workflow, 'BVRSETWHSERCPTRELEASED') then
            exit(false);
        if HasStep(Workflow, WorkflowEventHandling.RunWorkflowOnCancelPurchaseApprovalRequestCode()) then
            exit(false);
        if HasStep(Workflow, WorkflowEventHandling.RunWorkflowOnCancelSalesApprovalRequestCode()) then
            exit(false);
        exit(true);
    end;

    local procedure HasStep(var Workflow: Record Workflow; FunctionName: Code[128]): Boolean
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", FunctionName);
        exit(not WorkflowStep.IsEmpty());
    end;

    // Rebuild an existing (enabled) workflow to the full step set. Guarded against in-flight
    // approvals, which would otherwise fail the step deletion with "active workflow step
    // instances".   //AAV.SP
    local procedure RebuildWorkflowSteps(var Workflow: Record Workflow)
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
    begin
        WorkflowStepInstance.SetRange("Workflow Code", Workflow.Code);
        if not WorkflowStepInstance.IsEmpty() then
            Error(CannotRebuildActiveErr, Workflow.Code);
        if Workflow.Enabled then begin
            Workflow.Validate(Enabled, false);
            Workflow.Modify(true);
        end;
        DeleteWorkflowSteps(Workflow);
        InsertWorkflowSteps(Workflow);
    end;

    local procedure DeleteWorkflowSteps(var Workflow: Record Workflow)
    var
        WorkflowStep: Record "Workflow Step";
    begin
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.DeleteAll(true);
    end;

    // Build the workflow with Microsoft's own DOCUMENT-approval builder (Codeunit "Workflow Setup".
    // InsertDocApprovalWorkflowSteps) - the exact routine the Purchase / Sales document approvals
    // use. This makes the Warehouse Receipt workflow structurally identical to Purchase Order
    // approval:
    //   send  -> restrict usage -> set status pending -> create requests -> send request
    //   approve (all done)     -> allow record usage -> RELEASE DOCUMENT   (-> our status Released)
    //   approve (chain pending)-> send request to next approver (loops back)
    //   reject                 -> reject all requests -> OPEN DOCUMENT      (-> our status Sent to AP)
    //   cancel                 -> cancel all + allow usage -> OPEN DOCUMENT -> message
    //   delegate               -> send request (loops back)
    //
    // ReleaseDocument / OpenDocument would normally raise "unsupported record type" on a custom
    // table, so codeunit "BVR Whse Rcpt Appr Mgt" subscribes to OnReleaseDocument / OnOpenDocument
    // (and OnSetStatusToPendingApproval) to map them onto "BVR Receipt Status" and mark them handled.
    // The Warehouse Receipt's own send / cancel events drive the entry and cancel branches.   //AAV.SP
    local procedure InsertWorkflowSteps(var Workflow: Record Workflow)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowSetup: Codeunit "Workflow Setup";
        WhseRcptApprEvents: Codeunit "BVR Whse Rcpt Appr Events";
        EmptyDateFormula: DateFormula;
    begin
        // Default routing: up the approver chain until someone with a high enough limit approves.
        // Link Target Page = "Warehouse Receipt" so reject/cancel notifications deep-link to the WR.
        // The admin can change Approver Type / Limit Type on the created workflow afterwards.
        WorkflowSetup.InitWorkflowStepArgument(
            WorkflowStepArgument,
            WorkflowStepArgument."Approver Type"::Approver,
            WorkflowStepArgument."Approver Limit Type"::"Approver Chain",
            Page::"Warehouse Receipt", '', EmptyDateFormula, true);

        WorkflowSetup.InsertDocApprovalWorkflowSteps(
            Workflow,
            WhseReceiptCondition(),   // send condition (match-all) - required, must be non-empty
            WhseRcptApprEvents.RunWorkflowOnSendWhseReceiptForApprovalCode(),
            WhseReceiptCondition(),   // cancel condition (match-all)
            WhseRcptApprEvents.RunWorkflowOnCancelWhseReceiptApprovalRequestCode(),
            WorkflowStepArgument,
            true);   // ShowConfirmationMessage

        AppendAutoPostStep(Workflow);
    end;

    // Chain "Post the Warehouse Receipt" onto the Release Document response, i.e. onto the branch the
    // builder creates for "all approvals granted". The receipt is Released by that point, which is
    // what the posting gate requires, and the branch's "no pending approvals" condition means it only
    // fires on the FINAL approval - never part-way through an approver chain.   //AAV.SP
    local procedure AppendAutoPostStep(var Workflow: Record Workflow)
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WhseRcptPostResponse: Codeunit "BVR Whse Rcpt Post Response";
    begin
        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.ReleaseDocumentCode());
        if not WorkflowStep.FindFirst() then
            exit;
        WorkflowSetup.InsertResponseStep(Workflow, WhseRcptPostResponse.PostWhseReceiptResponseCode(), WorkflowStep.ID);
    end;

    // The document builder requires a non-empty event condition on the entry and cancel events
    // (see "Workflow Setup".InsertEventArgument). We supply a match-all condition (no filters),
    // encoded exactly the way the base BuildCustomerTypeConditions / BuildVendorTypeConditions do -
    // SubmitForApproval already controls who/when, so no field filter is needed.   //AAV.SP
    local procedure WhseReceiptCondition(): Text
    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        exit(StrSubstNo(WhseReceiptCondnTxt, WorkflowSetup.Encode(WhseReceiptHeader.GetView(false))));
    end;

    var
        CategoryDescTxt: Label 'Warehouse Receipt Approval';
        WorkflowDescTxt: Label 'Warehouse Receipt Approval Workflow';
        CreatedEnabledMsg: Label 'Warehouse Receipt approval workflow %1 has been created and enabled.', Comment = '%1 = Workflow Code';
        AlreadyEnabledMsg: Label 'Warehouse Receipt approval workflow %1 is already set up and enabled.', Comment = '%1 = Workflow Code';
        CannotRebuildActiveErr: Label 'Warehouse Receipt approval workflow %1 needs to be rebuilt to the latest version, but there are approvals still in progress. Approve, reject or cancel the open Warehouse Receipt approvals first, then run this again.', Comment = '%1 = Workflow Code';
        WhseReceiptCondnTxt: Label '<?xml version="1.0" encoding="utf-8" standalone="yes"?><ReportParameters><DataItems><DataItem name="Warehouse Receipt Header">%1</DataItem></DataItems></ReportParameters>', Locked = true;
}
