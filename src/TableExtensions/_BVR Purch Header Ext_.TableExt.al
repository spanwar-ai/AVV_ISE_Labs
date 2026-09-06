tableextension 50110 "BVR Purch Header Ext" extends "Purchase Header"
{
    fields
    {
        field(50100; "BVR Receive PO"; Boolean)
        {
            Caption = 'Receive PO';
            DataClassification = CustomerContent;
        }
        field(50101; "BVR Custom Rcpt Posted"; Boolean)
        {
            Caption = 'Custom Receipt Posted';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50102; "BVR Posted Rcpt No."; Code[20])
        {
            Caption = 'Posted Receipt No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50103; "BVR Vendor Accrual Acc No."; Code[20])
        {
            Caption = 'Vendor Accrual Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }
        field(50104; "BVR Expense Accrual Acc No."; Code[20])
        {
            Caption = 'Expense Accrual Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }
        field(50105; "BVR Custom Inv Posted"; Boolean)
        {
            Caption = 'Custom Invoice Posted';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50106; "BVR Posted Inv No."; Code[20])
        {
            Caption = 'Posted Invoice No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        // Global dimensions carried over from the Warehouse Receipt, stamped by codeunit "BVR Whse
        // Receipt Mgt" just before the receipt posts. They are DELIBERATELY separate from the order's
        // own "Shortcut Dimension 1/2 Code": the PO's real dimensions - and its Dimension Set ID, and
        // its lines - are never touched by the warehouse flow. Only the accrual entry posted by
        // codeunit "BVR Std Rcpt Accrual" is dimensioned from these.
        //
        // Numbered 50108/50109, NOT 50107: Purch. Rcpt. Header 50107 is "BVR Source Whse Receipt No.",
        // and Purch.-Post copies header fields with TransferFields, which matches by field NUMBER -
        // reusing 50107 here would silently overwrite the receipt's WR number.   //AAV.SP
        field(50108; "BVR WH Shortcut Dim 1 Code"; Code[20])
        {
            Caption = 'Warehouse Shortcut Dimension 1 Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
        }
        field(50109; "BVR WH Shortcut Dim 2 Code"; Code[20])
        {
            Caption = 'Warehouse Shortcut Dimension 2 Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
        }
        // The Vendor Accrual account's own dimensions, from the Warehouse Receipt. Kept apart from the
        // two above, which dimension the EXPENSE side of the same accrual entry.
        //
        // 50111/50112 deliberately match on "Purchase Header" and "Purch. Rcpt. Header", the way
        // 50108/50109 do: Purch.-Post's TransferFields copies by field NUMBER, and that is the whole
        // mechanism carrying these onto the posted receipt for "BVR Undo Receipt Accrual" to reverse
        // under.   //AAV.SP
        field(50111; "BVR Vendor Accrual Dim 1 Code"; Code[20])
        {
            Caption = 'Vendor Accrual Dimension 1 Code';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50112; "BVR Vendor Accrual Dim 2 Code"; Code[20])
        {
            Caption = 'Vendor Accrual Dimension 2 Code';
            DataClassification = CustomerContent;
            Editable = false;
        }
        // P2: Grouping + batch
        field(50120; "BVR Group No."; Code[20])
        {
            Caption = 'Group Number';
            DataClassification = CustomerContent;
        }
        field(50121; "BVR Batch No."; Code[20])
        {
            Caption = 'Batch Number';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50122; "BVR Custom Invoice No."; code[20])
        {
            Caption = 'Custom Invoice Number';
            DataClassification = CustomerContent;
        }
        // AP batch on the Purchase Invoice, assigned by the AP team and used by the Purchase Invoice
        // Batch pages to post a batch of invoices together.
        // NOTE: this is NOT field 50121 "BVR Batch No." above - that one is a legacy no.-series
        // stamp written by the superseded codeunit "BVR Receipt Approval Mgt" and still shown on the
        // custom receipt page. The two are unrelated; see the note in the batch documentation before
        // consolidating them.
        // Same number and type as on "Purch. Inv. Header" (50124) so Purch.-Post's
        // TransferFields(PurchHeader) carries it onto the posted invoice.   //AAV.SP
        // One field serves both document types. The relation is conditional on "Document Type", so an
        // invoice can only be put in an Invoice batch and a credit memo only in a Credit Memo batch -
        // the lookup itself enforces it, with no validation code to keep in step.   //AAV.SP
        // ValidateTableRelation is OFF on purpose. The automatic check errors on a code that does not
        // exist yet, which leaves no room to offer to create it - so the check is made by hand in
        // OnValidate instead, which asks first and rejects the value if the answer is no. The relation
        // is still what drives the lookup.   //AAV.SP
        field(50124; "BVR Doc Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            DataClassification = CustomerContent;
            ValidateTableRelation = false;
            TableRelation = if ("Document Type" = const(Invoice)) "BVR Purch Inv Batch"."Code" where(Status = const(Open))
            else
            if ("Document Type" = const("Credit Memo")) "BVR Purch CrMemo Batch"."Code" where(Status = const(Open));

            trigger OnValidate()
            var
                BatchDocMgt: Codeunit "BVR Batch Doc Mgt";
            begin
                BatchDocMgt.CheckOrCreatePurchBatch("Document Type", "BVR Doc Batch No.");
            end;
        }
        // Stamped by codeunit "BVR Purch Doc Mgt" when the order is created from a Blanket
        // Purchase Order via Make Order. Held at header level because BC only tracks the blanket
        // order per LINE ("Blanket Order No." on Purchase Line).
        // Deliberately the same number/type as on "Purch. Rcpt. Header" (50123) so both
        // Purch.-Post and "BVR Custom Rcpt Post V2" carry it to the posted receipt through their
        // TransferFields call, with no extra posting code.   //AAV.SP
        field(50123; "BVR Blanket Order No."; Code[20])
        {
            Caption = 'Blanket Order No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Purchase Header"."No." where("Document Type" = const("Blanket Order"));
        }

    }
    /*  trigger OnInsert()
         begin
             // Only default for Custom Receipt Orders
             if ("Document Type" = "Document Type"::Order) then begin
                 if not "BVR Receive PO" then
                     "BVR Receive PO" := true;
             end
         end; */
}
