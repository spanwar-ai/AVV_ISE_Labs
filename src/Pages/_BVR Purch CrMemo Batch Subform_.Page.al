page 50159 "BVR Purch CrMemo Batch Subform"
{
    // The "lines" of a purchase credit memo batch: the RELEASED credit memos carrying this batch no.
    // Rows are multi-selectable, and the parent page posts whatever is selected.
    //
    // Released only, because this is a posting screen - a credit memo still being worked on cannot be
    // posted. The "No. of Purchase Credit Memos" count on the header still counts every one in the
    // batch, so a count higher than the number of lines is the sign that some are not released yet.
    //   //AAV.SP
    PageType = ListPart;
    SourceTable = "Purchase Header";
    Caption = 'Purchase Credit Memos';
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
                    ToolTip = 'Specifies the purchase credit memo number.';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor the credit memo is for.';
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the vendor the credit memo is for.';
                }
                field("Vendor Cr. Memo No."; Rec."Vendor Cr. Memo No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s own credit memo number.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the credit memo.';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total amount of the credit memo including VAT. These are the figures the batch total adds up.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency of the credit memo.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Open Purch Cr Memo")
            {
                ApplicationArea = All;
                Caption = 'Open Purchase Credit Memo';
                Image = Document;
                RunObject = page "Purchase Credit Memo";
                RunPageLink = "Document Type" = field("Document Type"), "No." = field("No.");
                ToolTip = 'Open the selected purchase credit memo to review it before posting.';
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
        Rec.SetRange("Document Type", Rec."Document Type"::"Credit Memo");
        Rec.SetRange(Status, Rec.Status::Released);
        Rec.FilterGroup(0);
    end;

    procedure PostSelectedDocuments()
    var
        PurchaseHeader: Record "Purchase Header";
        BatchPost: Codeunit "BVR Purch Inv Batch Post";
    begin
        CurrPage.SetSelectionFilter(PurchaseHeader);
        BatchPost.PostDocuments(PurchaseHeader);
    end;

    // Takes the batch code from the parent rather than copying the page's filters. "Post the whole
    // batch" has to mean exactly the rows on screen, and the filters that define them now live in
    // filter group 2 - restating them here removes any dependence on which groups CopyFilters carries.
    //   //AAV.SP
    procedure PostAllDocuments(BatchCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        BatchPost: Codeunit "BVR Purch Inv Batch Post";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.SetRange("BVR Doc Batch No.", BatchCode);
        PurchaseHeader.SetRange(Status, PurchaseHeader.Status::Released);
        BatchPost.PostDocuments(PurchaseHeader);
    end;
}
