page 50110 "BVR Custom Invoice Statistics"
{
    PageType = Card;
    SourceTable = Integer;
    Caption = 'Custom Invoice Statistics';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(content)
        {
            group("Base Amounts")
            {
                field("Receipt Base Amount"; ReceiptBaseAmt)
                {
                    ApplicationArea = All;
                }
                field("Invoice Base Amount"; InvoiceBaseAmt)
                {
                    ApplicationArea = All;
                }
                field("Base Difference"; DiffBase)
                {
                    ApplicationArea = All;
                    StyleExpr = DiffStyle;
                }
            }
            group("Tax")
            {
                field("Tax Amount"; TaxAmt)
                {
                    ApplicationArea = All;
                }
                field("Tax Account (Purchases)"; PurchTaxAcc)
                {
                    ApplicationArea = All;
                }
            }
            group("Totals")
            {
                field("Invoice Total"; TotalAmt)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
        }
    }
    var ReceiptBaseAmt: Decimal;
    InvoiceBaseAmt: Decimal;
    DiffBase: Decimal;
    TaxAmt: Decimal;
    TotalAmt: Decimal;
    PurchTaxAcc: Code[20];
    DiffStyle: Text;
    procedure SetTotals(NewReceiptBase: Decimal; NewInvoiceBase: Decimal; NewDiffBase: Decimal; NewTax: Decimal; NewTotal: Decimal; NewPurchTaxAcc: Code[20])
    begin
        ReceiptBaseAmt:=NewReceiptBase;
        InvoiceBaseAmt:=NewInvoiceBase;
        DiffBase:=NewDiffBase;
        TaxAmt:=NewTax;
        TotalAmt:=NewTotal;
        PurchTaxAcc:=NewPurchTaxAcc;
        if DiffBase = 0 then DiffStyle:='Standard'
        else
            DiffStyle:='Attention';
    end;
}
