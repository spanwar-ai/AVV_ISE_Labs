codeunit 50126 "BVR Std PO Appr Mgt"
{
    // Thin helper for the STANDARD purchase order accrual flow. BC's standard Status and
    // standard approval process drive everything; this only adds the "Send to AP Team"
    // notification step and clears the marker on Reopen. The accrual G/L entry is booked
    // by "BVR Std Rcpt Accrual" when the receipt posts.   //AAV
    Permissions = tabledata "Purchase Header" = rm;

    // Step 2 - notify the AP team to update the accrual accounts. Marks the PO so the
    // standard Send Approval Request can then be raised (by an AP-team user).   //AAV
    procedure SendToAPTeam(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
        PurchaseHeader."BVR Sent To AP Team" := true;
        PurchaseHeader.Modify(true);
        // The marker must stand even if the mail fails; warn the user to notify AP manually.
        if not TryNotifyAPTeam(PurchaseHeader) then
            Message(NotificationFailedMsg, PurchaseHeader."No.", GetLastErrorText());
    end;

    // Step 4 - reopening the PO (manual Reopen, or a rejected/cancelled approval, both of
    // which reopen the document) clears the marker, so it must be sent to the AP team again
    // for verification before it can go back for approval.   //AAV
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterReopenPurchaseDoc', '', false, false)]
    local procedure ResetSentToAPOnReopen(var PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader."BVR Sent To AP Team" then begin
            PurchaseHeader."BVR Sent To AP Team" := false;
            PurchaseHeader.Modify(true);
        end;
    end;

    // Email the AP team. Try function: any failure is returned to the caller instead of
    // aborting the Send to AP Team step.   //AAV
    [TryFunction]
    local procedure TryNotifyAPTeam(var PurchaseHeader: Record "Purchase Header")
    var
        EmailMessage: Codeunit "Email Message";
        Email: Codeunit "Email";
        Recipients: List of [Text];
    begin
        GetAPRecipients(Recipients);
        EmailMessage.Create(
            Recipients,
            StrSubstNo(APMailSubjectTxt, PurchaseHeader."No."),
            StrSubstNo(APMailBodyTxt, PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor Name"),
            false);
        Email.Enqueue(EmailMessage);
    end;

    local procedure GetAPRecipients(var Recipients: List of [Text])
    var
        PurchSetup: Record "Purchases & Payables Setup";
        Address: Text;
    begin
        PurchSetup.Get();
        PurchSetup.TestField("BVR AP Team Email");
        foreach Address in PurchSetup."BVR AP Team Email".Split(';') do
            if Address.Trim() <> '' then
                Recipients.Add(Address.Trim());
    end;

    var
        APMailSubjectTxt: Label 'Purchase Order %1 awaiting AP accrual update', Comment = '%1 = Purchase Order No.';
        APMailBodyTxt: Label 'Purchase Order %1 (Vendor %2 - %3) has been sent to the AP team. Please update the Vendor and Expense accrual accounts, then send it for approval.', Comment = '%1 = PO No., %2 = Vendor No., %3 = Vendor Name';
        NotificationFailedMsg: Label 'Purchase Order %1 was sent to the AP team, but the email notification could NOT be sent. Please inform the AP team manually.\\Details: %2', Comment = '%1 = PO No., %2 = error details';
}
