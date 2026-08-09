page 50166 "BVR Sales CrMemo Batch"
{
    // A batch opened "like a document": the batch is the header, the Sales Credit Memos carrying its
    // batch no. are the lines. Select lines and post them together.   //AAV.SP
    PageType = Document;
    SourceTable = "BVR Doc Batch";
    SourceTableView = where(Type = const("Sales Credit Memo"));
    Caption = 'Sales Credit Memo Batch';
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
                field("No. of Sales Cr. Memos"; Rec."No. of Sales Cr. Memos")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many sales credit memos are still open in this batch. A number higher than the lines below means some are not released yet.';
                }
                field("No. of Posted Sales Cr.Memo"; Rec."No. of Posted Sales Cr.Memo")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many posted sales credit memos have come out of this batch.';
                }
                field(BVRTotalAmount; BVRTotalAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Total Amount (LCY)';
                    Editable = false;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total value of the released sales credit memos in this batch - the sum of the Amount Including VAT column in the lines below.';
                }
            }
            part(Lines; "BVR Sales CrMemo Batch Subform")
            {
                ApplicationArea = All;
                Caption = 'Sales Credit Memos';
                SubPageLink = "BVR Doc Batch No." = field("Code");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Post Selected SCrMemos")
            {
                ApplicationArea = All;
                Caption = 'Post Selected';
                Image = PostDocument;
                ToolTip = 'Post the sales credit memos selected in the lines. The batch is all or nothing: if any credit memo fails, none of them are posted.';

                trigger OnAction()
                begin
                    CurrPage.Lines.Page.PostSelectedDocuments();
                    RefreshBatch();
                end;
            }
            action("BVR Post Whole SCrMemo Batch")
            {
                ApplicationArea = All;
                Caption = 'Post Whole Batch';
                Image = PostBatch;
                ToolTip = 'Post every released sales credit memo in this batch. The batch is all or nothing: a single credit memo that fails any posting check stops the run and nothing is posted.';

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
                actionref("BVR Post Selected SCrMemos_Prom"; "BVR Post Selected SCrMemos") { }
                actionref("BVR Post Whole SCrMemo Btch_Prom"; "BVR Post Whole SCrMemo Batch") { }
            }
        }
    }

    // Posted credit memos leave "Sales Header", so the batch record is re-read rather than the page
    // being left showing counts that no longer hold.   //AAV.SP
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
        PostWholeBatchQst: Label 'Post all sales credit memos in batch %1?', Comment = '%1 = batch code';
}
