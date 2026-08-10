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
        // Superseded, along with the sales-order batch it came from. The sales batch is now held on
        // the Warehouse Shipment, so a posted sales invoice has no batch to inherit - and could not
        // have one anyway, since an invoice can combine shipments out of several different batches.
        // The batch is shown on the Posted Sales Shipment instead.
        //
        // Kept rather than dropped so any value already written survives.   //AAV.SP
        field(50124; "BVR Doc Batch No."; Code[20])
        {
            Caption = 'Batch No. (old)';
            DataClassification = CustomerContent;
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'The sales batch is held on the Warehouse Shipment and reported on the Posted Sales Shipment.';
        }
    }
}

// Tagged as well as the invoice, because a Sales Order posted Ship-only produces a shipment and no
// invoice at all - without this the batch would lose sight of it entirely.   //AAV.SP
tableextension 50126 "BVR Sales Shpt Hdr Ext" extends "Sales Shipment Header"
{
    fields
    {
        // Field 50110, matching "BVR Batch No." on "Purch. Rcpt. Header", and deliberately NOT 50124.
        // The batch lives on the WAREHOUSE SHIPMENT, not on the sales order, so there is nothing for
        // Sales-Post's TransferFields to carry - codeunit "BVR Whse Shipment Mgt" stamps it as each
        // shipment is created. Reusing 50124 would let the sales order's own batch field overwrite it.
        field(50110; "BVR Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "BVR Sales Shpt Batch"."Code";
        }
        // Superseded by 50110 above, when the sales batch moved from the order to the warehouse
        // shipment. Kept rather than dropped so any value already written survives.   //AAV.SP
        field(50124; "BVR Doc Batch No."; Code[20])
        {
            Caption = 'Batch No. (old)';
            DataClassification = CustomerContent;
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'The sales batch is now held on the Warehouse Shipment; use "BVR Batch No." (50110).';
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
