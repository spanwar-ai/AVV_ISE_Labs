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
}
