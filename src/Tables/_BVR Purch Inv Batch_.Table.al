table 50154 "BVR Purch Inv Batch"
{
    // Batch of purchase invoices for AP/AR review, in the spirit of a General Journal Batch.
    //
    // One table per batch process. A batch code therefore means exactly one thing - a purchase invoice batch - and
    // the tables carry no Type field to keep in step. The trade is that the same code can exist on two
    // different batch tables; they are separate registers, not one register with a discriminator.
    //
    // Shared behaviour - what a batch is worth, and whether anything is left in it - lives in codeunit
    // "BVR Batch Doc Mgt" rather than being copied into all five tables.   //AAV.SP
    Caption = 'Purchase Invoice Batch';
    DataClassification = CustomerContent;
    LookupPageId = "BVR Inv Batch List";
    DrillDownPageId = "BVR Inv Batch List";

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
        // Every document in this batch posts on THIS date. A batch is one accounting event, so a run
        // cannot straddle two dates just because the documents happened to be entered on different
        // days. Left blank, each document keeps its own posting date and nothing is overridden -
        // which is what every batch created before this field existed does.   //AAV.SP
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                if Status = Status::Closed then
                    Error(ClosedBatchErr, "Code");
            end;
        }
        field(10; "No. of Purch. Invoices"; Integer)
        {
            Caption = 'No. of Purchase Invoices';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Purchase Header" where("Document Type" = const(Invoice), "BVR Doc Batch No." = field("Code")));
        }
        field(11; "No. of Posted Purch. Inv."; Integer)
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

    var
        ClosedBatchErr: Label 'Batch %1 is closed, so its posting date can no longer be changed. Reopen the batch first.', Comment = '%1 = batch code';

    // Closes the batch once nothing is left in it to post. Called at the end of a successful batch
    // post; runs inside that same transaction, so if the batch post is rolled back the close goes
    // with it. Returns whether it actually closed the batch.   //AAV.SP
    procedure CloseIfComplete(): Boolean
    var
        BatchDocMgt: Codeunit "BVR Batch Doc Mgt";
    begin
        if Status = Status::Closed then
            exit(false);
        if not BatchDocMgt.PurchBatchIsEmpty(Enum::"Purchase Document Type"::Invoice, "Code") then
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
        exit(BatchDocMgt.PurchDocTotal(Enum::"Purchase Document Type"::Invoice, "Code"));
    end;
}
