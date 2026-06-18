report 50281 "BVR Custom Invoice Report"
{
    Caption = 'Custom Purchase Invoice';
    DefaultLayout = RDLC;
    RDLCLayout = 'ReportLayouts/BVRCustomInvoice.rdlc';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(InvHdr; "Purchase Header")
        {
            DataItemTableView = where("Document Type"=const(Invoice));
            RequestFilterFields = "No.";

            column(No_; "No.")
            {
            }
            column(BuyFromVendorNo; "Buy-from Vendor No.")
            {
            }
            column(BuyFromVendorName; "Buy-from Vendor Name")
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
            dataitem(InvLine; "Purchase Line")
            {
                DataItemLink = "Document Type"=field("Document Type"), "Document No."=field("No.");
                DataItemTableView = where(Type=filter(Item|"G/L Account"));

                column(LineNo; "Line No.")
                {
                }
                column(No; "No.")
                {
                }
                column(Desc; Description)
                {
                }
                column(Quantity; Quantity)
                {
                }
                column(UnitCost; "Direct Unit Cost")
                {
                }
                column(LineAmount; "Line Amount")
                {
                }
                column(SourceRcptNo; "BVR Source Rcpt No.")
                {
                }
            }
        }
    }
}
