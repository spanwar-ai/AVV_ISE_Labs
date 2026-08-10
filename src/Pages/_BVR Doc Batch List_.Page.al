page 50152 "BVR Doc Batch List"
{
    // Doubles as the maintenance list and as the lookup behind "Batch No." on the Warehouse Receipt.
    // Insert is deliberately left allowed so the AP team can create a new batch straight from the
    // lookup rather than having to leave the receipt first.   //AAV.SP
    PageType = List;
    SourceTable = "BVR Doc Batch";
    Caption = 'Document Batches';
    ApplicationArea = All;
    // Off the search menu: the per-process lists have replaced it. Reachable only through the
    // obsolete table it shows, so the original batches can still be inspected.   //AAV.SP
    UsageCategory = None;


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
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which document kind this batch is for. A Receipt batch can only be picked on warehouse receipts, an Invoice batch only on purchase invoices.';
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
                    ToolTip = 'Specifies how many open purchase invoices are currently assigned to this batch.';
                }
                field("No. of Posted Purch. Inv."; Rec."No. of Posted Purch. Inv.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many posted purchase invoices came from this batch.';
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
                // Every batch type gets its own pair of counts. Only the pair matching the Type
                // column is ever non-zero, so without these a Sales Order batch would show nothing
                // but zeros on this page.   //AAV.SP
                field("No. of Purch. Cr. Memos"; Rec."No. of Purch. Cr. Memos")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many open purchase credit memos are currently assigned to this batch.';
                }
                field("No. of Posted Purch. Cr.Memo"; Rec."No. of Posted Purch. Cr.Memo")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many posted purchase credit memos came from this batch.';
                }
                field("No. of Sales Orders"; Rec."No. of Sales Orders")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many open sales orders are currently assigned to this batch.';
                }
                field("No. of Posted Sales Invoices"; Rec."No. of Posted Sales Invoices")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many posted sales invoices came from this batch.';
                }
                field("No. of Sales Cr. Memos"; Rec."No. of Sales Cr. Memos")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many open sales credit memos are currently assigned to this batch.';
                }
                field("No. of Posted Sales Cr.Memo"; Rec."No. of Posted Sales Cr.Memo")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many posted sales credit memos came from this batch.';
                }
                field(BVRTotalAmount; BVRTotalAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Total Amount (LCY)';
                    Editable = false;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total value of the released documents in this batch - warehouse receipts on a Receipt batch, purchase invoices on an Invoice batch. Documents that are not released yet are not counted, so this can be less than the batch holds.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            // A batch closes itself when its last document posts. Reopening is the way back if a
            // posting was undone, or if AP simply needs to add more documents to the batch.   //AAV.SP
            action("BVR Reopen Batch")
            {
                ApplicationArea = All;
                Caption = 'Reopen';
                Image = ReOpen;
                Enabled = Rec.Status = Rec.Status::Closed;
                ToolTip = 'Reopen a closed batch so it can be assigned to documents again.';

                trigger OnAction()
                begin
                    Rec.Reopen();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("BVR Reopen Batch_Promoted"; "BVR Reopen Batch") { }
            }
        }
    }

    // This page is the lookup behind "Batch No." on every document, so the platform arrives here
    // carrying the TableRelation's filters - Type and Status = Open. Those land in filter group 0,
    // where the filter pane shows them as removable chips: a user could clear them and pick a closed
    // batch, or one belonging to a different document type.
    //
    // Moving them to filter group 2 keeps exactly the same filtering but takes them out of the pane,
    // so they cannot be cleared. Reading them back rather than hard-coding them means this works for
    // whichever document opened the lookup, and does nothing at all when the page is opened on its
    // own for batch maintenance.   //AAV.SP
    trigger OnOpenPage()
    var
        TypeFilter: Text;
        StatusFilter: Text;
    begin
        TypeFilter := Rec.GetFilter(Type);
        StatusFilter := Rec.GetFilter(Status);
        if (TypeFilter = '') and (StatusFilter = '') then
            exit;

        Rec.SetRange(Type);
        Rec.SetRange(Status);

        Rec.FilterGroup(2);
        if TypeFilter <> '' then
            Rec.SetFilter(Type, TypeFilter);
        if StatusFilter <> '' then
            Rec.SetFilter(Status, StatusFilter);
        Rec.FilterGroup(0);
    end;

    // Totalled per row rather than held on the batch, so it can never disagree with the documents it
    // is adding up. Each batch totals whichever kind it holds.   //AAV.SP
    trigger OnAfterGetRecord()
    begin
        BVRTotalAmount := Rec.CalcTotalAmount();
    end;

    var
        BVRTotalAmount: Decimal;
}
