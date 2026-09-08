codeunit 50127 "BVR Std Get Receipt Lines"
{
    // Invoicing side of the standard-PO accrual flow. Pulls the lines of a STANDARD posted
    // accrual receipt onto a purchase invoice as G/L-Account lines pointing to the receipt's
    // Vendor Accrual account. Standard posting then books Dr Vendor Accrual / Cr Vendor for
    // the invoice amount - clearing the GRNI that "BVR Std Rcpt Accrual" credited at receipt.
    // No custom posting code is needed; only the line redirection + invoiced-qty tracking.  //AAV
    Permissions = tabledata "Purch. Rcpt. Line" = rm,
                  tabledata "Purchase Header" = rm,
                  tabledata "Purchase Line" = rimd;

    // Let the user pick a posted accrual receipt for the invoice's vendor, then pull it.  //AAV
    procedure GetLinesInteractive(var InvHdr: Record "Purchase Header")
    var
        RcptHdr: Record "Purch. Rcpt. Header";
        PostedRcpts: Page "Posted Purchase Receipts";
    begin
        InvHdr.TestField("Document Type", InvHdr."Document Type"::Invoice);
        InvHdr.TestField("Buy-from Vendor No.");
        // Only STANDARD receipts (not custom-receipt) that carry a Vendor Accrual account.
        RcptHdr.SetRange("Buy-from Vendor No.", InvHdr."Buy-from Vendor No.");
        //RcptHdr.SetRange("BVR Custom Receipt", false);
        RcptHdr.SetFilter("BVR Vendor Accrual Acc No.", '<>%1', '');
        PostedRcpts.SetTableView(RcptHdr);
        PostedRcpts.LookupMode(true);
        if PostedRcpts.RunModal() = Action::LookupOK then begin
            PostedRcpts.GetRecord(RcptHdr);
            GetLinesFromReceipt(InvHdr, RcptHdr."No.");
        end;
    end;

    procedure GetLinesFromReceipt(var InvHdr: Record "Purchase Header"; ReceiptNo: Code[20])
    var
        RcptHdr: Record "Purch. Rcpt. Header";
        RcptLine: Record "Purch. Rcpt. Line";
        InvLine: Record "Purchase Line";
        Item: Record Item;
        VendAccrAcc: Code[20];
        ExpAccrAcc: Code[20];
        NextLineNo: Integer;
        RemQty: Decimal;
        IsInventoryItem: Boolean;
    begin
        InvHdr.TestField("Document Type", InvHdr."Document Type"::Invoice);
        RcptHdr.Get(ReceiptNo);
        RcptHdr.TestField("BVR Vendor Accrual Acc No.");
        VendAccrAcc := RcptHdr."BVR Vendor Accrual Acc No.";
        ExpAccrAcc := RcptHdr."BVR Expense Accrual Acc No.";

        // Copy the accrual accounts onto the invoice header (informational; the posting is
        // driven by the line-level accrual accounts populated below).   //AAV
        InvHdr."BVR Vendor Accrual Acc No." := RcptHdr."BVR Vendor Accrual Acc No.";
        InvHdr."BVR Expense Accrual Acc No." := RcptHdr."BVR Expense Accrual Acc No.";
        InvHdr.Modify();

        InvLine.SetRange("Document Type", InvHdr."Document Type");
        InvLine.SetRange("Document No.", InvHdr."No.");
        if InvLine.FindLast() then
            NextLineNo := InvLine."Line No.";

        // Only Item lines were accrued at receipt (BVR Std Rcpt Accrual excludes G/L lines),
        // so only Item lines are reversed here - keeping the invoice scope identical to the
        // receipt accrual scope so Vendor Accrual nets to zero.   //AAV
        RcptLine.SetRange("Document No.", ReceiptNo);
        RcptLine.SetRange(Type, RcptLine.Type::Item);
        RcptLine.SetFilter(Quantity, '<>%1', 0);
        if RcptLine.FindSet() then
            repeat
                RemQty := RcptLine.Quantity - RcptLine."BVR Invoiced Qty";
                if RemQty > 0 then begin
                    NextLineNo += 10000;
                    InvLine.Init();
                    InvLine."Document Type" := InvHdr."Document Type";
                    InvLine."Document No." := InvHdr."No.";
                    InvLine."Line No." := NextLineNo;

                    // A true Inventory item was already received into stock by the standard
                    // receipt; re-pulling it as an Item line would post inventory a second
                    // time and its cost would bypass the account-redirect hook. So keep those
                    // as a G/L line straight to the Vendor Accrual account. Non-inventory
                    // items carry no stock, so they are pulled as the real Item line and the
                    // OnPrepareLineOnBeforeSetAccount subscriber redirects their cost debit to
                    // the Vendor Accrual account.   //AAV
                    IsInventoryItem := false;
                    if Item.Get(RcptLine."No.") then
                        IsInventoryItem := Item.Type = Item.Type::Inventory;

                    if IsInventoryItem then begin
                        InvLine.Validate(Type, InvLine.Type::"G/L Account");
                        InvLine.Validate("No.", VendAccrAcc);
                    end else begin
                        InvLine.Validate(Type, InvLine.Type::Item);
                        InvLine.Validate("No.", RcptLine."No.");
                    end;

                    InvLine.Validate(Quantity, RemQty);
                    InvLine.Description := RcptLine.Description;
                    if RcptLine."Location Code" <> '' then
                        InvLine.Validate("Location Code", RcptLine."Location Code");
                    // Line-level accrual accounts: drive the posting redirect and keep the
                    // accrual detail visible per line.   //AAV
                    InvLine.Validate("Direct Unit Cost", RcptLine."Direct Unit Cost");
                    InvLine."BVR Vendor Accrual Acc No." := VendAccrAcc;
                    InvLine."BVR Expense Accrual Acc No." := ExpAccrAcc;
                    // Link back to the source receipt line so invoiced qty can be tracked.
                    InvLine."BVR Source Rcpt No." := RcptLine."Document No.";
                    InvLine."BVR Source Rcpt Line No." := RcptLine."Line No.";
                    InvLine."Dimension Set ID" := RcptLine."Dimension Set ID";
                    InvLine.Insert(true);
                end;
            until RcptLine.Next() = 0;
    end;

    // Invoice-post redirect: for any line carrying a line-level Vendor Accrual account, post
    // its cost debit to that account instead of the item's normal purchase/expense account.
    // Combined with Cr Vendor from standard posting this books Dr Vendor Accrual / Cr Vendor,
    // clearing the GRNI that "BVR Std Rcpt Accrual" credited at receipt. Only fires for the
    // non-inventory Item lines pulled above (inventory items are already G/L lines to the same
    // account, so the redirect is a no-op for them).   //AAV
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", 'OnPrepareLineOnBeforeSetAccount', '', false, false)]
    local procedure RedirectAccrualLineToVendorAccrualAcc(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var SalesAccount: Code[20])
    begin

        if PurchLine."BVR Vendor Accrual Acc No." <> '' then
            SalesAccount := PurchLine."BVR Vendor Accrual Acc No.";
    end;

    // Track how much of each source receipt line has been invoiced, so re-running Get Receipt
    // Lines never pulls the same quantity twice. Runs inside the posting transaction, so it
    // rolls back with the post on failure.   //AAV
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure UpdateReceiptInvoicedQtyOnInvoicePost(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var IsHandled: Boolean)
    var
        PurchLine: Record "Purchase Line";
        RcptLine: Record "Purch. Rcpt. Line";
    begin
        if PreviewMode then
            exit;
        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice then
            exit;
        PurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchLine.SetFilter("BVR Source Rcpt No.", '<>%1', '');
        if PurchLine.FindSet() then
            repeat
                if PurchLine."BVR Source Rcpt Line No." <> 0 then
                    if RcptLine.Get(PurchLine."BVR Source Rcpt No.", PurchLine."BVR Source Rcpt Line No.") then begin
                        RcptLine."BVR Invoiced Qty" += PurchLine.Quantity;
                        RcptLine.Modify();
                    end;
            until PurchLine.Next() = 0;
    end;
}
