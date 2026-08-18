page 50163 "BVR Sales Inv Batch"
{
    // A batch opened "like a document": the batch is the header, the Sales Invoices carrying its
    // batch no. are the lines. Select lines and post them together.   //AAV.SP
    PageType = Document;
    SourceTable = "BVR Sales Inv Batch";
    Caption = 'Sales Invoice Batch';
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
                field("No. of Sales Invoices"; Rec."No. of Sales Invoices")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many sales invoices are still open in this batch. A number higher than the lines below means some are not released yet.';
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
                    ToolTip = 'Specifies the total value of the released sales invoices in this batch - the sum of the Amount Including VAT column in the lines below.';
                }
            }
            part(Lines; "BVR Sales Inv Batch Subform")
            {
                ApplicationArea = All;
                Caption = 'Sales Invoices';
                SubPageLink = "BVR Doc Batch No." = field("Code");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Post Selected SInvoices")
            {
                ApplicationArea = All;
                Caption = 'Post Selected';
                Image = PostDocument;
                ToolTip = 'Post the sales invoices selected in the lines. The batch is all or nothing: if any invoice fails, none of them are posted.';

                trigger OnAction()
                begin
                    CurrPage.Lines.Page.PostSelectedDocuments();
                    RefreshBatch();
                end;
            }
            action("BVR Post Whole SInv Batch")
            {
                ApplicationArea = All;
                Caption = 'Post Whole Batch';
                Image = PostBatch;
                ToolTip = 'Post every released sales invoice in this batch. The batch is all or nothing: a single invoice that fails any posting check stops the run and nothing is posted.';

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
                actionref("BVR Post Selected SInv_Prom"; "BVR Post Selected SInvoices") { }
                actionref("BVR Post Whole SInv Btch_Prom"; "BVR Post Whole SInv Batch") { }
            }
        }
    }

    // Posted invoices leave "Sales Header", so the batch record is re-read rather than the page
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
        PostWholeBatchQst: Label 'Post all sales invoices in batch %1?', Comment = '%1 = batch code';
}
