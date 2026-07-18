codeunit 50128 "BVR Whse Rcpt Non-Inv"
{
    // Lets STANDARD Warehouse Receipts include NON-INVENTORY purchase lines (Non-Inventory and
    // Service items), which BC normally excludes because they are not inventoriable and generate
    // no warehouse entries. Achieved purely with subscribers on the three native gates - no base
    // object is overridden:
    //   1. PO Release        -> force an inbound Warehouse Request so the PO surfaces on a receipt.
    //   2. Get Source Docs   -> mark the non-inventory line eligible so it becomes a receipt line.
    //   3. Whse.-Post Receipt -> skip put-away for the non-inventory line (nothing to put away).
    // Posting the receipt then runs standard Purch.-Post (Receive), which books the receipt and
    // fires "BVR Std Rcpt Accrual" for the accrual - same as any standard receipt.   //AAV
    //
    // Only acts on Purchase Order lines at a location that "Require Receive"; inventory items are
    // untouched (they already flow through warehouse receipts natively).   //AAV

    // Force the inbound warehouse request for non-inventory lines on release, so the PO is
    // available to "Get Source Documents" on a Warehouse Receipt.   //AAV
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Purch. Release", 'OnReleaseOnBeforeCreateWhseRequest', '', false, false)]
    local procedure ForceWhseRequestForNonInvLine(var PurchaseLine: Record "Purchase Line"; var DoCreateWhseRequest: Boolean)
    begin
        if IsNonInvReceivableLine(PurchaseLine) then
            DoCreateWhseRequest := true;
    end;

    // Mark the non-inventory line eligible to become a Warehouse Receipt Line. Without this the
    // native inventoriability check drops it during "Get Source Documents".   //AAV
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purchases Warehouse Mgt.", 'OnBeforeCheckIfPurchLine2ReceiptLine', '', false, false)]
    local procedure IncludeNonInvLineOnReceipt(var PurchaseLine: Record "Purchase Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
        if IsNonInvReceivableLine(PurchaseLine) then begin
            ReturnValue := true;
            IsHandled := true;
        end;
    end;

    // Non-inventory items cannot be put away, so suppress put-away processing for their posted
    // receipt lines (only relevant when the location also requires put-away).   //AAV
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnCreatePostedRcptLineOnBeforePutAwayProcessing', '', false, false)]
    local procedure SkipPutAwayForNonInvLine(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var SkipPutAwayProcessing: Boolean)
    var
        Item: Record Item;
    begin
        // Only purchase-sourced item lines that resolve to a non-inventory item.
        if PostedWhseReceiptLine."Source Document" <> PostedWhseReceiptLine."Source Document"::"Purchase Order" then
            exit;
        if PostedWhseReceiptLine."Item No." = '' then
            exit;
        if not Item.Get(PostedWhseReceiptLine."Item No.") then
            exit;
        if Item.Type <> Item.Type::Inventory then
            SkipPutAwayProcessing := true;
    end;

    // A Purchase Order line for a Non-Inventory / Service item at a Require-Receive location,
    // with something still outstanding to receive.   //AAV
    local procedure IsNonInvReceivableLine(var PurchaseLine: Record "Purchase Line"): Boolean
    var
        Item: Record Item;
        Location: Record Location;
    begin
        if PurchaseLine."Document Type" <> PurchaseLine."Document Type"::Order then
            exit(false);
        if PurchaseLine.Type <> PurchaseLine.Type::Item then
            exit(false);
        if PurchaseLine."No." = '' then
            exit(false);
        if PurchaseLine."Outstanding Quantity" = 0 then
            exit(false);
        if PurchaseLine."Location Code" = '' then
            exit(false);
        if not Location.Get(PurchaseLine."Location Code") then
            exit(false);
        if not Location."Require Receive" then
            exit(false);
        if not Item.Get(PurchaseLine."No.") then
            exit(false);
        // Inventory items already flow through warehouse receipts natively - leave them alone.
        exit(Item.Type <> Item.Type::Inventory);
    end;
}
