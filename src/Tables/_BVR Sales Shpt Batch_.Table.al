table 50156 "BVR Sales Shpt Batch"
{
    // Batch of warehouse shipments for review before posting, in the spirit of a General Journal Batch.
    //
    // One table per batch process. A batch code therefore means exactly one thing - a sales shipment batch - and
    // the tables carry no Type field to keep in step. The trade is that the same code can exist on two
    // different batch tables; they are separate registers, not one register with a discriminator.
    //
    // Shared behaviour - what a batch is worth, and whether anything is left in it - lives in codeunit
    // "BVR Batch Doc Mgt" rather than being copied into all five tables.   //AAV.SP
    Caption = 'Sales Shipment Batch';
    DataClassification = CustomerContent;
    LookupPageId = "BVR Sales Shpt Batch List";
    DrillDownPageId = "BVR Sales Shpt Batch List";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        // Set to Closed by CloseIfComplete when the last document leaves the batch. Not editable by
        // hand - use the Reopen action, so reopening is a deliberate act rather than a stray click.
        field(4; Status; Enum "BVR Batch Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(10; "No. of Whse. Shipments"; Integer)
        {
            Caption = 'No. of Warehouse Shipments';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Warehouse Shipment Header" where("BVR Batch No." = field("Code")));
        }
        field(11; "No. of Posted Sales Shpts."; Integer)
        {
            Caption = 'No. of Posted Sales Shipments';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Sales Shipment Header" where("BVR Batch No." = field("Code")));
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    // Closes the batch once nothing is left in it to post. Called at the end of a successful batch
    // post; runs inside that same transaction, so if the batch post is rolled back the close goes
    // with it. Returns whether it actually closed the batch.   //AAV.SP
    procedure CloseIfComplete(): Boolean
    var
        BatchDocMgt: Codeunit "BVR Batch Doc Mgt";
    begin
        if Status = Status::Closed then
            exit(false);
        if not BatchDocMgt.WhseShptBatchIsEmpty("Code") then
            exit(false);

        Status := Status::Closed;
        Modify();
        exit(true);
    end;

    procedure Reopen()
    begin
        if Status = Status::Open then
            exit;
        Status := Status::Open;
        Modify();
    end;

    // What the batch is about to book, in LCY. Released documents only, so it ties back to the lines
    // the batch page lists.   //AAV.SP
    procedure CalcTotalAmount(): Decimal
    var
        BatchDocMgt: Codeunit "BVR Batch Doc Mgt";
    begin
        exit(BatchDocMgt.WhseShptTotal("Code"));
    end;
}
