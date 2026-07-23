codeunit 50129 "BVR Whse Receipt Mgt"
{
    // Step 1 of the Warehouse-Receipt approval flow. Subscribers on standard warehouse objects -
    // no base object is overridden:
    //   1. Whse.-Create Source Document -> blank Qty. to Receive on purchase-sourced lines so
    //      the user explicitly enters what to receive.
    //   2. Whse.-Post Receipt (get header) -> block posting until the WR is Released, remember the
    //      WR No. for stamping, and push the WR's accrual accounts AND its two global dimensions onto
    //      the source PO header(s) so the standard receipt-accrual (codeunit "BVR Std Rcpt Accrual")
    //      books the same G/L entry it does for a normal PO receipt, and the dimensions reach the
    //      posted receipt and the G/L entries through standard posting.
    //   3. Whse.-Post Receipt (after posting the purchase header) -> stamp the WR No. onto the
    //      resulting Purchase Receipt.
    //   4. Whse.-Post Receipt (after the whole post) -> delete the ENTIRE Warehouse Receipt once it
    //      has been posted, even on a partial receipt (partial quantity, or only some lines
    //      received), so the remainder is handled by a new, separately-approved WR.
    // The gate/accrual/delete only act on WRs in this flow; standard receipts are untouched.
    // SingleInstance so the WR No. captured at (2) survives to (3) within the same post.   //AAV
    SingleInstance = true;
    Permissions = tabledata "Purch. Rcpt. Header" = rm,
                  tabledata "Purchase Header" = rm,
                  tabledata "Warehouse Receipt Header" = rimd,
                  tabledata "Warehouse Receipt Line" = rimd;

    // 1 - Purchase-sourced warehouse receipt lines start with a blank Qty. to Receive.   //AAV
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Create Source Document", 'OnAfterWhseReceiptLineInsert', '', false, false)]
    local procedure BlankQtyToReceiveOnCreate(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
        if WarehouseReceiptLine."Source Document" <> WarehouseReceiptLine."Source Document"::"Purchase Order" then
            exit;
        if WarehouseReceiptLine."Qty. to Receive" = 0 then
            exit;
        WarehouseReceiptLine.Validate("Qty. to Receive", 0);
        WarehouseReceiptLine.Modify();
    end;

    // 2 - Gate posting to Released, capture the WR No. for the stamp in (3), and push the WR's
    // accrual accounts onto the source PO header(s) before they post.   //AAV
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnCodeOnAfterGetWhseRcptHeader', '', false, false)]
    local procedure GateAndCaptureOnPost(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        // Fresh per post; consumed line-by-line in StampWhseReceiptNoOnReceipt.
        CurrentWhseReceiptNo := WarehouseReceiptHeader."No.";
        if not IsFlowWhseReceipt(WarehouseReceiptHeader) then
            exit;
        // A flow WR can ONLY be posted once Released. This blocks Open (and Sent to AP Team / Pending
        // Approval) receipts - even a brand-new purchase WR that has not been sent to AP yet.   //AAV
        if WarehouseReceiptHeader."BVR Receipt Status" <> WarehouseReceiptHeader."BVR Receipt Status"::Released then
            Error(NotReleasedErr, WarehouseReceiptHeader."No.");
        // Runs before the source documents post, so "BVR Std Rcpt Accrual" (OnAfterPostPurchaseDoc)
        // finds the accrual accounts on the PO header and books the accrual exactly as it does for a
        // normal PO receipt. They also transfer onto the posted receipt header for invoicing.   //AAV
        StampWhseReceiptDataOnSourcePOs(WarehouseReceiptHeader);
    end;

    // A Warehouse Receipt belongs to this approval flow if it already carries the approval flag OR it
    // has any purchase-order source line. Using the source line means a fresh, still-Open purchase WR
    // is gated too - it cannot be posted until it has gone through Send to AP -> approval -> Released.
    //   //AAV
    local procedure IsFlowWhseReceipt(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"): Boolean
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        if WarehouseReceiptHeader."BVR Requires Approval" then
            exit(true);
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        exit(not WarehouseReceiptLine.IsEmpty());
    end;

    // Copy the WR's accrual accounts AND its two global dimensions onto every source Purchase Order
    // header of this receipt. The WR (filled by the AP team) is the source of truth for both in this
    // flow, and pushing them onto the PO before it posts is what makes them reach the posted receipt
    // and the G/L entries through entirely standard posting code.   //AAV
    local procedure StampWhseReceiptDataOnSourcePOs(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        if (WarehouseReceiptHeader."BVR Vendor Accrual Acc No." = '') and
           (WarehouseReceiptHeader."BVR Expense Accrual Acc No." = '') and
           (WarehouseReceiptHeader."BVR Shortcut Dimension 1 Code" = '')
        //          (WarehouseReceiptHeader."BVR Shortcut Dimension 2 Code" = '')
        then
            exit;
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        if WarehouseReceiptLine.FindSet() then
            repeat
                if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, WarehouseReceiptLine."Source No.") then
                    StampAccrualsAndDimensions(WarehouseReceiptHeader, PurchaseHeader);
            until WarehouseReceiptLine.Next() = 0;
    end;

    // Plain assignment throughout - every target is one of OUR fields, so there is nothing to
    // validate and nothing standard to disturb.
    //
    // The warehouse dimensions go into "BVR WH Shortcut Dim 1/2 Code", NOT into the order's own
    // "Shortcut Dimension 1/2 Code". That is deliberate: validating the order's real shortcut
    // dimensions would rebuild its Dimension Set ID and cascade onto every purchase line, changing
    // the dimensions the order itself posts under. The warehouse dimensions are only meant to
    // dimension the ACCRUAL entry, which codeunit "BVR Std Rcpt Accrual" builds from these two
    // fields.   //AAV.SP
    local procedure StampAccrualsAndDimensions(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var PurchaseHeader: Record "Purchase Header")
    begin
        if (PurchaseHeader."BVR Vendor Accrual Acc No." = WarehouseReceiptHeader."BVR Vendor Accrual Acc No.") and
           (PurchaseHeader."BVR Expense Accrual Acc No." = WarehouseReceiptHeader."BVR Expense Accrual Acc No.") and
           (PurchaseHeader."BVR WH Shortcut Dim 1 Code" = WarehouseReceiptHeader."BVR Shortcut Dimension 1 Code")
        //   (PurchaseHeader."BVR WH Shortcut Dim 2 Code" = WarehouseReceiptHeader."BVR Shortcut Dimension 2 Code")
        then
            exit;
        PurchaseHeader."BVR Vendor Accrual Acc No." := WarehouseReceiptHeader."BVR Vendor Accrual Acc No.";
        PurchaseHeader."BVR Expense Accrual Acc No." := WarehouseReceiptHeader."BVR Expense Accrual Acc No.";
        PurchaseHeader."BVR WH Shortcut Dim 1 Code" := WarehouseReceiptHeader."BVR Shortcut Dimension 1 Code";
        PurchaseHeader."BVR WH Shortcut Dim 2 Code" := WarehouseReceiptHeader."BVR Shortcut Dimension 2 Code";
        PurchaseHeader.Modify();
    end;

    // 3 - After each source purchase document is posted, PurchaseHeader."Last Receiving No." is
    // the just-created Purchase Receipt. Stamp the WR No. onto it.   //AAV
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnPostSourceDocumentOnAfterPostPurchaseHeader', '', false, false)]
    local procedure StampWhseReceiptNoOnReceipt(PurchaseHeader: Record "Purchase Header")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        CopyAttachments: Codeunit "BVR Copy Attachments";
    begin
        if CurrentWhseReceiptNo = '' then
            exit;
        if PurchaseHeader."Last Receiving No." = '' then
            exit;
        if not PurchRcptHeader.Get(PurchaseHeader."Last Receiving No.") then
            exit;
        // Copy the WR's attachments onto this posted receipt. Done here (not at OnAfterCode) because
        // this is where the posted receipt is known; for a multi-PO WR it fires once per posted
        // receipt, so each receipt carries the WR's documents. Idempotent on re-entry.   //AAV.SP
        CopyAttachments.CopyWhseReceiptAttachmentsToPosted(CurrentWhseReceiptNo, PurchRcptHeader);
        if PurchRcptHeader."BVR Source Whse Receipt No." = CurrentWhseReceiptNo then
            exit;
        PurchRcptHeader."BVR Source Whse Receipt No." := CurrentWhseReceiptNo;
        PurchRcptHeader.Modify();
    end;

    // 4 - Delete the whole Warehouse Receipt once it has posted, even on a partial receipt. Standard
    // BC only deletes the header when NOTHING is left outstanding; when part of the quantity - or
    // only some of the lines - is received, it keeps the WR (the remaining lines hold the header
    // alive). For this flow the WR is one approved receipt event, so we remove it entirely and the
    // remainder is received on a new, separately-approved WR.
    //
    // Runs on OnAfterCode - once, at the very end, AFTER every source document is posted and put-away
    // documents are created (put-away works off the POSTED receipt, not the WR). This is why we do
    // NOT delete per line/per source document: a WR spanning several POs still has un-posted lines
    // mid-run, and removing them early would break the later POs.   //AAV


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnAfterCode', '', false, false)]
    local procedure DeleteWholeWhseReceiptAfterPost(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        CopyAttachments: Codeunit "BVR Copy Attachments";
    begin
        // Clear the WR's attachment rows - they were copied onto the posted receipt(s) in
        // StampWhseReceiptNoOnReceipt, and Warehouse Receipt Header has no OnDelete that clears them.
        // Done FIRST and keyed off "No." because on a full receipt base BC has already deleted the
        // header by the time this fires, so the Get below would exit before cleanup ran.   //AAV.SP
        CopyAttachments.DeleteWhseReceiptAttachments(WarehouseReceiptHeader."No.");
        // Already gone when everything was received - only act if a partial receipt left it behind.
        if not WhseRcptHeader.Get(WarehouseReceiptHeader."No.") then
            exit;
        // Delete via the base app's own document-delete: DeleteRelatedLines(false) removes the lines
        // WITHOUT running their OnDelete trigger, which would otherwise Get + Modify this header (the
        // record the Warehouse Receipt page still has open) to recalc Document Status and raise the
        // "page is not up-to-date" concurrency error. Delete() (no trigger) then removes the header.
        // This mirrors exactly how base Whse.-Post Receipt deletes a fully received WR.   //AAV
        WhseRcptHeader.DeleteRelatedLines(false);
        WhseRcptHeader.Delete();
    end;

    [EventSubscriber(ObjectType::table, Database::"Warehouse Receipt Line", 'OnBeforeConfirmDelete', '', false, false)]
    local procedure OnBeforeConfirmDelete(var SkipConfirm: Boolean; var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
        if WarehouseReceiptLine."Source Document" = WarehouseReceiptLine."Source Document"::"Purchase Order" then
            SkipConfirm := true;
    end;

    var
        CurrentWhseReceiptNo: Code[20];
        NotReleasedErr: Label 'Warehouse Receipt %1 must be Released before it can be posted. Complete the AP / approval flow first.', Comment = '%1 = Warehouse Receipt No.';
}
