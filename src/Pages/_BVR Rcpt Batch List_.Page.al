page 50153 "BVR Rcpt Batch List"
{
    // Entry point for batch-wise receipt posting: pick a batch, open it as a document, post its
    // warehouse receipts. Batch maintenance itself stays on "BVR Doc Batch List".   //AAV.SP
    PageType = List;
    SourceTable = "BVR Doc Batch";
    SourceTableView = where(Type = const(Receipt));
    Caption = 'Purchase Receipt Batches';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "BVR Rcpt Batch";
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
                    ToolTip = 'Specifies the batch code. Open the batch to see and post its warehouse receipts.';
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
                field("No. of Whse. Receipts"; Rec."No. of Whse. Receipts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many warehouse receipts are still open in this batch and therefore pending posting.';
                }
                field("No. of Posted Receipts"; Rec."No. of Posted Receipts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many posted purchase receipts have come out of this batch.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Open Batch")
            {
                ApplicationArea = All;
                Caption = 'Open Batch';
                Image = Document;
                RunObject = page "BVR Rcpt Batch";
                RunPageLink = "Code" = field("Code");
                ToolTip = 'Open the batch to review and post the warehouse receipts linked to it.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("BVR Open Batch_Promoted"; "BVR Open Batch") { }
            }
        }
    }
}
