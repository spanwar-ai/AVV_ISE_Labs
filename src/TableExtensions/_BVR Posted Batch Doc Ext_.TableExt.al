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
            TableRelation = "BVR Purch CrMemo Batch"."Code";
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
            TableRelation = "BVR Sales Inv Batch"."Code";
        }
    }
}

// Both fields are obsolete: there is no sales shipment batch process. 50124 came from the original
// design, where the batch sat on the sales order; 50110 from the design that replaced it, where the
// batch sat on the warehouse shipment. Neither is written any more.
//
// Kept rather than dropped so whatever either of them already holds survives - a posted shipment is
// a record of something that happened, and the batch it came out of is part of that record.   //AAV.SP
tableextension 50126 "BVR Sales Shpt Hdr Ext" extends "Sales Shipment Header"
{
    fields
    {
        field(50110; "BVR Batch No."; Code[20])
        {
            Caption = 'Batch No. (old)';
            DataClassification = CustomerContent;
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'The sales shipment batch process has been removed.';
        }
        field(50124; "BVR Doc Batch No."; Code[20])
        {
            Caption = 'Batch No. (old)';
            DataClassification = CustomerContent;
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'The sales shipment batch process has been removed.';
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
            TableRelation = "BVR Sales CrMemo Batch"."Code";
        }
    }
}
