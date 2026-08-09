page 50156 "BVR Inv Batch List"
{
    // Entry point for batch-wise invoice posting: pick a batch, open it as a document, post its
    // invoices. Batch maintenance itself stays on "BVR Doc Batch List".   //AAV.SP
    PageType = List;
    SourceTable = "BVR Doc Batch";
    Caption = 'Purchase Invoice Batches';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "BVR Inv Batch";
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
                    ToolTip = 'Specifies the batch code. Open the batch to see and post its purchase invoices.';
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
                field("No. of Purch. Invoices"; Rec."No. of Purch. Invoices")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many purchase invoices are still open in this batch and therefore pending posting.';
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
                    ToolTip = 'Specifies the total value of the released purchase invoices in this batch - what it is about to book. Invoices that are still Open are not counted, so this can be less than the batch holds.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Open Inv Batch")
            {
                ApplicationArea = All;
                Caption = 'Open Batch';
                Image = Document;
                RunObject = page "BVR Inv Batch";
                RunPageLink = "Code" = field("Code");
                ToolTip = 'Open the batch to review and post the purchase invoices linked to it.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("BVR Open Inv Batch_Promoted"; "BVR Open Inv Batch") { }
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
        Rec.SetRange(Type, Rec.Type::Invoice);
        Rec.FilterGroup(0);
    end;

    // Totalled per row rather than held on the batch, so it can never disagree with the invoices it
    // is adding up.   //AAV.SP
    trigger OnAfterGetRecord()
    begin
        BVRTotalAmount := Rec.CalcTotalAmount();
    end;

    var
        BVRTotalAmount: Decimal;
}
