codeunit 50140 "BVR Create Custom Invoice"
{
    procedure CreateFromReceipt(var RcptOrder: Record "Purchase Header")
    var
        InvHdr: Record "Purchase Header";
        InvLine: Record "Purchase Line";
        RcptHdr: Record "Purch. Rcpt. Header";
        RcptLine: Record "Purch. Rcpt. Line";
        Setup: Record "Purchases & Payables Setup";
        NoSeries: Codeunit "No. Series";
        NextLineNo: Integer;
        Text001: Label 'Custom Invoice %1 already created for Custom Receipt %2';
    begin
        RcptOrder.TestField("Document Type", RcptOrder."Document Type"::Order);
        RcptOrder.TestField("BVR Receive PO", true);
        RcptOrder.TestField("BVR Custom Rcpt Posted", true);
        RcptOrder.TestField("BVR Posted Rcpt No.");
        if RcptOrder."BVR Custom Invoice No." <> '' then
            Error(Text001, RcptOrder."BVR Custom Invoice No.", RcptOrder."BVR Posted Rcpt No.");
        RcptHdr.Get(RcptOrder."BVR Posted Rcpt No.");
        Setup.Get();
        Setup.TestField("Invoice Nos.");
        InvHdr.Init();
        InvHdr."Document Type" := InvHdr."Document Type"::Invoice;
        InvHdr."No." := NoSeries.GetNextNo(Setup."Invoice Nos.", WorkDate(), true);
        InvHdr.Insert(true);
        InvHdr.Validate("Buy-from Vendor No.", RcptOrder."Buy-from Vendor No.");
        InvHdr."Posting Date" := WorkDate();
        InvHdr."Document Date" := WorkDate();
        InvHdr."Vendor Invoice No." := RcptOrder."Vendor Invoice No.";
        InvHdr."BVR Vendor Accrual Acc No." := RcptOrder."BVR Vendor Accrual Acc No.";
        InvHdr."BVR Expense Accrual Acc No." := RcptOrder."BVR Expense Accrual Acc No.";
        InvHdr.Modify(true);
        rcptOrder."BVR Custom Invoice No." := InvHdr."No.";
        rcptOrder.Modify();
        NextLineNo := 10000;
        RcptLine.SetRange("Document No.", RcptOrder."BVR Posted Rcpt No.");
        if RcptLine.FindSet() then
            repeat
                InvLine.Init();
                InvLine."Document Type" := InvLine."Document Type"::Invoice;
                InvLine."Document No." := InvHdr."No.";
                InvLine."Line No." := NextLineNo;
                NextLineNo += 10000;
                InvLine.Type := RcptLine.Type;
                InvLine.Validate("No.", RcptLine."No.");
                InvLine.Description := RcptLine.Description;
                InvLine.Validate(Quantity, RcptLine.Quantity);
                InvLine.Validate("Direct Unit Cost", RcptLine."BVR Accrued Unit Cost");
                InvLine."BVR From Custom Receipt" := true;
                InvLine."BVR Source Rcpt No." := RcptLine."Document No.";
                InvLine."BVR Source Rcpt Line No." := RcptLine."Line No.";
                InvLine.Insert(true);
            until RcptLine.Next() = 0;
        Page.Run(Page::"BVR Custom Purch Invoice", InvHdr);
    end;
}
