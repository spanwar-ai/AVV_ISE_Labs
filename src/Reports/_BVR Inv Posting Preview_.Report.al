report 50254 "BVR Inv Posting Preview"
{
    Caption = 'Posting Preview - Custom Invoice';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = false; // Set to false + add RDLCLayout when you add your RDLC

    dataset
    {
        dataitem(InvHdr; "Purchase Header")
        {
            DataItemTableView = where("Document Type"=const(Invoice));
            RequestFilterFields = "No.";

            column(InvoiceNo; "No.")
            {
            }
            column(BuyFromVendorNo; "Buy-from Vendor No.")
            {
            }
            column(PayToVendorNo; "Pay-to Vendor No.")
            {
            }
            column(PostingDate; "Posting Date")
            {
            }
            column(DocumentDate; "Document Date")
            {
            }
            column(VendorInvoiceNo; "Vendor Invoice No.")
            {
            }
            column(TaxAreaCode; "Tax Area Code")
            {
            }
            column(TaxLiable; "Tax Liable")
            {
            }
            column(InvoiceBaseAmt; InvoiceBaseAmt)
            {
            }
            column(ReceiptBaseAmt; ReceiptBaseAmt)
            {
            }
            column(DiffBase; DiffBase)
            {
            }
            column(TaxAmt; TaxAmt)
            {
            }
            column(DiscountAmt; DiscountAmt)
            {
            }
            column(TotalInvoiceAmt; TotalInvoiceAmt)
            {
            }
            dataitem(PreviewLine; "BVR Posting Preview Line")
            {
                UseTemporary = true;

                column(LineNo; "Line No.")
                {
                }
                column(EntryType; "Entry Type")
                {
                }
                column(DebitCredit; "Debit/Credit")
                {
                }
                column(IsItemLedger; "Is Item Ledger")
                {
                }
                column(IsSummary; "Is Summary")
                {
                }
                column(AccountDoc; "Account/Doc")
                {
                }
                column(Description; Description)
                {
                }
                column(Quantity; Quantity)
                {
                }
                column(Amount; Amount)
                {
                }
                column(BalAccount; "Bal. Account")
                {
                }
                trigger OnPreDataItem()
                begin
                    // Load temp dataset created in parent dataitem
                    PreviewLine.DeleteAll();
                    if TempPreviewLines.FindSet()then repeat PreviewLine:=TempPreviewLines;
                            PreviewLine.Insert();
                        until TempPreviewLines.Next() = 0;
                end;
            }
            trigger OnAfterGetRecord()
            var
                PrevMgt: Codeunit "BVR Posting Preview Mgt";
            begin
                TempPreviewLines.DeleteAll();
                PrevMgt.BuildPreviewForCustomInvoiceWithTotals(InvHdr, TempPreviewLines, InvoiceBaseAmt, ReceiptBaseAmt, TaxAmt, DiscountAmt, DiffBase, TotalInvoiceAmt);
            end;
        }
    }
    var TempPreviewLines: Record "BVR Posting Preview Line" temporary;
    InvoiceBaseAmt: Decimal;
    ReceiptBaseAmt: Decimal;
    TaxAmt: Decimal;
    DiscountAmt: Decimal;
    DiffBase: Decimal;
    TotalInvoiceAmt: Decimal;
}
