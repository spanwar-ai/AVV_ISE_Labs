page 50158 "BVR Inv Batch Subform"
{
    // The "lines" of an invoice batch: every open Purchase Invoice carrying this batch no. Rows are
    // multi-selectable, and the parent page posts whatever is selected.   //AAV.SP
    PageType = ListPart;
    SourceTable = "Purchase Header";
    SourceTableView = where("Document Type" = const(Invoice));
    Caption = 'Purchase Invoices';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Gen)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the purchase invoice number.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the invoice is Open or Released.';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor the invoice is from.';
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the vendor the invoice is from.';
                }
                field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s own invoice number.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the invoice.';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount of the invoice including VAT.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency of the invoice.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Open Purch Invoice")
            {
                ApplicationArea = All;
                Caption = 'Open Purchase Invoice';
                Image = Document;
                RunObject = page "Purchase Invoice";
                RunPageLink = "Document Type" = field("Document Type"), "No." = field("No.");
                ToolTip = 'Open the selected purchase invoice to review it before posting.';
            }
        }
    }

    procedure PostSelectedInvoices()
    var
        PurchaseHeader: Record "Purchase Header";
        BatchPost: Codeunit "BVR Purch Inv Batch Post";
    begin
        CurrPage.SetSelectionFilter(PurchaseHeader);
        BatchPost.PostInvoices(PurchaseHeader);
    end;

    procedure PostAllInvoices()
    var
        PurchaseHeader: Record "Purchase Header";
        BatchPost: Codeunit "BVR Purch Inv Batch Post";
    begin
        PurchaseHeader.CopyFilters(Rec);
        BatchPost.PostInvoices(PurchaseHeader);
    end;
}
