table 50150 "BVR PO Line Buffer"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Select"; Boolean)
        {
            Caption = 'Select';
        }
        field(2; "PO No."; Code[20])
        {
            Caption = 'PO No.';
        }
        field(3; "PO Line No."; Integer)
        {
            Caption = 'PO Line No.';
        }
        field(4; Type;Enum "Purchase Line Type")
        {
            Caption = 'Type';
        }
        field(5; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
        }
        field(8; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0: 5;
        }
        field(9; "Quantity Received"; Decimal)
        {
            Caption = 'Quantity Received';
            DecimalPlaces = 0: 5;
        }
        field(10; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0: 5;
        }
        field(11; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            DecimalPlaces = 0: 5;
        }
        field(12; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
        }
    }
    keys
    {
        key(PK; "PO No.", "PO Line No.")
        {
            Clustered = true;
        }
    }
}
