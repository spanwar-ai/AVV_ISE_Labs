page 50164 "BVR Sales Shpt Batch List"
{
    // Doubles as the lookup behind Batch No. on the document, so Insert is allowed: the team can
    // create a batch straight from the lookup rather than having to leave the document first.
    // Entry point for batch-wise sales shipment posting: pick a batch, open it as a document, post
    // its warehouse shipments. Batch maintenance itself stays on "BVR Doc Batch List".   //AAV.SP
    PageType = List;
    SourceTable = "BVR Sales Shpt Batch";
    Caption = 'Sales Shipment Batches';
    ApplicationArea = All;
    UsageCategory = Lists;
    // No CardPageId on purpose. The lookup behind Batch No. on the document offers a New line,
    // and with a CardPageId set that New opens the batch CARD - a document page whose lines are
    // linked on the batch code, so a not-yet-typed code would link to blank and list every
    // unbatched document in the company. Without it, New adds a row here instead, which is all a
    // batch needs: a code and a description. Use Open Batch to open one.   //AAV.SP
    Editable = true;
    InsertAllowed = true;
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
                    ToolTip = 'Specifies the batch code. Open the batch to see and post its sales orders.';
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
                field("No. of Whse. Shipments"; Rec."No. of Whse. Shipments")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many warehouse shipments are still in this batch and therefore pending posting.';
                }
                field("No. of Posted Sales Shpts."; Rec."No. of Posted Sales Shpts.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many posted sales shipments have come out of this batch.';
                }
                field(BVRTotalAmount; BVRTotalAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Total Amount (LCY)';
                    Editable = false;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total value of the released warehouse shipments in this batch - what it is about to post.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            // A batch closes itself when its last document posts. Reopening is the way back if a
            // posting was undone, or if the team simply needs to add more documents to it.   //AAV.SP
            action("BVR Reopen")
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

            action("BVR Open Order Batch")
            {
                ApplicationArea = All;
                Caption = 'Open Batch';
                Image = Document;
                RunObject = page "BVR Sales Shpt Batch";
                RunPageLink = "Code" = field("Code");
                ToolTip = 'Open the batch to review and post the warehouse shipments linked to it.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("BVR Open Order Batch_Promoted"; "BVR Open Order Batch") { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        BVRTotalAmount := Rec.CalcTotalAmount();
    end;

    var
        BVRTotalAmount: Decimal;
}
