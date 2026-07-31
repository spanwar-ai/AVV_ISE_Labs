codeunit 50145 "BVR Purch Doc Mgt"
{
    // Small shared helpers for purchase documents:   //AAV.SP
    //   * numbering Purchase Orders created from a Blanket Purchase Order as <Blanket No.>/<n>,
    //   * the "Order No." drill-down shown on posted purchase receipts.

    var
        NoTooLongErr: Label 'Purchase order %1 cannot be created from blanket order %2 because the resulting number is longer than 20 characters.', Comment = '%1 = proposed order no., %2 = blanket order no.';
        OrderDeletedMsg: Label 'Purchase order %1 no longer exists. Purchase orders are removed automatically once they are fully received and invoiced.', Comment = '%1 = purchase order no.';

    // ---------------------------------------------------------------------------------------------
    // Blanket Purchase Order -> Purchase Order numbering
    //
    // Blanket order PO023655 produces PO023655/1, PO023655/2, ... instead of taking a number from
    // the Order Nos. series. The next sequence is found by probing for the first free number rather
    // than by keeping a counter, so it survives the blanket order being modified elsewhere in the
    // Make Order transaction. "In use" deliberately includes archived orders and posted
    // receipts/invoices, so a number is never handed out twice even after the order itself has been
    // fully invoiced and deleted by BC.
    // ---------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Blanket Purch. Order to Order", 'OnBeforeInsertPurchOrderHeader', '', false, false)]
    local procedure SetOrderNoOnBeforeInsertPurchOrderHeader(var PurchOrderHeader: Record "Purchase Header"; BlanketOrderPurchHeader: Record "Purchase Header")
    begin
        if BlanketOrderPurchHeader."No." = '' then
            exit;

        PurchOrderHeader."No." := NextOrderNo(BlanketOrderPurchHeader."No.");
        // Header-level record of the source blanket order. Flows on to the posted receipt via
        // TransferFields - see the field comment on "Purch. Rcpt. Header".
        PurchOrderHeader."BVR Blanket Order No." := BlanketOrderPurchHeader."No.";
        // Blanked so Purchase Header.InitInsert() does not pull a replacement number from the series
        // and so the order is not reported as belonging to Order Nos.
        PurchOrderHeader."No. Series" := '';
    end;

    local procedure NextOrderNo(BlanketOrderNo: Code[20]) OrderNo: Code[20]
    var
        Seq: Integer;
    begin
        repeat
            Seq += 1;
            OrderNo := BuildOrderNo(BlanketOrderNo, Seq);
        until not OrderNoInUse(OrderNo);
    end;

    local procedure BuildOrderNo(BlanketOrderNo: Code[20]; Seq: Integer) OrderNo: Code[20]
    var
        Candidate: Text;
    begin
        Candidate := StrSubstNo('%1/%2', BlanketOrderNo, Seq);
        if StrLen(Candidate) > MaxStrLen(OrderNo) then
            Error(NoTooLongErr, Candidate, BlanketOrderNo);
        OrderNo := CopyStr(Candidate, 1, MaxStrLen(OrderNo));
    end;

    local procedure OrderNoInUse(OrderNo: Code[20]): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo) then
            exit(true);

        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeaderArchive."Document Type"::Order);
        PurchaseHeaderArchive.SetRange("No.", OrderNo);
        if not PurchaseHeaderArchive.IsEmpty() then
            exit(true);

        PurchRcptHeader.SetRange("Order No.", OrderNo);
        if not PurchRcptHeader.IsEmpty() then
            exit(true);

        PurchInvHeader.SetRange("Order No.", OrderNo);
        exit(not PurchInvHeader.IsEmpty());
    end;

    // ---------------------------------------------------------------------------------------------
    // Drill-down target for "Order No." on posted purchase documents. BC deletes a purchase order
    // once it is fully received and invoiced, so the order is often legitimately gone; in that case
    // we tell the user rather than throwing an error.
    // ---------------------------------------------------------------------------------------------

    procedure ShowPurchaseOrder(OrderNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if OrderNo = '' then
            exit;

        if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo) then begin
            Message(OrderDeletedMsg, OrderNo);
            exit;
        end;

        PurchaseHeader.SetRecFilter();
        Page.Run(Page::"Purchase Order", PurchaseHeader);
    end;
}
