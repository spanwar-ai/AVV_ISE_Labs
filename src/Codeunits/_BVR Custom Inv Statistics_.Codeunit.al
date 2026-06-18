codeunit 50143 "BVR Custom Inv Statistics"
{
    procedure Show(var InvHdr: Record "Purchase Header")
    var
        InvLine: Record "Purchase Line";
        RcptLine: Record "Purch. Rcpt. Line";
        TaxSetup: Record "Tax Setup";
        SalesTaxCalc: Codeunit "Sales Tax Calculate";
        StatsPage: Page "BVR Custom Invoice Statistics";
        ReceiptBaseAmt: Decimal;
        InvoiceBaseAmt: Decimal;
        DiffBase: Decimal;
        TaxAmt: Decimal;
        TotalAmt: Decimal;
        LineTax: Decimal;
        TaxGroupCode: Code[20];
        ExchRate: Decimal;
        PurchTaxAcc: Code[20];
    begin
        InvHdr.TestField("Document Type", InvHdr."Document Type"::Invoice);
        InvHdr.TestField("Buy-from Vendor No.");
        ReceiptBaseAmt:=0;
        InvoiceBaseAmt:=0;
        TaxAmt:=0;
        ExchRate:=1;
        TaxSetup.Get();
        PurchTaxAcc:=TaxSetup."Tax Account (Purchases)";
        InvLine.SetRange("Document Type", InvHdr."Document Type");
        InvLine.SetRange("Document No.", InvHdr."No.");
        //InvLine.SetRange("BVR From Custom Receipt", true);
        if InvLine.FindSet()then repeat InvoiceBaseAmt+=Round(InvLine."Direct Unit Cost" * InvLine.Quantity, 0.01);
                if(InvLine."BVR Source Rcpt No." <> '') and (InvLine."BVR Source Rcpt Line No." <> 0)then begin
                    RcptLine.Get(InvLine."BVR Source Rcpt No.", InvLine."BVR Source Rcpt Line No.");
                    ReceiptBaseAmt+=Round(RcptLine."BVR Accrued Unit Cost" * InvLine.Quantity, 0.01);
                end;
                TaxGroupCode:=InvLine."Tax Group Code";
                if(InvHdr."Tax Area Code" <> '') and (TaxGroupCode <> '')then begin
                    LineTax:=SalesTaxCalc.CalculateTax(InvHdr."Tax Area Code", TaxGroupCode, InvHdr."Tax Liable", InvHdr."Posting Date", InvLine."Line Amount", InvLine.Quantity, ExchRate);
                    TaxAmt+=Round(LineTax, 0.01);
                end;
            until InvLine.Next() = 0;
        DiffBase:=Round(InvoiceBaseAmt - ReceiptBaseAmt, 0.01);
        TotalAmt:=Round(InvoiceBaseAmt + TaxAmt, 0.01);
        StatsPage.SetTotals(ReceiptBaseAmt, InvoiceBaseAmt, DiffBase, TaxAmt, TotalAmt, PurchTaxAcc);
        StatsPage.RunModal();
    //Page.RunModal(Page::"BVR Custom Invoice Statistics",InvHdr,StatsPage);
    end;
}
