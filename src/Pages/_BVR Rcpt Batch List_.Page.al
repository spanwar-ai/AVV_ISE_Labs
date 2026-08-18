page 50153 "BVR Rcpt Batch List"
{
    // Doubles as the lookup behind Batch No. on the document, so Insert is allowed: the team can
    // create a batch straight from the lookup rather than having to leave the document first.
    // Entry point for batch-wise receipt posting: pick a batch, open it as a document, post its
    // warehouse receipts. Batch maintenance itself stays on "BVR Doc Batch List".   //AAV.SP
    PageType = List;
    SourceTable = "BVR Purch Rcpt Batch";
    Caption = 'Purchase Receipt Batches';
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
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date every document in this batch will post on. Set it and the batch posts as one accounting event, whatever dates the individual documents carry. Leave it blank and each document keeps its own posting date.';
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
                field(BVRTotalAmount; BVRTotalAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Total Amount (LCY)';
                    Editable = false;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total value of the released warehouse receipts in this batch - what it is about to book. Receipts that are not released yet are not counted, so this can be less than the batch holds.';
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
                ToolTip = 'Print the selected batches: every warehouse receipt in each one, the lines behind each receipt, and the accrual entry it will book when the batch is posted. Print this before posting - it exists to be read while there is still something to correct.';

                trigger OnAction()
                var
                    RcptBatch: Record "BVR Purch Rcpt Batch";
                begin
                    CurrPage.SetSelectionFilter(RcptBatch);
                    if RcptBatch.IsEmpty() then
                        exit;
                    Report.Run(Report::"BVR Purch Rcpt Batch Report", true, false, RcptBatch);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("BVR Open Batch_Promoted"; "BVR Open Batch") { }
            }
            group(Category_Report)
            {
                actionref("BVR Print Batch Edit List_Prom"; "BVR Print Batch Edit List") { }
            }
        }
    }

    // Totalled per row rather than held on the batch, so it can never disagree with the receipts it
    // is adding up. The cost is a read of each receipt's lines per row - fine at AP batch volumes.
    //   //AAV.SP
    trigger OnAfterGetRecord()
    begin
        BVRTotalAmount := Rec.CalcTotalAmount();
    end;

    var
        BVRTotalAmount: Decimal;
}
