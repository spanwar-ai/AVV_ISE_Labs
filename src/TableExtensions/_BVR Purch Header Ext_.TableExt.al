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
