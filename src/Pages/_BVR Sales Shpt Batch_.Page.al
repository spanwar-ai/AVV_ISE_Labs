page 50163 "BVR Sales Shpt Batch"
{
    // A batch opened "like a document": the batch is the header, the Warehouse Shipments carrying its
    // batch no. are the lines. Select lines and post them together.
    //
    // The sales mirror of the receipt batch: it batches the WAREHOUSE SHIPMENT, not the sales order,
    // and posting it produces the Posted Sales Shipments the batch then reports on. A shipment posted
    // only in part stays put, so it stays in the batch and the batch stays open.   //AAV.SP
    PageType = Document;
    SourceTable = "BVR Sales Shpt Batch";
    Caption = 'Sales Shipment Batch';
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
                field("No. of Whse. Shipments"; Rec."No. of Whse. Shipments")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many warehouse shipments are still in this batch. A number higher than the lines below means some are not released yet.';
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
                    ToolTip = 'Specifies the total value of the released warehouse shipments in this batch - the sum of the Amount column in the lines below.';
                }
            }
            part(Lines; "BVR Sales Shpt Batch Subform")
            {
                ApplicationArea = All;
                Caption = 'Warehouse Shipments';
                SubPageLink = "BVR Batch No." = field("Code");
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
                ToolTip = 'Post the warehouse shipments selected in the lines. The batch is all or nothing: if any shipment fails, none of them are posted.';

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
                ToolTip = 'Post every released warehouse shipment in this batch. The batch is all or nothing: a single shipment that fails any posting check stops the run and nothing is posted.';

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

    // Fully posted shipments are deleted, so the batch record is re-read rather than the page
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
        PostWholeBatchQst: Label 'Post all warehouse shipments in batch %1?', Comment = '%1 = batch code';
}
