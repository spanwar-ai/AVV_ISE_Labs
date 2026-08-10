page 50160 "BVR Purch CrMemo Batch"
{
    // A batch opened "like a document": the batch is the header, the Purchase Credit Memos carrying
    // its batch no. are the lines. Select lines and post them together.   //AAV.SP
    PageType = Document;
    SourceTable = "BVR Purch CrMemo Batch";
    Caption = 'Purchase Credit Memo Batch';
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
                field("No. of Purch. Cr. Memos"; Rec."No. of Purch. Cr. Memos")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many purchase credit memos are still open in this batch. A number higher than the lines below means some are not released yet.';
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
                    ToolTip = 'Specifies the total value of the released purchase credit memos in this batch - the sum of the Amount Including VAT column in the lines below.';
                }
            }
            part(Lines; "BVR Purch CrMemo Batch Subform")
            {
                ApplicationArea = All;
                Caption = 'Purchase Credit Memos';
                SubPageLink = "BVR Doc Batch No." = field("Code");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Post Selected CrMemos")
            {
                ApplicationArea = All;
                Caption = 'Post Selected';
                Image = PostDocument;
                ToolTip = 'Post the purchase credit memos selected in the lines. The batch is all or nothing: if any credit memo fails, none of them are posted.';

                trigger OnAction()
                begin
                    CurrPage.Lines.Page.PostSelectedDocuments();
                    RefreshBatch();
                end;
            }
            action("BVR Post Whole CrMemo Batch")
            {
                ApplicationArea = All;
                Caption = 'Post Whole Batch';
                Image = PostBatch;
                ToolTip = 'Post every released purchase credit memo in this batch. The batch is all or nothing: a single credit memo that fails any posting check stops the run and nothing is posted.';

                trigger OnAction()
                begin
                    if not Confirm(PostWholeBatchQst, false, Rec."Code") then
                        exit;
                    CurrPage.Lines.Page.PostAllDocuments(Rec."Code");
                    RefreshBatch();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("BVR Post Selected CrMemos_Prom"; "BVR Post Selected CrMemos") { }
                actionref("BVR Post Whole CrMemo Btch_Prom"; "BVR Post Whole CrMemo Batch") { }
            }
        }
    }

    // Posted credit memos leave "Purchase Header", so the batch record is re-read rather than the
    // page being left showing counts that no longer hold.   //AAV.SP
    local procedure RefreshBatch()
    begin
        if Rec.Get(Rec."Code") then;
        CurrPage.Update(false);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        BVRTotalAmount := Rec.CalcTotalAmount();
    end;

    var
        BVRTotalAmount: Decimal;
        PostWholeBatchQst: Label 'Post all purchase credit memos in batch %1?', Comment = '%1 = batch code';
}
