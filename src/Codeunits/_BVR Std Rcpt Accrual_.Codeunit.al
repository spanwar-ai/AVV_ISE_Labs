codeunit 50125 "BVR Std Rcpt Accrual"
{
    // Posts the SAME Expense/Vendor accrual entry as the custom receipt flow
    // (BVR Custom Rcpt Post V2), but triggered by STANDARD purchase receipt
    // posting (Purch.-Post). Accrual accounts are taken from the Purchase Order
    // header (BVR Expense/Vendor Accrual Acc No.). Only Item-type lines accrue
    // (inventory + non-inventory); G/L-account lines are excluded.   //AAV
    Permissions = tabledata "Gen. Journal Line" = rimd;

    // Fires after the whole purchase document has posted; PurchRcpHdrNo is the
    // posted receipt number (blank when this run did not post a receipt).   //AAV
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure PostAccrualOnStandardReceipt(var PurchaseHeader: Record "Purchase Header"; PurchRcpHdrNo: Code[20]; PurchInvHdrNo: Code[20])
    var
        RcptHdr: Record "Purch. Rcpt. Header";
        RcptLine: Record "Purch. Rcpt. Line";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        TotalAccrualAmt: Decimal;
    begin
        // Custom-receipt POs accrue via BVR Custom Rcpt Post V2 - avoid double posting.
        if PurchaseHeader."BVR Receive PO" then exit;
        // Only act when a receipt was actually posted in this run.
        if PurchRcpHdrNo = '' then exit;
        // Skip combined Receive+Invoice: the invoice already hits Payables in the
        // same run, so there is no receive-not-invoiced accrual to book here.   //AAV
        if PurchInvHdrNo <> '' then exit;
        // Both accrual accounts must be defined on the PO header.
        if (PurchaseHeader."BVR Expense Accrual Acc No." = '') or
           (PurchaseHeader."BVR Vendor Accrual Acc No." = '') then
            exit;
        if not RcptHdr.Get(PurchRcpHdrNo) then exit;

        // Sum this receipt's Item lines (inventory + non-inventory) at Direct Unit Cost.
        RcptLine.SetRange("Document No.", PurchRcpHdrNo);
        RcptLine.SetRange(Type, RcptLine.Type::Item);
        RcptLine.SetFilter(Quantity, '<>%1', 0);
        if RcptLine.FindSet() then
            repeat
                TotalAccrualAmt += Round(RcptLine."Direct Unit Cost" * RcptLine.Quantity, 0.01);
            until RcptLine.Next() = 0;

        if TotalAccrualAmt = 0 then exit;

        // Same entry as the custom flow: Dr Expense Accrual / Cr Vendor Accrual.
        Clear(GenJnlLine);
        GenJnlLine.Init();
        GenJnlLine.Validate("Journal Template Name", 'GENERAL');
        GenJnlLine.Validate("Journal Batch Name", 'DEFAULT');
        GenJnlLine.Validate("Posting Date", RcptHdr."Posting Date");
        GenJnlLine.Validate("Document Date", RcptHdr."Document Date");
        GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Invoice);
        GenJnlLine.Validate("Document No.", RcptHdr."No.");
        GenJnlLine.Validate("External Document No.", PurchaseHeader."Vendor Invoice No.");
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", PurchaseHeader."BVR Expense Accrual Acc No.");
        GenJnlLine.Validate(Amount, TotalAccrualAmt);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", PurchaseHeader."BVR Vendor Accrual Acc No.");
        // Lines are clubbed into one entry, so use header dimensions.
        GenJnlLine."Dimension Set ID" := PurchaseHeader."Dimension Set ID";
        GenJnlLine.Description := CopyStr(StrSubstNo('Receipt accrual %1', RcptHdr."No."), 1, MaxStrLen(GenJnlLine.Description));
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", OnBeforeInsertToPurchLine, '', false, false)]
    local procedure OnBeforeInsertToPurchLine(FromPurchLine: Record "Purchase Line"; var ToPurchLine: Record "Purchase Line")
    begin
        // Copy accrual accounts from the PO header to the line, so they are available
        // for the accrual posting in PostAccrualOnStandardReceipt.   //AAV
        ToPurchLine."BVR Expense Accrual Acc No." := FromPurchLine."BVR Expense Accrual Acc No.";
        ToPurchLine."BVR Vendor Accrual Acc No." := FromPurchLine."BVR Vendor Accrual Acc No.";
    end;

    local procedure MyProcedure()
    begin

    end;


}
