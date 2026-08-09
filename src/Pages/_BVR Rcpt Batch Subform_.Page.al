page 50155 "BVR Rcpt Batch Subform"
{
    // The "lines" of a receipt batch: the RELEASED Warehouse Receipts carrying this batch no. Rows are
    // multi-selectable, and the parent page posts whatever is selected.
    //
    // Released only, because this is a posting screen - a receipt still working its way through the AP
    // flow cannot be posted, and listing it here would only invite a click that ends in an error. The
    // "No. of Warehouse Receipts" count on the header still counts every receipt in the batch, so a
    // count higher than the number of lines is the sign that some are not released yet.   //AAV.SP
    PageType = ListPart;
    SourceTable = "Warehouse Receipt Header";
    Caption = 'Warehouse Receipts';
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
                    ToolTip = 'Specifies the warehouse receipt number.';
                }
                field("BVR Receipt Status"; Rec."BVR Receipt Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies where this receipt is in the AP / approval flow. Only Released receipts can be posted.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the location the goods are received at.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the receipt.';
                }
                field("Document Status"; Rec."Document Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the receipt is partially or completely received.';
                }
                field(BVRAmount; BVRAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Amount (LCY)';
                    Editable = false;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the value of this receipt: the quantity to receive on each line at the purchase order''s unit cost, less any line discount. These are the figures the batch total adds up.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user the receipt is assigned to.';
                }
                field("BVR Vendor Accrual Acc No."; Rec."BVR Vendor Accrual Acc No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the G/L account credited when this receipt is posted.';
                }
                field("BVR Expense Accrual Acc No."; Rec."BVR Expense Accrual Acc No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the G/L account debited when this receipt is posted.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Open Whse Receipt")
            {
                ApplicationArea = All;
                Caption = 'Open Warehouse Receipt';
                Image = Document;
                RunObject = page "Warehouse Receipt";
                RunPageLink = "No." = field("No.");
                ToolTip = 'Open the selected warehouse receipt to review it before posting.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        BVRAmount := Rec.BVRCalcAmount();
    end;

    var
        BVRAmount: Decimal;

    // Filter group 2, not SourceTableView. As SourceTableView these showed in the filter pane as
    // removable chips, and clearing them would list documents this screen cannot post - unreleased
    // ones, or the wrong document type entirely. Group 2 filters are not shown and cannot be cleared.
    //   //AAV.SP
    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("BVR Receipt Status", Rec."BVR Receipt Status"::Released);
        Rec.FilterGroup(0);
    end;

    procedure PostSelectedReceipts()
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        BatchPost: Codeunit "BVR Whse Rcpt Batch Post";
    begin
        CurrPage.SetSelectionFilter(WhseRcptHeader);
        BatchPost.PostReceipts(WhseRcptHeader);
    end;

    // Takes the batch code from the parent rather than copying the page's filters. "Post the whole
    // batch" has to mean exactly the rows on screen, and the filters that define them now live in
    // filter group 2 - restating them here removes any dependence on which groups CopyFilters carries.
    //   //AAV.SP
    procedure PostAllReceipts(BatchCode: Code[20])
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        BatchPost: Codeunit "BVR Whse Rcpt Batch Post";
    begin
        WhseRcptHeader.SetRange("BVR Batch No.", BatchCode);
        WhseRcptHeader.SetRange("BVR Receipt Status", WhseRcptHeader."BVR Receipt Status"::Released);
        BatchPost.PostReceipts(WhseRcptHeader);
    end;
}
