page 50154 "BVR Rcpt Batch"
{
    // A batch opened "like a document": the batch itself is the header, and the Warehouse Receipts
    // carrying its batch no. are the lines. Select lines and post them together.   //AAV.SP
    PageType = Document;
    SourceTable = "BVR Purch Rcpt Batch";
    Caption = 'Purchase Receipt Batch';
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
                field("No. of Whse. Receipts"; Rec."No. of Whse. Receipts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many warehouse receipts are still open in this batch.';
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
                    ToolTip = 'Specifies the total value of the released warehouse receipts in this batch - the sum of the Amount column in the lines below. Receipts that are not released yet are not counted, and neither are posted ones, so this figure is what the batch is about to book.';
                }
            }
            part(Lines; "BVR Rcpt Batch Subform")
            {
                ApplicationArea = All;
                Caption = 'Warehouse Receipts';
                SubPageLink = "BVR Batch No." = field("Code");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Post Selected")
            {
                ApplicationArea = All;
                Caption = 'Post Selected';
                Image = PostDocument;
                ToolTip = 'Post the warehouse receipts selected in the lines. The batch is all or nothing: if any receipt fails, none of them are posted.';

                trigger OnAction()
                begin
                    CurrPage.Lines.Page.PostSelectedReceipts();
                    RefreshBatch();
                end;
            }
            action("BVR Post Whole Batch")
            {
                ApplicationArea = All;
                Caption = 'Post Whole Batch';
                Image = PostBatch;
                ToolTip = 'Post every warehouse receipt in this batch. The batch is all or nothing: a single receipt that is not yet Released, or that fails any posting check, stops the run and nothing is posted.';

                trigger OnAction()
                begin
                    if not Confirm(PostWholeBatchQst, false, Rec."Code") then
                        exit;
                    CurrPage.Lines.Page.PostAllReceipts(Rec."Code");
                    RefreshBatch();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("BVR Post Selected_Promoted"; "BVR Post Selected") { }
                actionref("BVR Post Whole Batch_Promoted"; "BVR Post Whole Batch") { }
            }
        }
    }

    // Posted receipts are deleted, so the current batch record is re-read rather than the page being
    // left showing counts that no longer hold.   //AAV.SP
    local procedure RefreshBatch()
    begin
        if Rec.Get(Rec."Code") then;
        CurrPage.Update(false);
    end;

    // CurrPage.Update in RefreshBatch re-runs this, so the total drops as posted receipts leave the
    // batch without any extra bookkeeping.   //AAV.SP
    trigger OnAfterGetCurrRecord()
    begin
        BVRTotalAmount := Rec.CalcTotalAmount();
    end;

    var
        BVRTotalAmount: Decimal;
        PostWholeBatchQst: Label 'Post all warehouse receipts in batch %1?', Comment = '%1 = batch code';
}
