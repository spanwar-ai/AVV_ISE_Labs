page 50163 "BVR Sales Order Batch"
{
    // A batch opened "like a document": the batch is the header, the Sales Orders carrying its batch
    // no. are the lines. Select lines and post them together.
    //
    // Posting an order ships AND invoices it, the same as the Post action on the order itself. An
    // order posted only in part stays in "Sales Header", so it stays in the batch and the batch stays
    // open - which is right: there is still something there to post.   //AAV.SP
    PageType = Document;
    SourceTable = "BVR Doc Batch";
    SourceTableView = where(Type = const("Sales Order"));
    Caption = 'Sales Order Batch';
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
                field("No. of Sales Orders"; Rec."No. of Sales Orders")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many sales orders are still open in this batch. A number higher than the lines below means some are not released yet.';
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
                    ToolTip = 'Specifies the total value of the released sales orders in this batch - the sum of the Amount Including VAT column in the lines below.';
                }
            }
            part(Lines; "BVR Sales Order Batch Subform")
            {
                ApplicationArea = All;
                Caption = 'Sales Orders';
                SubPageLink = "BVR Doc Batch No." = field("Code");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Post Selected Orders")
            {
                ApplicationArea = All;
                Caption = 'Post Selected';
                Image = PostDocument;
                ToolTip = 'Ship and invoice the sales orders selected in the lines. The batch is all or nothing: if any order fails, none of them are posted.';

                trigger OnAction()
                begin
                    CurrPage.Lines.Page.PostSelectedDocuments();
                    RefreshBatch();
                end;
            }
            action("BVR Post Whole Order Batch")
            {
                ApplicationArea = All;
                Caption = 'Post Whole Batch';
                Image = PostBatch;
                ToolTip = 'Ship and invoice every released sales order in this batch. The batch is all or nothing: a single order that fails any posting check stops the run and nothing is posted.';

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
                actionref("BVR Post Selected Orders_Prom"; "BVR Post Selected Orders") { }
                actionref("BVR Post Whole Order Btch_Prom"; "BVR Post Whole Order Batch") { }
            }
        }
    }

    // Fully posted orders leave "Sales Header", so the batch record is re-read rather than the page
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
        PostWholeBatchQst: Label 'Ship and invoice all sales orders in batch %1?', Comment = '%1 = batch code';
}
