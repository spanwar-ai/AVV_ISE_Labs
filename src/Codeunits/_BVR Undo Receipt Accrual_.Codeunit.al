codeunit 50124 "BVR Undo Receipt Accrual"
{
    // Full undo for a CUSTOM purchase receipt line. The standard Undo Receipt cannot
    // be used because our posting creates inventory through the item journal (the
    // entries are born fully invoiced), so we reverse everything ourselves:
    //   1. inventory  - a negative item entry applied to the original ledger entry,
    //   2. accrual    - a reversing G/L entry (Expense Accrual <-> Vendor Accrual),
    //   3. source PO  - give the received / outstanding quantity back,
    //   4. order      - re-open the matching custom order line, and once the whole
    //                   receipt is undone, clear the posted flags and set the status
    //                   back to Released so it can be received again.
    // Driven by the "Undo Custom Receipt" action on the posted-receipt subform.   //AAV.SP
    Permissions = tabledata "Purchase Line" = rimd,
                  tabledata "Purch. Rcpt. Line" = rimd,
                  tabledata "Purch. Rcpt. Header" = r,
                  tabledata "Purchase Header" = rimd,
                  tabledata "Item Journal Line" = rimd,
                  tabledata "Item Ledger Entry" = r,
                  tabledata "Gen. Journal Line" = rimd;

    // Entry point used by the page action. Safe to call per line (partial undo).
    procedure UndoCustomReceiptLine(var RcptLine: Record "Purch. Rcpt. Line")
    var
        RcptHdr: Record "Purch. Rcpt. Header";
    begin
        if not RcptLine."BVR Custom Receipt" then
            exit;
        if RcptLine."BVR Accrual Reversed" then
            exit;
        if RcptLine.Correction then
            exit;
        if not RcptHdr.Get(RcptLine."Document No.") then
            exit;
        if not RcptHdr."BVR Custom Receipt" then
            exit;

        ReverseInventory(RcptHdr, RcptLine);
        ReverseAccrualEntry(RcptHdr, RcptLine);
        RestoreSourcePO(RcptLine);
        RestoreCustomOrderLine(RcptHdr, RcptLine);

        RcptLine."BVR Accrual Reversed" := true;
        RcptLine.Modify(true);

        if AllLinesReversed(RcptHdr."No.") then
            ResetCustomOrderHeader(RcptHdr);
    end;

    // 1. Reverse the inventory by applying a negative item entry to the original one.
    //    Non-inventory items have no ledger entry, so there is simply nothing to do.   //AAV.SP
    local procedure ReverseInventory(var RcptHdr: Record "Purch. Rcpt. Header"; var RcptLine: Record "Purch. Rcpt. Line")
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if RcptLine.Type <> RcptLine.Type::Item then
            exit;

        // The original entry was tagged with the receipt's document keys at post time.
        ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Purchase);
        ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Purchase Receipt");
        ItemLedgEntry.SetRange("Document No.", RcptLine."Document No.");
        ItemLedgEntry.SetRange("Document Line No.", RcptLine."Line No.");
        if not ItemLedgEntry.FindFirst() then
            exit;

        Clear(ItemJnlLine);
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Journal Template Name", 'ITEM');
        ItemJnlLine.Validate("Journal Batch Name", 'DEFAULT');
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Purchase);
        ItemJnlLine.Validate("Document No.", RcptHdr."No.");
        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Purchase Receipt";
        ItemJnlLine."Document Line No." := RcptLine."Line No.";
        ItemJnlLine.Validate("Posting Date", RcptHdr."Posting Date");
        ItemJnlLine.Validate("Item No.", RcptLine."No.");
        ItemJnlLine.Validate("Location Code", RcptLine."Location Code");
        ItemJnlLine.Validate(Quantity, -RcptLine.Quantity);
        ItemJnlLine.Validate("Unit Amount", 0);
        ItemJnlLine."Dimension Set ID" := RcptLine."Dimension Set ID";
        ItemJnlLine.Validate("Applies-to Entry", ItemLedgEntry."Entry No.");
        ItemJnlLine.Validate("Source Type", ItemJnlLine."Source Type"::Vendor);
        ItemJnlLine.Validate("Source No.", RcptHdr."Buy-from Vendor No.");
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    // 2. Post the reversing accrual entry for this line's accrued amount, on the same
    //    (header) dimension set the original clubbed accrual used.   //AAV.SP
    local procedure ReverseAccrualEntry(var RcptHdr: Record "Purch. Rcpt. Header"; var RcptLine: Record "Purch. Rcpt. Line")
    var
        StdRcptAccrual: Codeunit "BVR Std Rcpt Accrual";
    begin
        if RcptLine."BVR Accrued Amount" = 0 then
            exit;
        RcptHdr.TestField("BVR Expense Accrual Acc No.");
        RcptHdr.TestField("BVR Vendor Accrual Acc No.");

        // Built by the SAME routine that posted the accrual, with the sign flipped. That is the whole
        // point of it being shared: the reversal has to mirror the accrual entry for entry, including
        // which dimensions each SIDE carries. G/L Entry reads its Global Dimension 1/2 columns from
        // the journal line's shortcut codes, so a reversal that differs by dimension nets to zero in
        // total while leaving permanent phantom balances on the accrual accounts by dimension.
        //
        // Every dimension it needs is on the posted receipt already: Purch.-Post's TransferFields
        // carries them from the order under matching field numbers - 50108/50109 for the expense side,
        // 50111/50112 for the vendor side.   //AAV.SP
        StdRcptAccrual.PostAccrualPair(
            RcptHdr,
            RcptHdr."Posting Date",
            '',
            RcptHdr."BVR Expense Accrual Acc No.",
            RcptHdr."BVR Vendor Accrual Acc No.",
            -RcptLine."BVR Accrued Amount",
            RcptHdr."BVR WH Shortcut Dim 1 Code",
            RcptHdr."BVR WH Shortcut Dim 2 Code",
            RcptHdr."BVR Vendor Accrual Dim 1 Code",
            RcptHdr."BVR Vendor Accrual Dim 2 Code");
    end;

    // 3. Give the received quantity back to the source PO line.   //AAV.SP
    local procedure RestoreSourcePO(var RcptLine: Record "Purch. Rcpt. Line")
    var
        SrcLine: Record "Purchase Line";
    begin
        if (RcptLine."BVR Source PO No." = '') or (RcptLine."BVR Source PO Line No." = 0) then
            exit;
        if not SrcLine.Get(SrcLine."Document Type"::Order, RcptLine."BVR Source PO No.", RcptLine."BVR Source PO Line No.") then
            exit;
        SrcLine."Quantity Received" := SrcLine."Quantity Received" - RcptLine.Quantity;
        if SrcLine."Quantity Received" < 0 then
            SrcLine."Quantity Received" := 0;
        SrcLine."Outstanding Quantity" := SrcLine.Quantity - SrcLine."Quantity Received";
        SrcLine.Modify(true);
    end;

    // 3b. Re-open the matching custom-receipt order line so it can be received again.   //AAV.SP
    local procedure RestoreCustomOrderLine(var RcptHdr: Record "Purch. Rcpt. Header"; var RcptLine: Record "Purch. Rcpt. Line")
    var
        PurchLine: Record "Purchase Line";
    begin
        if RcptHdr."Order No." = '' then
            exit;
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", RcptHdr."Order No.");
        PurchLine.SetRange("BVR Source PO No.", RcptLine."BVR Source PO No.");
        PurchLine.SetRange("BVR Source PO Line No.", RcptLine."BVR Source PO Line No.");
        if not PurchLine.FindFirst() then
            exit;
        PurchLine."Quantity Received" := PurchLine."Quantity Received" - RcptLine.Quantity;
        if PurchLine."Quantity Received" < 0 then
            PurchLine."Quantity Received" := 0;
        PurchLine."Qty. to Receive" := PurchLine."Qty. to Receive" + RcptLine.Quantity;
        PurchLine."BVR Remaining Qty" := PurchLine."BVR Remaining Qty" + RcptLine.Quantity;
        PurchLine.Modify(true);
    end;

    // 4. Clear posted flags / reset status once every line of the receipt is reversed.   //AAV.SP
    local procedure ResetCustomOrderHeader(var RcptHdr: Record "Purch. Rcpt. Header")
    var
        PurchHdr: Record "Purchase Header";
    begin
        if RcptHdr."Order No." = '' then
            exit;
        if not PurchHdr.Get(PurchHdr."Document Type"::Order, RcptHdr."Order No.") then
            exit;
        if not PurchHdr."BVR Receive PO" then
            exit;
        if PurchHdr."BVR Posted Rcpt No." <> RcptHdr."No." then
            exit;

        PurchHdr."BVR Custom Rcpt Posted" := false;
        PurchHdr."BVR Posted Rcpt No." := '';
        PurchHdr."BVR Receipt Status" := PurchHdr."BVR Receipt Status"::Released;
        PurchHdr.Modify(true);
    end;

    local procedure AllLinesReversed(ReceiptNo: Code[20]): Boolean
    var
        RcptLine: Record "Purch. Rcpt. Line";
    begin
        RcptLine.SetRange("Document No.", ReceiptNo);
        RcptLine.SetRange("BVR Custom Receipt", true);
        RcptLine.SetRange(Correction, false);
        RcptLine.SetFilter(Quantity, '>0');
        RcptLine.SetRange("BVR Accrual Reversed", false);
        exit(RcptLine.IsEmpty());
    end;
}
