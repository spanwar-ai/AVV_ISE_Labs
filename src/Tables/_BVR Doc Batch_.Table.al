table 50151 "BVR Doc Batch"
{
    // User-named batch that groups documents for AP review, in the spirit of a General Journal
    // Batch. The AP team assigns one to a Warehouse Receipt; it is carried onto the resulting
    // Posted Purchase Receipt when the WR posts (codeunit "BVR Whse Receipt Mgt").   //AAV.SP
    Caption = 'Document Batch';
    DataClassification = CustomerContent;
    LookupPageId = "BVR Doc Batch List";
    DrillDownPageId = "BVR Doc Batch List";

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
        // One batch belongs to one document kind. The Batch No. lookups on the Warehouse Receipt and
        // the Purchase Invoice each filter on this, so the two processes cannot pick each other's
        // batches. Note the primary key stays "Code" alone: a batch code is unique across ALL types,
        // so B1 is either a Receipt batch or an Invoice batch, never both.   //AAV.SP
        field(3; Type; Enum "BVR Batch Type")
        {
            Caption = 'Type';
        }
        // Set to Closed by CloseIfComplete when the last document leaves the batch. Not editable by
        // hand - use the Reopen action, so reopening is a deliberate act rather than a stray click.
        //   //AAV.SP
        field(4; Status; Enum "BVR Batch Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(10; "No. of Whse. Receipts"; Integer)
        {
            Caption = 'No. of Warehouse Receipts';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Warehouse Receipt Header" where("BVR Batch No." = field("Code")));
        }
        field(11; "No. of Posted Receipts"; Integer)
        {
            Caption = 'No. of Posted Receipts';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Purch. Rcpt. Header" where("BVR Batch No." = field("Code")));
        }
        field(12; "No. of Purch. Invoices"; Integer)
        {
            Caption = 'No. of Purchase Invoices';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Purchase Header" where("Document Type" = const(Invoice),
                                                         "BVR Doc Batch No." = field("Code")));
        }
        field(13; "No. of Posted Purch. Inv."; Integer)
        {
            Caption = 'No. of Posted Purchase Invoices';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Purch. Inv. Header" where("BVR Doc Batch No." = field("Code")));
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
        WhseRcptHeader: Record "Warehouse Receipt Header";
        PurchaseHeader: Record "Purchase Header";
        StillHasDocuments: Boolean;
    begin
        if Status = Status::Closed then
            exit(false);

        case Type of
            Type::Receipt:
                begin
                    WhseRcptHeader.SetRange("BVR Batch No.", "Code");
                    StillHasDocuments := not WhseRcptHeader.IsEmpty();
                end;
            Type::Invoice:
                begin
                    PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
                    PurchaseHeader.SetRange("BVR Doc Batch No.", "Code");
                    StillHasDocuments := not PurchaseHeader.IsEmpty();
                end;
        end;

        if StillHasDocuments then
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
}
