page 50162 "BVR Sales Order Batch Subform"
{
    // The "lines" of a sales order batch: the RELEASED orders carrying this batch no. Rows are
    // multi-selectable, and the parent page posts whatever is selected.
    //
    // Released only, because this is a posting screen - an order still being worked on cannot be
    // posted. The "No. of Sales Orders" count on the header still counts every order in the batch, so
    // a count higher than the number of lines is the sign that some are not released yet.   //AAV.SP
    PageType = ListPart;
    SourceTable = "Sales Header";
    Caption = 'Sales Orders';
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
                    ToolTip = 'Specifies the sales order number.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer the order is for.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the customer the order is for.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer''s own order number.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the order.';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount of the order including VAT. These are the figures the batch total adds up.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency of the order.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Open Sales Order")
            {
                ApplicationArea = All;
                Caption = 'Open Sales Order';
                Image = Document;
                RunObject = page "Sales Order";
                RunPageLink = "Document Type" = field("Document Type"), "No." = field("No.");
                ToolTip = 'Open the selected sales order to review it before posting.';
            }
        }
    }

    // Filter group 2, not SourceTableView. As SourceTableView these showed in the filter pane as
    // removable chips, and clearing them would list documents this screen cannot post - unreleased
    // ones, or the wrong document type entirely. Group 2 filters are not shown and cannot be cleared.
    //   //AAV.SP
    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Document Type", Rec."Document Type"::Order);
        Rec.SetRange(Status, Rec.Status::Released);
        Rec.FilterGroup(0);
    end;

    procedure PostSelectedDocuments()
    var
        SalesHeader: Record "Sales Header";
        BatchPost: Codeunit "BVR Sales Batch Post";
    begin
        CurrPage.SetSelectionFilter(SalesHeader);
        BatchPost.PostDocuments(SalesHeader);
    end;

    // Takes the batch code from the parent rather than copying the page's filters. "Post the whole
    // batch" has to mean exactly the rows on screen, and the filters that define them now live in
    // filter group 2 - restating them here removes any dependence on which groups CopyFilters carries.
    //   //AAV.SP
    procedure PostAllDocuments(BatchCode: Code[20])
    var
        SalesHeader: Record "Sales Header";
        BatchPost: Codeunit "BVR Sales Batch Post";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("BVR Doc Batch No.", BatchCode);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        BatchPost.PostDocuments(SalesHeader);
    end;
}
