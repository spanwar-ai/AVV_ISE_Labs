table 50180 "BVR GL Dim Correction"
{
    // Staging table for a bulk dimension correction on POSTED G/L entries.
    //
    // The shape is deliberate: one row per G/L entry, holding the dimension values that entry SHOULD
    // have carried. Load it (paste from Excel, or Import from File), look at it, then press Process.
    // Nothing is written to the G/L until Process runs, so a bad upload costs nothing but a Delete.
    //
    // Why a table of our own rather than BC's "Dimension Correction" document: that feature corrects a
    // SET of entries to the SAME value - its changes are keyed by dimension code, not by entry - so
    // ten thousand entries each needing their own value would mean building and running a correction
    // document per distinct value combination. Here the value travels with the entry, which is how the
    // data arrives from the business. The G/L update itself mirrors what codeunit "Dim Correction Run"
    // does, entry for entry.   //AAV.SP
    //
    // The primary key is the G/L Entry No. on purpose. One entry cannot be staged twice, so two rows
    // disagreeing about what a single entry should become is not a state this table can reach.
    Caption = 'G/L Dimension Correction';
    DataClassification = CustomerContent;
    LookupPageId = "BVR GL Dim Corrections";
    DrillDownPageId = "BVR GL Dim Corrections";

    fields
    {
        field(1; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            NotBlank = true;
            TableRelation = "G/L Entry"."Entry No.";

            trigger OnValidate()
            begin
                TestNotProcessed();
            end;
        }
        // Blank means "leave this dimension exactly as the entry has it" - never "clear it". Clearing
        // is a separate, deliberate tick below, because a blank cell in a spreadsheet of ten thousand
        // rows is far more often "not my column" than "remove the dimension".   //AAV.SP
        field(10; "New Global Dim 1 Code"; Code[20])
        {
            Caption = 'New Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));

            trigger OnValidate()
            begin
                TestNotProcessed();
                if "New Global Dim 1 Code" <> '' then
                    "Clear Global Dim 1" := false;
                ResetStatus();
            end;
        }
        field(11; "New Global Dim 2 Code"; Code[20])
        {
            Caption = 'New Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                TestNotProcessed();
                if "New Global Dim 2 Code" <> '' then
                    "Clear Global Dim 2" := false;
                ResetStatus();
            end;
        }
        field(12; "Clear Global Dim 1"; Boolean)
        {
            Caption = 'Clear Global Dimension 1';

            trigger OnValidate()
            begin
                TestNotProcessed();
                if "Clear Global Dim 1" then
                    "New Global Dim 1 Code" := '';
                ResetStatus();
            end;
        }
        field(13; "Clear Global Dim 2"; Boolean)
        {
            Caption = 'Clear Global Dimension 2';

            trigger OnValidate()
            begin
                TestNotProcessed();
                if "Clear Global Dim 2" then
                    "New Global Dim 2 Code" := '';
                ResetStatus();
            end;
        }
        field(20; Status; Enum "BVR GL Dim Corr Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(21; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            Editable = false;
        }
        // What the entry looked like before Process touched it. This is the whole undo story: with the
        // old set ID kept per row, Revert is a straight write-back rather than a reconstruction, and it
        // stays right even if those dimension values were later reused for something else.   //AAV.SP
        field(30; "Previous Dimension Set ID"; Integer)
        {
            Caption = 'Previous Dimension Set ID';
            Editable = false;
        }
        field(31; "Previous Global Dim 1 Code"; Code[20])
        {
            Caption = 'Previous Global Dimension 1 Code';
            Editable = false;
        }
        field(32; "Previous Global Dim 2 Code"; Code[20])
        {
            Caption = 'Previous Global Dimension 2 Code';
            Editable = false;
        }
        field(33; "New Dimension Set ID"; Integer)
        {
            Caption = 'New Dimension Set ID';
            Editable = false;
        }
        field(40; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
            Editable = false;
        }
        field(41; "Processed By"; Code[50])
        {
            Caption = 'Processed By';
            Editable = false;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        // Read straight off the entry so the team can check they staged what they meant to before
        // pressing Process. All FlowFields - nothing here is stored, so nothing here can go stale or
        // disagree with the ledger.   //AAV.SP
        field(50; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Entry"."Posting Date" where("Entry No." = field("G/L Entry No.")));
        }
        field(51; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Entry"."Document No." where("Entry No." = field("G/L Entry No.")));
        }
        field(52; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Entry"."G/L Account No." where("Entry No." = field("G/L Entry No.")));
        }
        field(53; "Entry Description"; Text[100])
        {
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Entry".Description where("Entry No." = field("G/L Entry No.")));
        }
        field(54; Amount; Decimal)
        {
            Caption = 'Amount';
            Editable = false;
            AutoFormatType = 1;
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Entry".Amount where("Entry No." = field("G/L Entry No.")));
        }
        field(55; "Current Global Dim 1 Code"; Code[20])
        {
            Caption = 'Current Global Dimension 1 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Entry"."Global Dimension 1 Code" where("Entry No." = field("G/L Entry No.")));
        }
        field(56; "Current Global Dim 2 Code"; Code[20])
        {
            Caption = 'Current Global Dimension 2 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Entry"."Global Dimension 2 Code" where("Entry No." = field("G/L Entry No.")));
        }
    }

    keys
    {
        key(PK; "G/L Entry No.")
        {
            Clustered = true;
        }
        // Validate, Process and Revert all work a Status filter over a table that is meant to hold
        // tens of thousands of rows, so it is worth an index of its own.   //AAV.SP
        key(Status; Status, "G/L Entry No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "G/L Entry No.", "New Global Dim 1 Code", "New Global Dim 2 Code", Status)
        {
        }
    }

    trigger OnDelete()
    begin
        // Deleting a processed row throws away the only record of what the entry looked like before,
        // and with it any chance of reverting. Revert first, or use Delete Processed Lines once the
        // correction is accepted - that action says out loud what this would do quietly.   //AAV.SP
        if Status = Status::Processed then
            Error(DeleteProcessedErr, "G/L Entry No.");
    end;

    // A processed row is the record of a change already made to the ledger, and the "previous" values
    // on it are the only way back. Editing it would leave those values describing a correction that no
    // longer matches the row - so the row is frozen until it is reverted.   //AAV.SP
    local procedure TestNotProcessed()
    begin
        if Status = Status::Processed then
            Error(ProcessedLineErr, "G/L Entry No.");
    end;

    // Any edit puts the row back to Pending: a Validated mark is only worth anything while it still
    // describes what the row says now.   //AAV.SP
    local procedure ResetStatus()
    begin
        if Status in [Status::Validated, Status::Failed] then begin
            Status := Status::Pending;
            "Error Message" := '';
        end;
    end;

    var
        ProcessedLineErr: Label 'G/L Entry %1 has already been corrected. Revert the line before changing it.', Comment = '%1 = G/L Entry No.';
        DeleteProcessedErr: Label 'G/L Entry %1 has already been corrected. Use Revert to undo it, or Delete Processed Lines to clear it from this list.', Comment = '%1 = G/L Entry No.';
}
