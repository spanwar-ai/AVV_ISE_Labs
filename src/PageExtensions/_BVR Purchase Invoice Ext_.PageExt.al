pageextension 50112 "BVR Purchase Invoice Ext" extends "Purchase Invoice"
{
    // Invoicing side of the standard-PO accrual flow. "Get Receipt Lines (Accrual)" pulls a
    // standard posted accrual receipt onto the invoice as G/L lines posting to the Vendor
    // Accrual account, so standard posting books Dr Vendor Accrual / Cr Vendor.   //AAV
    layout
    {
        // Already on the page, just hidden by Microsoft. What is typed here ends up as the
        // description on the vendor ledger entry and the G/L entries the invoice posts, so AP wants
        // it in front of them while they enter the invoice, not buried behind Show More.   //AAV.SP
        modify("Posting Description")
        {
            Visible = true;
        }
        addlast(General)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")   //AAV.SP
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the batch this invoice belongs to. Choose an existing Invoice batch or create a new one from the lookup. The batch is posted from the Purchase Invoice Batches page.';
            }
            // The purchase order behind this invoice, worked out from the lines rather than stored.
            //
            // Derived, not a field, because there is nothing on the invoice HEADER that points at an
            // order - the link is per line, and a stored copy would go stale the moment a line was
            // added or removed. Reading it on demand cannot disagree with the lines.
            //
            // Drill down to open it. One order opens its card; several open the list filtered to
            // exactly those orders, because an invoice built from more than one receipt can span
            // several - and picking one of them to show would be a guess.   //AAV.SP
            field(BVRPurchOrderNo; BVRPurchOrderNo)   //AAV.SP
            {
                ApplicationArea = All;
                Caption = 'Purchase Order No.';
                Editable = false;
                ToolTip = 'Specifies the purchase order this invoice was built from. Choose the value to open it. Blank means no line on this invoice traces back to an order.';

                trigger OnDrillDown()
                var
                    PurchaseHeader: Record "Purchase Header";
                    OrderNos: List of [Code[20]];
                begin
                    BVRCollectOrderNos(OrderNos);
                    if OrderNos.Count() = 0 then
                        exit;

                    PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
                    if OrderNos.Count() = 1 then begin
                        PurchaseHeader.SetRange("No.", OrderNos.Get(1));
                        if PurchaseHeader.FindFirst() then
                            Page.Run(Page::"Purchase Order", PurchaseHeader)
                        else
                            // Posted and gone, or archived - saying so beats opening an empty card.
                            Message(BVROrderGoneMsg, OrderNos.Get(1));
                        exit;
                    end;

                    PurchaseHeader.SetFilter("No.", BVROrderFilter(OrderNos));
                    Page.Run(Page::"Purchase Order List", PurchaseHeader);
                end;
            }
            field("BVR Vendor Accrual Acc No."; Rec."BVR Vendor Accrual Acc No.")   //AAV
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Vendor Accrual (GRNI) account this invoice reverses. Copied from the source receipt by Get Receipt Lines (Accrual).';
            }
            field("BVR Expense Accrual Acc No."; Rec."BVR Expense Accrual Acc No.")   //AAV
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Expense Accrual account booked at receipt. Copied from the source receipt for reference.';
            }
        }
    }

    actions
    {
        // An invoice that has been put into a batch is posted from the batch, together with the rest
        // of it - so the posting buttons on this page are switched off while a Batch No. is filled
        // in. Clearing the Batch No. brings them back.
        //
        // Preview Posting is deliberately left alone: it posts nothing, and it is the most useful way
        // to check an invoice before its batch goes.   //AAV.SP
        modify(Post)
        {
            Enabled = BVRPostAllowed;
        }
        modify(PostAndPrint)
        {
            Enabled = BVRPostAllowed;
        }
        modify(PostAndNew)
        {
            Enabled = BVRPostAllowed;
        }
        modify(PostBatch)
        {
            Enabled = BVRPostAllowed;
        }
        addlast(processing)
        {
            action("BVR Get Receipt Lines Accrual")                                               //AAV
            {                                                                                    //AAV
                ApplicationArea = All;                                                           //AAV
                Caption = 'Get Receipt Lines (Accrual)';                                         //AAV
                Image = GetLines;                                                                //AAV
                ToolTip = 'Pull the lines of a posted accrual receipt onto this invoice as Vendor Accrual G/L lines. Posting then books Dr Vendor Accrual / Cr Vendor.'; //AAV

                trigger OnAction()                                                               //AAV
                var                                                                              //AAV
                    GetRcpt: Codeunit "BVR Std Get Receipt Lines";                               //AAV
                begin                                                                            //AAV
                    GetRcpt.GetLinesInteractive(Rec);                                            //AAV
                    CurrPage.Update(false);                                                      //AAV
                end;                                                                             //AAV
            }                                                                                    //AAV
        }
        addlast(Category_Process)
        {
            actionref("BVR Get Receipt Lines Accrual_Promoted"; "BVR Get Receipt Lines Accrual") { }   //AAV
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        OrderNos: List of [Code[20]];
    begin
        BVRPostAllowed := Rec."BVR Doc Batch No." = '';   //AAV.SP

        // Recalculated on every record change, so adding or removing a line is reflected as soon as
        // the page refreshes.   //AAV.SP
        BVRCollectOrderNos(OrderNos);
        case OrderNos.Count() of
            0:
                Clear(BVRPurchOrderNo);
            1:
                BVRPurchOrderNo := CopyStr(OrderNos.Get(1), 1, MaxStrLen(BVRPurchOrderNo));
            else
                // Naming one of several would read as "this invoice is for that order", which is not
                // true. The count says plainly that there is more than one behind it.
                BVRPurchOrderNo :=
                    CopyStr(StrSubstNo(BVRSeveralOrdersTxt, OrderNos.Get(1), OrderNos.Count() - 1),
                            1, MaxStrLen(BVRPurchOrderNo));
        end;
    end;

    // Every purchase order the lines of this invoice trace back to, in the order they are met and
    // without repeats.
    //
    // Three routes, because an invoice line can arrive by three different paths and only one of them
    // is standard BC:
    //   * "BVR Source PO No." - the custom receipt flow writes the order straight onto the line,
    //   * "Receipt No."       - standard Get Receipt Lines links the line to a posted receipt, which
    //                           remembers its order,
    //   * "BVR Source Rcpt No." - this app's own receipt link, read the same way.
    // A line typed by hand traces to nothing and is simply passed over.   //AAV.SP
    local procedure BVRCollectOrderNos(var OrderNos: List of [Code[20]])
    var
        PurchLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        OrderNo: Code[20];
    begin
        Clear(OrderNos);
        if Rec."No." = '' then
            exit;

        PurchLine.SetRange("Document Type", Rec."Document Type");
        PurchLine.SetRange("Document No.", Rec."No.");
        if not PurchLine.FindSet() then
            exit;

        repeat
            OrderNo := '';
            if PurchLine."BVR Source PO No." <> '' then
                OrderNo := PurchLine."BVR Source PO No."
            else
                if PurchLine."Receipt No." <> '' then begin
                    if PurchRcptHeader.Get(PurchLine."Receipt No.") then
                        OrderNo := PurchRcptHeader."Order No.";
                end else
                    if PurchLine."BVR Source Rcpt No." <> '' then
                        if PurchRcptHeader.Get(PurchLine."BVR Source Rcpt No.") then
                            OrderNo := PurchRcptHeader."Order No.";

            if (OrderNo <> '') and not OrderNos.Contains(OrderNo) then
                OrderNos.Add(OrderNo);
        until PurchLine.Next() = 0;
    end;

    // A filter of the form 'PO-01|PO-02', so the list shows exactly these orders and nothing else.
    local procedure BVROrderFilter(OrderNos: List of [Code[20]]) Filter: Text
    var
        OrderNo: Code[20];
    begin
        foreach OrderNo in OrderNos do begin
            if Filter <> '' then
                Filter += '|';
            Filter += OrderNo;
        end;
    end;

    var
        BVRPostAllowed: Boolean;   //AAV.SP
        BVRPurchOrderNo: Text[50];   //AAV.SP
        BVRSeveralOrdersTxt: Label '%1 (+%2 more)', Comment = '%1 = first purchase order no., %2 = how many others';
        BVROrderGoneMsg: Label 'Purchase order %1 no longer exists - it has been posted or deleted.', Comment = '%1 = purchase order no.';
}
