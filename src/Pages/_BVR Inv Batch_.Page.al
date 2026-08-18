page 50157 "BVR Inv Batch"
{
    // A batch opened "like a document": the batch is the header, the Purchase Invoices carrying its
    // batch no. are the lines. Select lines and post them together.   //AAV.SP
    PageType = Document;
    SourceTable = "BVR Purch Inv Batch";
    Caption = 'Purchase Invoice Batch';
    ApplicationArea = All;
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the batch code.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the batch is still Open, or was closed automatically when its last document was posted.';
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
                field("No. of Purch. Invoices"; Rec."No. of Purch. Invoices")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many purchase invoices are still open in this batch.';
                }
                field("No. of Posted Purch. Inv."; Rec."No. of Posted Purch. Inv.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many posted purchase invoices have come out of this batch.';
                }
                field(BVRTotalAmount; BVRTotalAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Total Amount (LCY)';
                    Editable = false;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total value of the released purchase invoices in this batch - the sum of the Amount Including VAT column in the lines below. Invoices that are still Open are not counted, and neither are posted ones, so this figure is what the batch is about to book.';
                }
            }
            part(Lines; "BVR Inv Batch Subform")
            {
                ApplicationArea = All;
                Caption = 'Purchase Invoices';
                SubPageLink = "BVR Doc Batch No." = field("Code");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Post Selected Invoices")
            {
                ApplicationArea = All;
                Caption = 'Post Selected';
                Image = PostDocument;
                ToolTip = 'Post the purchase invoices selected in the lines. The batch is all or nothing: if any invoice fails, none of them are posted.';

                trigger OnAction()
                begin
                    CurrPage.Lines.Page.PostSelectedInvoices();
                    RefreshBatch();
                end;
            }
            action("BVR Post Whole Inv Batch")
            {
                ApplicationArea = All;
                Caption = 'Post Whole Batch';
                Image = PostBatch;
                ToolTip = 'Post every purchase invoice in this batch. The batch is all or nothing: a single invoice that fails any posting check stops the run and nothing is posted.';

                trigger OnAction()
                begin
                    if not Confirm(PostWholeBatchQst, false, Rec."Code") then
                        exit;
                    CurrPage.Lines.Page.PostAllInvoices(Rec."Code");
                    RefreshBatch();
                end;
            }
        }
        area(reporting)
        {
            // The edit list, run against the batch that is open. Printed BEFORE posting - it exists
            // to be read while there is still something to correct.   //AAV.SP
            action("BVR Print Batch Edit List")
            {
                ApplicationArea = All;
                Caption = 'Print';
                Image = PrintReport;
                ToolTip = 'Print this batch: every invoice in it, the lines behind each one, and the G/L distribution each will book when the batch is posted.';

                trigger OnAction()
                var
                    InvBatch: Record "BVR Purch Inv Batch";
                begin
                    InvBatch.SetRange("Code", Rec."Code");
                    Report.Run(Report::"BVR Purch Inv Batch Report", true, false, InvBatch);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("BVR Post Selected Inv_Promoted"; "BVR Post Selected Invoices") { }
                actionref("BVR Post Whole Inv Batch_Prom"; "BVR Post Whole Inv Batch") { }
            }
            group(Category_Report)
            {
                actionref("BVR Print Batch Edit List_Prom"; "BVR Print Batch Edit List") { }
            }
        }
    }

    // Posted invoices leave "Purchase Header", so the batch record is re-read rather than the page
    // being left showing counts that no longer hold.   //AAV.SP
    local procedure RefreshBatch()
    begin
        if Rec.Get(Rec."Code") then;
        CurrPage.Update(false);
    end;

    // CurrPage.Update in RefreshBatch re-runs this, so the total drops as posted invoices leave the
    // batch without any extra bookkeeping.   //AAV.SP
    trigger OnAfterGetCurrRecord()
    begin
        BVRTotalAmount := Rec.CalcTotalAmount();
    end;

    var
        BVRTotalAmount: Decimal;
        PostWholeBatchQst: Label 'Post all purchase invoices in batch %1?', Comment = '%1 = batch code';
}
