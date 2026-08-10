page 50162 "BVR Sales Shpt Batch Subform"
{
    // The "lines" of a sales shipment batch: the RELEASED Warehouse Shipments carrying this batch no.
    // Rows are multi-selectable, and the parent page posts whatever is selected.
    //
    // Released only, because this is a posting screen - an Open warehouse shipment cannot be posted.
    // The "No. of Warehouse Shipments" count on the header still counts every shipment in the batch,
    // so a count higher than the number of lines is the sign that some are not released yet.   //AAV.SP
    PageType = ListPart;
    SourceTable = "Warehouse Shipment Header";
    Caption = 'Warehouse Shipments';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Gen)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the warehouse shipment number.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the shipment is Open or Released. Only Released shipments can be posted.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the location the goods are shipped from.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the shipment.';
                }
                field("Document Status"; Rec."Document Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the shipment is partially or completely shipped.';
                }
                field(BVRAmount; BVRAmount)
                {
                    ApplicationArea = All;
                    Caption = 'Amount (LCY)';
                    Editable = false;
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the value of this shipment: the quantity to ship on each line at the sales order unit price, less any line discount. These are the figures the batch total adds up.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user the shipment is assigned to.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("BVR Open Whse Shipment")
            {
                ApplicationArea = All;
                Caption = 'Open Warehouse Shipment';
                Image = Document;
                RunObject = page "Warehouse Shipment";
                RunPageLink = "No." = field("No.");
                ToolTip = 'Open the selected warehouse shipment to review it before posting.';
            }
        }
    }

    // Filter group 2, not SourceTableView. As SourceTableView it showed in the filter pane as a
    // removable chip, and clearing it would list shipments this screen cannot post.   //AAV.SP
    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Status, Rec.Status::Released);
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetRecord()
    begin
        BVRAmount := Rec.BVRCalcAmount();
    end;

    var
        BVRAmount: Decimal;

    procedure PostSelectedDocuments()
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        BatchPost: Codeunit "BVR Whse Shpt Batch Post";
    begin
        CurrPage.SetSelectionFilter(WhseShptHeader);
        BatchPost.PostShipments(WhseShptHeader);
    end;

    // Takes the batch code from the parent rather than copying the page's filters. "Post the whole
    // batch" has to mean exactly the rows on screen.   //AAV.SP
    procedure PostAllDocuments(BatchCode: Code[20])
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        BatchPost: Codeunit "BVR Whse Shpt Batch Post";
    begin
        WhseShptHeader.SetRange("BVR Batch No.", BatchCode);
        WhseShptHeader.SetRange(Status, WhseShptHeader.Status::Released);
        BatchPost.PostShipments(WhseShptHeader);
    end;
}
