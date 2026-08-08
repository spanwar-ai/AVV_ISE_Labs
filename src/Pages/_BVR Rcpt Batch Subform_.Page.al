page 50155 "BVR Rcpt Batch Subform"
{
    // The "lines" of a receipt batch: every open Warehouse Receipt carrying this batch no. Rows are
    // multi-selectable, and the parent page posts whatever is selected.   //AAV.SP
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

    procedure PostSelectedReceipts()
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        BatchPost: Codeunit "BVR Whse Rcpt Batch Post";
    begin
        CurrPage.SetSelectionFilter(WhseRcptHeader);
        BatchPost.PostReceipts(WhseRcptHeader);
    end;

    procedure PostAllReceipts()
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        BatchPost: Codeunit "BVR Whse Rcpt Batch Post";
    begin
        WhseRcptHeader.CopyFilters(Rec);
        BatchPost.PostReceipts(WhseRcptHeader);
    end;
}
