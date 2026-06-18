tableextension 50114 "BVR Purch Line Ext" extends "Purchase Line"
{
    fields
    {
        field(50100; "BVR From Custom Receipt"; Boolean)
        {
            Caption = 'From Custom Receipt';
            DataClassification = CustomerContent;
        }
        field(50101; "BVR Source Rcpt No."; Code[20])
        {
            Caption = 'Source Receipt No.';
            DataClassification = CustomerContent;
            TableRelation = "Purch. Rcpt. Header"."No.";
        }
        field(50102; "BVR Source Rcpt Line No."; Integer)
        {
            Caption = 'Source Receipt Line No.';
            DataClassification = CustomerContent;
        }
        // Link Custom Receipt line to released PO line
        field(50110; "BVR Source PO No."; Code[20])
        {
            Caption = 'Source PO No.';
            DataClassification = CustomerContent;
            TableRelation = "Purchase Header"."No." where("Document Type"=const(Order));
        }
        field(50111; "BVR Source PO Line No."; Integer)
        {
            Caption = 'Source PO Line No.';
            DataClassification = CustomerContent;
        }
        field(50112; "BVR Source PO Qty"; Decimal)
        {
            Caption = 'PO Quantity';
            DataClassification = CustomerContent;
            Editable = false;
            DecimalPlaces = 0: 5;
        }
        field(50113; "BVR Remaining Qty"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DataClassification = CustomerContent;
            Editable = false;
            DecimalPlaces = 0: 5;
        }
    }
}
