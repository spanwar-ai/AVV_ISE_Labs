table 50152 "BVR Batch Cue"
{
    // Feeds the batch tiles on the Business Manager Role Center.
    //
    // A cue table holds no data of its own - a single blank-key record exists purely so the FlowFields
    // below have something to hang off. The counts are calculated on every page refresh, so the tiles
    // can never drift out of step with the batches.
    //
    // Every tile counts OPEN batches only. A closed batch has had its last document posted and needs
    // nothing from anyone, so counting it would leave a number on the Role Center that never goes
    // down.   //AAV.SP
    Caption = 'Batch Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(10; "Purchase Receipt Batches"; Integer)
        {
            Caption = 'Purchase Receipt Batches';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("BVR Purch Rcpt Batch" where(Status = const(Open)));
        }
        field(11; "Purchase Invoice Batches"; Integer)
        {
            Caption = 'Purchase Invoice Batches';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("BVR Purch Inv Batch" where(Status = const(Open)));
        }
        field(12; "Purchase Cr. Memo Batches"; Integer)
        {
            Caption = 'Purchase Credit Memo Batches';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("BVR Purch CrMemo Batch" where(Status = const(Open)));
        }
        field(13; "Sales Invoice Batches"; Integer)
        {
            Caption = 'Sales Invoice Batches';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("BVR Sales Inv Batch" where(Status = const(Open)));
        }
        field(14; "Sales Cr. Memo Batches"; Integer)
        {
            Caption = 'Sales Credit Memo Batches';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("BVR Sales CrMemo Batch" where(Status = const(Open)));
        }
        // Documents actually waiting on someone. A batch with nothing released in it is open but idle,
        // so the batch tiles alone cannot tell a manager whether there is work to do - these can.
        // Released only, matching what the batch pages list and what Post Whole Batch would post.
        field(20; "Whse. Receipts to Post"; Integer)
        {
            Caption = 'Warehouse Receipts to Post';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Warehouse Receipt Header" where("BVR Batch No." = filter(<> ''),
                                                                  "BVR Receipt Status" = const(Released)));
        }
        field(21; "Purch. Documents to Post"; Integer)
        {
            Caption = 'Purchase Documents to Post';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Purchase Header" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                         "BVR Doc Batch No." = filter(<> ''),
                                                         Status = const(Released)));
        }
        field(22; "Sales Documents to Post"; Integer)
        {
            Caption = 'Sales Documents to Post';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Sales Header" where("Document Type" = filter(Invoice | "Credit Memo"),
                                                      "BVR Doc Batch No." = filter(<> ''),
                                                      Status = const(Released)));
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
