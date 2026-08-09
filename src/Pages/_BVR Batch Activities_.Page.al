page 50168 "BVR Batch Activities"
{
    // Batch tiles for the Business Manager Role Center. Each tile drills through to the batch list it
    // counts, so the Role Center is a way in to the batch process rather than just a readout.
    //
    // Two groups on purpose. The first answers "how many batches are open", the second "is there
    // anything in them to post" - a batch can sit open for days with nothing released in it, so the
    // batch count on its own cannot tell a manager whether there is work waiting.   //AAV.SP
    PageType = CardPart;
    SourceTable = "BVR Batch Cue";
    Caption = 'Document Batches';
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    ShowFilter = false;

    layout
    {
        area(content)
        {
            cuegroup("Open Batches")
            {
                Caption = 'Open Batches';

                field("Purchase Receipt Batches"; Rec."Purchase Receipt Batches")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BVR Rcpt Batch List";
                    ToolTip = 'Specifies how many purchase receipt batches are still open. Choose the number to open them.';
                }
                field("Purchase Invoice Batches"; Rec."Purchase Invoice Batches")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BVR Inv Batch List";
                    ToolTip = 'Specifies how many purchase invoice batches are still open. Choose the number to open them.';
                }
                field("Purchase Cr. Memo Batches"; Rec."Purchase Cr. Memo Batches")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BVR Purch CrMemo Batch List";
                    ToolTip = 'Specifies how many purchase credit memo batches are still open. Choose the number to open them.';
                }
                field("Sales Order Batches"; Rec."Sales Order Batches")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BVR Sales Order Batch List";
                    ToolTip = 'Specifies how many sales order batches are still open. Choose the number to open them.';
                }
                field("Sales Cr. Memo Batches"; Rec."Sales Cr. Memo Batches")
                {
                    ApplicationArea = All;
                    DrillDownPageId = "BVR Sales CrMemo Batch List";
                    ToolTip = 'Specifies how many sales credit memo batches are still open. Choose the number to open them.';
                }
            }
            cuegroup("Waiting to Post")
            {
                Caption = 'Waiting to Post';

                field("Whse. Receipts to Post"; Rec."Whse. Receipts to Post")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many released warehouse receipts are sitting in a batch waiting to be posted. Receipts that are not released yet are not counted, because they cannot be posted.';
                }
                field("Purch. Documents to Post"; Rec."Purch. Documents to Post")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many released purchase invoices and credit memos are sitting in a batch waiting to be posted.';
                }
                field("Sales Documents to Post"; Rec."Sales Documents to Post")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many released sales orders and credit memos are sitting in a batch waiting to be posted.';
                }
            }
        }
    }

    // A cue table carries one blank-key record that nothing else creates, so the part makes it on
    // first use. Without this the tiles have no record to calculate against and show nothing at all.
    //   //AAV.SP
    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
