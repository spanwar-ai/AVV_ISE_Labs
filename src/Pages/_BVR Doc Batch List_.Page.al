page 50152 "BVR Doc Batch List"
{
    // Doubles as the maintenance list and as the lookup behind "Batch No." on the Warehouse Receipt.
    // Insert is deliberately left allowed so the AP team can create a new batch straight from the
    // lookup rather than having to leave the receipt first.   //AAV.SP
    PageType = List;
    SourceTable = "BVR Doc Batch";
    Caption = 'Document Batches';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Gen)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the batch code. The AP team assigns this to Warehouse Receipts to group them for review.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies what this batch is for.';
                }
                field("No. of Whse. Receipts"; Rec."No. of Whse. Receipts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many open Warehouse Receipts are currently assigned to this batch.';
                }
                field("No. of Posted Receipts"; Rec."No. of Posted Receipts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many Posted Purchase Receipts came from this batch.';
                }
            }
        }
    }
}
