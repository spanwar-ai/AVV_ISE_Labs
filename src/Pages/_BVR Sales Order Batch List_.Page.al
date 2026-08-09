page 50164 "BVR Sales Order Batch List"
{
    // Entry point for batch-wise sales order posting: pick a batch, open it as a document, post its
    // orders. Batch maintenance itself stays on "BVR Doc Batch List".   //AAV.SP
    PageType = List;
    SourceTable = "BVR Doc Batch";
    Caption = 'Sales Order Batches';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "BVR Sales Order Batch";
    Editable = false;
    InsertAllowed = false;
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
                field("No. of Sales Orders"; Rec."No. of Sales Orders")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many sales orders are still open in this batch and therefore pending posting.';
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
                    ToolTip = 'Specifies the total value of the released sales orders in this batch - what it is about to book.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Open Order Batch")
            {
                ApplicationArea = All;
                Caption = 'Open Batch';
                Image = Document;
                RunObject = page "BVR Sales Order Batch";
                RunPageLink = "Code" = field("Code");
                ToolTip = 'Open the batch to review and post the sales orders linked to it.';
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

    // Filter group 2 instead of SourceTableView. As SourceTableView the Type filter showed in the
    // filter pane as a removable chip, and clearing it turned this list into every batch in the
    // system - including other document types. Group 2 filters are not shown, so they cannot be
    // removed.   //AAV.SP
    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Type, Rec.Type::"Sales Order");
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetRecord()
    begin
        BVRTotalAmount := Rec.CalcTotalAmount();
    end;

    var
        BVRTotalAmount: Decimal;
}
