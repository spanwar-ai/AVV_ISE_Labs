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
        DimMgt: Codeunit DimensionManagement;
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
        // Lines are clubbed into one entry, so start from the order's header dimensions...
        //
        // Both parts are required. G/L Entry.CopyFromGenJnlLine takes "Global Dimension 1/2 Code"
        // from the journal line's SHORTCUT codes and "Dimension Set ID" from the set - they are
        // copied independently. Assigning only the set ID posts an entry whose dimension set is
        // right but whose Global Dimension 1/2 columns are BLANK, which is what dimension-based
        // analysis and most reports actually read. UpdateGlobalDimFromDimSetID derives the two
        // shortcut codes back out of the set, keeping them consistent.   //AAV.SP
        GenJnlLine."Dimension Set ID" := PurchaseHeader."Dimension Set ID";
        DimMgt.UpdateGlobalDimFromDimSetID(
            GenJnlLine."Dimension Set ID",
            GenJnlLine."Shortcut Dimension 1 Code",
            GenJnlLine."Shortcut Dimension 2 Code");
        // ...then let the warehouse dimensions carried over from the Warehouse Receipt override the
        // two globals. Validate (not assignment) so the Dimension Set ID is rebuilt to match the new
        // codes - it applies a delta, so any NON-global dimensions on the order survive.
        // A blank warehouse dimension means "keep the order's own", not "clear it".   //AAV.SP
        ApplyWarehouseDimensions(PurchaseHeader, GenJnlLine);
        GenJnlLine.Description := AccrualDescription(RcptHdr);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    // The description these accrual entries carry into the G/L.
    //
    // It is the receipt's own "Posting Description", so what the AP team types once on the Warehouse
    // Receipt reaches the posted receipt AND the G/L entries that receipt books, and the two always
    // read the same. The chain is entirely standard: codeunit "BVR Whse Receipt Mgt" puts the typed
    // text on the purchase order, Purch.-Post's TransferFields carries it onto the posted receipt -
    // field 22 on both headers - and it is read back from there here.
    //
    // The receipt number is deliberately NOT repeated in the text. It is already on the entry as its
    // Document No., so the description is free to say what the receipt was FOR. Only when there is no
    // posting description at all does it fall back to naming the receipt, which beats a blank line on
    // an accrual account.
    //
    // Worth knowing: BC defaults "Posting Description" on a purchase order to the vendor name, so a
    // receipt whose Warehouse Receipt was left blank books the vendor name rather than the old
    // "Receipt accrual ..." wording. That is the point - the entry says the same thing the posted
    // receipt says.   //AAV.SP
    procedure AccrualDescription(PurchRcptHeader: Record "Purch. Rcpt. Header"): Text[100]
    begin
        if PurchRcptHeader."Posting Description" <> '' then
            exit(CopyStr(PurchRcptHeader."Posting Description", 1, 100));
        exit(CopyStr(StrSubstNo(AccrualDescTxt, PurchRcptHeader."No."), 1, 100));
    end;

    var
        AccrualDescTxt: Label 'Receipt accrual %1', Comment = '%1 = posted purchase receipt no.';

    // Override the accrual line's two global dimensions with the ones the AP team entered on the
    // Warehouse Receipt (stamped onto the PO header by codeunit "BVR Whse Receipt Mgt"). This is the
    // ONLY place those dimensions are applied - the Purchase Order's own dimensions, its Dimension
    // Set ID and its lines are never modified by the warehouse flow.   //AAV.SP
    local procedure ApplyWarehouseDimensions(var PurchaseHeader: Record "Purchase Header"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        if PurchaseHeader."BVR WH Shortcut Dim 1 Code" <> '' then
            GenJnlLine.Validate("Shortcut Dimension 1 Code", PurchaseHeader."BVR WH Shortcut Dim 1 Code");
        if PurchaseHeader."BVR WH Shortcut Dim 2 Code" <> '' then
            GenJnlLine.Validate("Shortcut Dimension 2 Code", PurchaseHeader."BVR WH Shortcut Dim 2 Code");
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
