codeunit 50246 "BVR Vendor Inv No Mgt"
{
    // Enforces that a Vendor Invoice No. is used only once on Custom Purchase
    // Receipts: it may not duplicate another open custom receipt for the same
    // vendor, nor a vendor invoice that has already been posted to the vendor
    // ledger.   //AAV.SP

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterValidateEvent', 'Vendor Invoice No.', false, false)]   //AAV.SP
    local procedure OnAfterValidateVendorInvoiceNo(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header")   //AAV.SP
    begin
        if Rec.IsTemporary() then   //AAV.SP
            exit;                    //AAV.SP
        CheckVendorInvoiceNoUnique(Rec);   //AAV.SP
    end;

    procedure CheckVendorInvoiceNoUnique(var PurchaseHeader: Record "Purchase Header")   //AAV.SP
    var
        OtherPurchaseHeader: Record "Purchase Header";   //AAV.SP
        VendorLedgerEntry: Record "Vendor Ledger Entry";   //AAV.SP
    begin
        if not IsCustomReceipt(PurchaseHeader) then   //AAV.SP
            exit;                                     //AAV.SP
        if PurchaseHeader."Vendor Invoice No." = '' then   //AAV.SP
            exit;                                          //AAV.SP

        // Another OPEN custom receipt for the same vendor already uses it.   //AAV.SP
        OtherPurchaseHeader.SetRange("Document Type", OtherPurchaseHeader."Document Type"::Order);   //AAV.SP
        OtherPurchaseHeader.SetRange("BVR Receive PO", true);                                        //AAV.SP
        OtherPurchaseHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");    //AAV.SP
        OtherPurchaseHeader.SetRange("Vendor Invoice No.", PurchaseHeader."Vendor Invoice No.");      //AAV.SP
        OtherPurchaseHeader.SetFilter("No.", '<>%1', PurchaseHeader."No.");                           //AAV.SP
        if not OtherPurchaseHeader.IsEmpty() then                                                     //AAV.SP
            Error(DuplicateOpenErr, PurchaseHeader."Vendor Invoice No.", PurchaseHeader."Buy-from Vendor No.", OtherPurchaseHeader."No.");   //AAV.SP

        // It has already been posted to the vendor ledger.   //AAV.SP
        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Pay-to Vendor No.");                 //AAV.SP
        VendorLedgerEntry.SetRange("External Document No.", PurchaseHeader."Vendor Invoice No.");     //AAV.SP
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);      //AAV.SP
        if not VendorLedgerEntry.IsEmpty() then                                                       //AAV.SP
            Error(DuplicatePostedErr, PurchaseHeader."Vendor Invoice No.", PurchaseHeader."Pay-to Vendor No.");   //AAV.SP
    end;

    local procedure IsCustomReceipt(var PurchaseHeader: Record "Purchase Header"): Boolean   //AAV.SP
    begin
        exit((PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order) and PurchaseHeader."BVR Receive PO");   //AAV.SP
    end;

    var
        DuplicateOpenErr: Label 'Vendor Invoice No. %1 is already used by vendor %2 on open Custom Purchase Receipt %3.', Comment = '%1 = vendor invoice no., %2 = vendor no., %3 = document no.';   //AAV.SP
        DuplicatePostedErr: Label 'Vendor Invoice No. %1 has already been posted for vendor %2 and cannot be used again.', Comment = '%1 = vendor invoice no., %2 = vendor no.';   //AAV.SP
}
