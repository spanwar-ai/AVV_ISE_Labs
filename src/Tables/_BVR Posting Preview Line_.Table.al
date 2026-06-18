table 50250 "BVR Posting Preview Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionMembers = "G/L", "Receipt", Item, Invoice;
            OptionCaption = 'G/L,Receipt,Item,Invoice';
        }
        field(2; "Account/Doc"; Code[20])
        {
            Caption = 'Account/Doc';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Account Description';
        }
        field(4; Amount; Decimal)
        {
            Caption = 'Amount';
            DecimalPlaces = 0: 2;
        }
        field(5; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0: 5;
        }
        field(6; "Bal. Account"; Code[20])
        {
            Caption = 'Bal. Account';
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(9; "Debit/Credit"; Option)
        {
            Caption = 'Debit/Credit';
            OptionMembers = Debit, Credit, None;
            OptionCaption = 'Debit,Credit,None';
        }
        field(10; "Is Item Ledger"; Boolean)
        {
            Caption = 'Item Ledger Entry';
        }
        field(11; "Is Summary"; Boolean)
        {
            Caption = 'Summary Line';
        }
        field(12; "Item No"; Code[20])
        {
            Caption = 'Item No';
        }
        field(13; "Line Description"; Text[100])
        {
            Caption = 'Description';
        }
        field(14; "Source PO Quantity"; Decimal)
        {
            Caption = 'Source PO Quantity';
        }
        field(15; "Source PO Cost"; Decimal)
        {
            Caption = 'Source PO Cost';
        }
        field(16; "Source Dimension 1"; Code[20])
        {
            Caption = 'Cost Center';
        }
        field(17; "Source Dimension 2"; Code[20])
        {
            Caption = 'BU Code';
        }
    }
    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
