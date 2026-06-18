report 50260 "BVR Custom Purchase Receipt"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Caption = 'Custom Purchase Receipt (Detailed)';
    DefaultLayout = RDLC;

    //RDLCLayout = 'CustomPurchaseReceipt_50260.rdlc';
    dataset
    {
        dataitem(Company; "Company Information")
        {
            column(CompanyName; Name)
            {
            }
            column(CompanyLogo; Picture)
            {
            }
            trigger OnAfterGetRecord()
            begin
                CalcFields(Picture);
            end;
        }
        dataitem(PurchHdr; "Purchase Header")
        {
            DataItemTableView = where("Document Type"=const(Order), "No."=FILTER(<>''));
            //where("Document Type" = const(Order),
            //"BVR Receive PO" = const(true));
            RequestFilterFields = "No.";

            column(DocumentNo; "No.")
            {
            }
            column(PostingDate; "Posting Date")
            {
            }
            column(Buy_from_Vendor_No_; "Buy-from Vendor No.")
            {
            }
            column(VendorName; "Buy-from Vendor Name")
            {
            }
            column(VendorAddress; "Buy-from Address")
            {
            }
            column(VendorCity; "Buy-from City")
            {
            }
            column(VendorPostCode; "Buy-from Post Code")
            {
            }
            column(VendorGST; "VAT Registration No.")
            {
            }
            // ✅ Temporary dataitem – no report-global Codeunit or temp vars
            dataitem(PreviewLine; "BVR Posting Preview Line")
            {
                UseTemporary = true;

                column(Item_No; "Item No")
                {
                }
                column(Description; "Line Description")
                {
                }
                column(Quantity; "Source PO Quantity")
                {
                }
                column("Cost"; "Source PO Cost")
                {
                }
                column(DebitCredit; "Debit/Credit")
                {
                }
                column(AccountDoc; "Account/Doc")
                {
                }
                column(BalAccount; "Bal. Account")
                {
                }
                column(Amount; Amount)
                {
                }
                column("Cost_Center"; "Source Dimension 1")
                {
                }
                column("BU"; "Source Dimension 1")
                {
                }
                trigger OnPreDataItem()
                var
                    PreviewMgt: Codeunit "BVR Posting Preview Mgt"; // existing 50250
                begin
                    // Build preview lines directly into this temp dataitem
                    Clear(PreviewLine);
                    PreviewLine.DeleteAll();
                    PreviewMgt.BuildPreviewForReceipt(PurchHdr, PreviewLine);
                    if not PreviewLine.FindSet()then begin
                        if PreviewLine.IsEmpty()then CurrReport.Skip();
                    end;
                end;
            }
        }
    }
}
