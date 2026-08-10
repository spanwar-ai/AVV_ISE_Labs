tableextension 50123 "BVR Sales Header Ext" extends "Sales Header"
{
    // Sales side of the document-batch process: a Sales Order or Sales Credit Memo is put into a
    // batch and posted from the batch pages together with the rest of it, exactly as purchase
    // invoices are.   //AAV.SP
    fields
    {
        // One field serves both document types. The relation is conditional on "Document Type", so only a
        // credit memo can be batched here. Sales ORDERS are not batched on the order at all - their
        // batch lives on the Warehouse Shipment, mirroring how the purchase side batches the
        // Warehouse Receipt rather than the purchase order.
        //
        // Field 50124 to match "Purchase Header", and to match the posted sales tables below, so that
        // Sales-Post's TransferFields carries the batch onto the posted document with no extra
        // posting code - the same trick the purchase side relies on.   //AAV.SP
        //
        // ValidateTableRelation is OFF for the same reason as on "Purchase Header": the automatic
        // check errors on a code that does not exist yet, so the check is made by hand in OnValidate,
        // which can offer to create the batch first.   //AAV.SP
        field(50124; "BVR Doc Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            DataClassification = CustomerContent;
            ValidateTableRelation = false;
            TableRelation = if ("Document Type" = const("Credit Memo")) "BVR Sales CrMemo Batch"."Code" where(Status = const(Open));

            trigger OnValidate()
            var
                BatchDocMgt: Codeunit "BVR Batch Doc Mgt";
            begin
                BatchDocMgt.CheckOrCreateSalesBatch("Document Type", "BVR Doc Batch No.");
            end;
        }
    }
}
