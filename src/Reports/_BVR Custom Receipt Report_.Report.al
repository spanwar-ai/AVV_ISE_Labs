report 50280 "BVR Custom Receipt Report"
{
    Caption = 'Custom Purchase Receipt';
    DefaultLayout = RDLC;
    RDLCLayout = 'ReportLayouts/BVRCustomReceipt.rdlc';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(PurchHdr; "Purchase Header")
        {
            DataItemTableView = where("Document Type"=const(Order), "BVR Receive PO"=const(true));
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
            column(PostedRcptNo; "BVR Posted Rcpt No.")
            {
            }
            dataitem(PurchLine; "Purchase Line")
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
                column(LocationCode; "Location Code")
                {
                }
                column(Quantity; Quantity)
                {
                }
                column(QtyToReceive; "Qty. to Receive")
                {
                }
                column(UnitCost; "Direct Unit Cost")
                {
                }
                column(LineAmount; "Line Amount")
                {
                }
            }
        }
    }
}
