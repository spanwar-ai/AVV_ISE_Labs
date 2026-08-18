tableextension 50123 "BVR Sales Header Ext" extends "Sales Header"
{
    // Sales side of the document-batch process: a Sales Invoice or Sales Credit Memo is put into a
    // batch and posted from the batch pages together with the rest of it, exactly as the purchase
    // documents are.   //AAV.SP
    fields
    {
        // One field serves both document types. The relation is conditional on "Document Type", so an
        // invoice can only go in an Invoice batch and a credit memo only in a Credit Memo batch - the
        // lookup itself enforces it, with no validation code to keep in step. Sales orders and
        // shipments are not batched at all.
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
            TableRelation = if ("Document Type" = const(Invoice)) "BVR Sales Inv Batch"."Code" where(Status = const(Open))
            else
            if ("Document Type" = const("Credit Memo")) "BVR Sales CrMemo Batch"."Code" where(Status = const(Open));

            trigger OnValidate()
            var
                BatchDocMgt: Codeunit "BVR Batch Doc Mgt";
            begin
                BatchDocMgt.CheckOrCreateSalesBatch("Document Type", "BVR Doc Batch No.");
            end;
        }
    }
}
