page 50156 "BVR Inv Batch List"
{
    // Entry point for batch-wise invoice posting: pick a batch, open it as a document, post its
    // invoices. Batch maintenance itself stays on "BVR Doc Batch List".   //AAV.SP
    PageType = List;
    SourceTable = "BVR Doc Batch";
    SourceTableView = where(Type = const(Invoice));
    Caption = 'Purchase Invoice Batches';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "BVR Inv Batch";
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
                    ToolTip = 'Specifies the batch code. Open the batch to see and post its purchase invoices.';
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
                field("No. of Purch. Invoices"; Rec."No. of Purch. Invoices")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many purchase invoices are still open in this batch and therefore pending posting.';
                }
                field("No. of Posted Purch. Inv."; Rec."No. of Posted Purch. Inv.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many posted purchase invoices have come out of this batch.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Open Inv Batch")
            {
                ApplicationArea = All;
                Caption = 'Open Batch';
                Image = Document;
                RunObject = page "BVR Inv Batch";
                RunPageLink = "Code" = field("Code");
                ToolTip = 'Open the batch to review and post the purchase invoices linked to it.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("BVR Open Inv Batch_Promoted"; "BVR Open Inv Batch") { }
            }
        }
    }
}
