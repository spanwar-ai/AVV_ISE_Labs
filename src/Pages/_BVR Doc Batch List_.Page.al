page 50152 "BVR Doc Batch List"
{
    // Doubles as the maintenance list and as the lookup behind "Batch No." on the Warehouse Receipt.
    // Insert is deliberately left allowed so the AP team can create a new batch straight from the
    // lookup rather than having to leave the receipt first.   //AAV.SP
    PageType = List;
    SourceTable = "BVR Doc Batch";
    Caption = 'Document Batches';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Gen)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the batch code. The AP team assigns this to Warehouse Receipts to group them for review.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which document kind this batch is for. A Receipt batch can only be picked on warehouse receipts, an Invoice batch only on purchase invoices.';
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
                    ToolTip = 'Specifies how many open purchase invoices are currently assigned to this batch.';
                }
                field("No. of Posted Purch. Inv."; Rec."No. of Posted Purch. Inv.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many posted purchase invoices came from this batch.';
                }
                field("No. of Whse. Receipts"; Rec."No. of Whse. Receipts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many open Warehouse Receipts are currently assigned to this batch.';
                }
                field("No. of Posted Receipts"; Rec."No. of Posted Receipts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many Posted Purchase Receipts came from this batch.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            // A batch closes itself when its last document posts. Reopening is the way back if a
            // posting was undone, or if AP simply needs to add more documents to the batch.   //AAV.SP
            action("BVR Reopen Batch")
            {
                ApplicationArea = All;
                Caption = 'Reopen';
                Image = ReOpen;
                Enabled = Rec.Status = Rec.Status::Closed;
                ToolTip = 'Reopen a closed batch so it can be assigned to documents again.';

                trigger OnAction()
                begin
                    Rec.Reopen();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("BVR Reopen Batch_Promoted"; "BVR Reopen Batch") { }
            }
        }
    }
}
