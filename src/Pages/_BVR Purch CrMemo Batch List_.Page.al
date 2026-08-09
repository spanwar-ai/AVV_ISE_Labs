page 50161 "BVR Purch CrMemo Batch List"
{
    // Entry point for batch-wise credit memo posting: pick a batch, open it as a document, post its
    // credit memos. Batch maintenance itself stays on "BVR Doc Batch List".   //AAV.SP
    PageType = List;
    SourceTable = "BVR Doc Batch";
    Caption = 'Purchase Credit Memo Batches';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "BVR Purch CrMemo Batch";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Gen)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the batch code. Open the batch to see and post its purchase credit memos.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the batch is still Open, or was closed automatically when its last document was posted. Closed batches cannot be picked on new documents.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies what this batch is for.';
                }
                field("No. of Purch. Cr. Memos"; Rec."No. of Purch. Cr. Memos")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many purchase credit memos are still open in this batch and therefore pending posting.';
                }
                field("No. of Posted Purch. Cr.Memo"; Rec."No. of Posted Purch. Cr.Memo")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many posted purchase credit memos have come out of this batch.';
                }
                field(BVRTotalAmount; BVRTotalAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Total Amount (LCY)';
                    Editable = false;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total value of the released purchase credit memos in this batch - what it is about to book.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Open CrMemo Batch")
            {
                ApplicationArea = All;
                Caption = 'Open Batch';
                Image = Document;
                RunObject = page "BVR Purch CrMemo Batch";
                RunPageLink = "Code" = field("Code");
                ToolTip = 'Open the batch to review and post the purchase credit memos linked to it.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("BVR Open CrMemo Batch_Promoted"; "BVR Open CrMemo Batch") { }
            }
        }
    }

    // Filter group 2 instead of SourceTableView. As SourceTableView the Type filter showed in the
    // filter pane as a removable chip, and clearing it turned this list into every batch in the
    // system - including other document types. Group 2 filters are not shown, so they cannot be
    // removed.   //AAV.SP
    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Type, Rec.Type::"Purch. Credit Memo");
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetRecord()
    begin
        BVRTotalAmount := Rec.CalcTotalAmount();
    end;

    var
        BVRTotalAmount: Decimal;
}
