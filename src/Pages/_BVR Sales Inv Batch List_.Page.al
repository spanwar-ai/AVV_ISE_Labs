page 50164 "BVR Sales Inv Batch List"
{
    // Doubles as the lookup behind Batch No. on the document, so Insert is allowed: the team can
    // create a batch straight from the lookup rather than having to leave the document first.
    // Entry point for batch-wise sales invoice posting: pick a batch, open it as a document, post
    // its invoices. Batch maintenance itself stays on "BVR Doc Batch List".   //AAV.SP
    PageType = List;
    SourceTable = "BVR Sales Inv Batch";
    Caption = 'Sales Invoice Batches';
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
                    ToolTip = 'Specifies the batch code. Open the batch to see and post its sales invoices.';
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
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date every document in this batch will post on. Set it and the batch posts as one accounting event, whatever dates the individual documents carry. Leave it blank and each document keeps its own posting date.';
                }
                field("No. of Sales Invoices"; Rec."No. of Sales Invoices")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many sales invoices are still open in this batch and therefore pending posting.';
                }
                field("No. of Posted Sales Invoices"; Rec."No. of Posted Sales Invoices")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many posted sales invoices have come out of this batch.';
                }
                field(BVRTotalAmount; BVRTotalAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Total Amount (LCY)';
                    Editable = false;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total value of the released sales invoices in this batch - what it is about to book.';
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

            action("BVR Open SInv Batch")
            {
                ApplicationArea = All;
                Caption = 'Open Batch';
                Image = Document;
                RunObject = page "BVR Sales Inv Batch";
                RunPageLink = "Code" = field("Code");
                ToolTip = 'Open the batch to review and post the sales invoices linked to it.';
            }
        }
        area(reporting)
        {
            // Printed from the list rather than only from inside a batch, so a whole run of batches
            // can go out in one report. Rows selected in the list are what gets printed; with
            // nothing selected it is the row the cursor is on.   //AAV.SP
            action("BVR Print Batch Edit List")
            {
                ApplicationArea = All;
                Caption = 'Print';
                Image = PrintReport;
                ToolTip = 'Print the selected batches: every document in each one, the lines behind it, and the G/L distribution it will book when the batch is posted. Print this before posting - it exists to be read while there is still something to correct.';

                trigger OnAction()
                var
                    EditListBatch: Record "BVR Sales Inv Batch";
                begin
                    CurrPage.SetSelectionFilter(EditListBatch);
                    if EditListBatch.IsEmpty() then
                        exit;
                    Report.Run(Report::"BVR Sales Inv Batch Report", true, false, EditListBatch);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("BVR Open SInv Batch_Promoted"; "BVR Open SInv Batch") { }
            }
            group(Category_Report)
            {
                actionref("BVR Print Batch Edit List_Prom"; "BVR Print Batch Edit List") { }
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
