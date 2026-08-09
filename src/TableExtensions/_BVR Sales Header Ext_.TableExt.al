tableextension 50123 "BVR Sales Header Ext" extends "Sales Header"
{
    // Sales side of the document-batch process: a Sales Order or Sales Credit Memo is put into a
    // batch and posted from the batch pages together with the rest of it, exactly as purchase
    // invoices are.   //AAV.SP
    fields
    {
        // One field serves both document types. The relation is conditional on "Document Type", so an
        // order can only be put in a Sales Order batch and a credit memo only in a Sales Credit Memo
        // batch - the lookup itself enforces it, with no validation code to keep in step.
        //
        // Field 50124 to match "Purchase Header", and to match the posted sales tables below, so that
        // Sales-Post's TransferFields carries the batch onto the posted document with no extra
        // posting code - the same trick the purchase side relies on.   //AAV.SP
        field(50124; "BVR Doc Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            DataClassification = CustomerContent;
            TableRelation = if ("Document Type" = const(Order)) "BVR Doc Batch"."Code" where(Type = const("Sales Order"), Status = const(Open))
            else
            if ("Document Type" = const("Credit Memo")) "BVR Doc Batch"."Code" where(Type = const("Sales Credit Memo"), Status = const(Open));
        }
    }
}
