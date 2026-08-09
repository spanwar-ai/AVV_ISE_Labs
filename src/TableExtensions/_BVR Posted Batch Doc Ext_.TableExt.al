// The batch a document was posted from, carried onto every posted document the batch process can
// produce.
//
// Each of these is field 50124 - the same number and type as "BVR Doc Batch No." on "Purchase Header"
// and "Sales Header". That is the whole mechanism: Purch.-Post and Sales-Post copy the unposted
// header onto the posted one with TransferFields, which works by field NUMBER, so the batch arrives
// on the posted document without a line of posting code.
//
// All are Editable = false: the batch is a property of how the document was posted, and changing it
// afterwards would only make the posted record disagree with the batch it came out of.   //AAV.SP
tableextension 50124 "BVR Purch CrMemo Hdr Ext" extends "Purch. Cr. Memo Hdr."
{
    fields
    {
        field(50124; "BVR Doc Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "BVR Doc Batch"."Code" where(Type = const("Purch. Credit Memo"));
        }
    }
}

tableextension 50125 "BVR Sales Invoice Hdr Ext" extends "Sales Invoice Header"
{
    fields
    {
        field(50124; "BVR Doc Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "BVR Doc Batch"."Code" where(Type = const("Sales Order"));
        }
    }
}

// Tagged as well as the invoice, because a Sales Order posted Ship-only produces a shipment and no
// invoice at all - without this the batch would lose sight of it entirely.   //AAV.SP
tableextension 50126 "BVR Sales Shpt Hdr Ext" extends "Sales Shipment Header"
{
    fields
    {
        field(50124; "BVR Doc Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "BVR Doc Batch"."Code" where(Type = const("Sales Order"));
        }
    }
}

tableextension 50127 "BVR Sales CrMemo Hdr Ext" extends "Sales Cr.Memo Header"
{
    fields
    {
        field(50124; "BVR Doc Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "BVR Doc Batch"."Code" where(Type = const("Sales Credit Memo"));
        }
    }
}
