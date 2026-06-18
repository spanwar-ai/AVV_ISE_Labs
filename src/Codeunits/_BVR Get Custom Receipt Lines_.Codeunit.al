codeunit 50141 "BVR Get Custom Receipt Lines"
{
    procedure GetLinesInteractive(var InvHdr: Record "Purchase Header")
    var
        RcptHdr: Record "Purch. Rcpt. Header";
    begin
        InvHdr.TestField("Document Type", InvHdr."Document Type"::Invoice);
        InvHdr.TestField("Buy-from Vendor No.");
        RcptHdr.Reset();
        RcptHdr.SetRange("BVR Custom Receipt", true);
        RcptHdr.SetRange("Buy-from Vendor No.", InvHdr."Buy-from Vendor No.");
        if Page.RunModal(Page::"BVR Custom Posted Receipts", RcptHdr) = Action::LookupOK then GetLinesFromReceipt(InvHdr, RcptHdr."No.");
    end;
    procedure GetLinesFromReceipt(var InvHdr: Record "Purchase Header"; ReceiptNo: Code[20])
    var
        RcptLine: Record "Purch. Rcpt. Line";
        InvLine: Record "Purchase Line";
        NextLineNo: Integer;
        RemQty: Decimal;
        RcpHdr: Record "Purch. Rcpt. Header";
    begin
        // Clear existing invoice lines
        InvLine.SetRange("Document Type", InvHdr."Document Type");
        InvLine.SetRange("Document No.", InvHdr."No.");
        if InvLine.FindSet(true)then InvLine.DeleteAll(true);
        NextLineNo:=0;
        RcpHdr.get(ReceiptNo);
        RcptLine.SetRange("Document No.", ReceiptNo);
        RcptLine.SetRange("BVR Custom Receipt", true);
        if RcptLine.FindSet()then InvHdr."BVR Vendor Accrual Acc No.":=RcpHdr."BVR Vendor Accrual Acc No.";
        InvHdr."BVR Expense Accrual Acc No.":=RcpHdr."BVR Expense Accrual Acc No.";
        InvHdr.Modify();
        repeat RemQty:=RcptLine.Quantity - RcptLine."BVR Invoiced Qty";
            if RemQty <= 0 then continue;
            NextLineNo+=10000;
            InvLine.Init();
            InvLine."Document Type":=InvHdr."Document Type";
            InvLine."Document No.":=InvHdr."No.";
            InvLine."Line No.":=NextLineNo;
            if RcptLine.Type = RcptLine.Type::Item then InvLine.Type:=InvLine.Type::Item
            else
                InvLine.Type:=InvLine.Type::"G/L Account";
            InvLine.Validate("No.", RcptLine."No.");
            InvLine.Validate(Quantity, RemQty);
            InvLine.Validate("Direct Unit Cost", RcptLine."BVR Accrued Unit Cost");
            InvLine.Validate("Location Code", RcptLine."Location Code");
            InvLine."BVR From Custom Receipt":=true;
            InvLine."BVR Source Rcpt No.":=RcptLine."Document No.";
            InvLine."BVR Source Rcpt Line No.":=RcptLine."Line No.";
            InvLine."Dimension Set ID":=RcptLine."Dimension Set ID";
            InvLine.Insert(true);
        until RcptLine.Next() = 0;
    end;
}
