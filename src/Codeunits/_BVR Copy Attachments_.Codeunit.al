codeunit 50320 "BVR Copy Attachments"
{
    Permissions = tabledata "Document Attachment" = rimd;

    procedure CopyReceiptAttachments(SourcePurchHdr: Record "Purchase Header"; PostedRcptHdr: Record "Purch. Rcpt. Header")
    var
        DocAtt: Record "Document Attachment";
    begin
        // Copy attachments from Custom Receipt (Purchase Header) to Posted Receipt
        DocAtt.SetRange("Table ID", Database::"Purchase Header");
        DocAtt.SetRange("No.", SourcePurchHdr."No.");
        if DocAtt.FindSet() then
            repeat
                InsertCopy(DocAtt, PostedRcptHdr."No.");
            until DocAtt.Next() = 0;
    end;

    // Copy every attachment on a Warehouse Receipt (table 7316) onto the posted Purchase Receipt.
    // Called once per posted receipt during Whse.-Post Receipt, so a WR spanning several POs copies
    // its documents onto each resulting posted receipt. The WR is deleted after posting, so this is
    // the copy half of a MOVE - the source rows are removed by DeleteWhseReceiptAttachments.   //AAV.SP
    procedure CopyWhseReceiptAttachmentsToPosted(WhseReceiptNo: Code[20]; PostedRcptHdr: Record "Purch. Rcpt. Header")
    var
        DocAtt: Record "Document Attachment";
        ExistingAtt: Record "Document Attachment";
    begin
        if WhseReceiptNo = '' then
            exit;
        DocAtt.SetRange("Table ID", Database::"Warehouse Receipt Header");
        DocAtt.SetRange("No.", WhseReceiptNo);
        if DocAtt.FindSet() then
            repeat
                // Skip anything already copied to this receipt (e.g. a re-entrant post), so the same
                // file is not attached twice.   //AAV.SP
                ExistingAtt.SetRange("Table ID", Database::"Purch. Rcpt. Header");
                ExistingAtt.SetRange("No.", PostedRcptHdr."No.");
                ExistingAtt.SetRange("File Name", DocAtt."File Name");
                ExistingAtt.SetRange("File Extension", DocAtt."File Extension");
                if ExistingAtt.IsEmpty() then
                    InsertCopy(DocAtt, PostedRcptHdr."No.");
            until DocAtt.Next() = 0;
    end;

    // Inserts one copy of SourceAtt on the posted receipt.
    //
    // The copy is built in a record that is CLEARED, not Init-ed, on every call. Init() resets every
    // field EXCEPT the primary key, and ID - an AutoIncrement field - is part of that key. Re-using one
    // record across a loop with Init() therefore carried the ID the first insert was given into the
    // second, and AutoIncrement only assigns a number when the value is 0. The second attachment on a
    // receipt collided with the first ("The record in table Document Attachment already exists ...
    // ID='159'"), and in a batch that rolled back every receipt in it.
    //
    // A fresh record per copy leaves ID at 0, so the table hands out a new one each time. Document
    // Type and Line No. stay 0 as well: TransferFields(..., false) never copies the key, and a posted
    // receipt's attachments are header-level.   //AAV.SP
    local procedure InsertCopy(SourceAtt: Record "Document Attachment"; PostedRcptNo: Code[20])
    var
        NewAtt: Record "Document Attachment";
    begin
        NewAtt.TransferFields(SourceAtt, false);
        NewAtt."Table ID" := Database::"Purch. Rcpt. Header";
        NewAtt."No." := PostedRcptNo;
        NewAtt.ID := 0;
        NewAtt.Insert(true);
    end;

    // Remove the Warehouse Receipt's own attachment rows. Run when the WR is deleted after posting,
    // so the copied-forward documents do not leave orphaned rows behind (Warehouse Receipt Header
    // has no OnDelete that clears Document Attachment).   //AAV.SP
    procedure DeleteWhseReceiptAttachments(WhseReceiptNo: Code[20])
    var
        DocAtt: Record "Document Attachment";
    begin
        if WhseReceiptNo = '' then
            exit;
        DocAtt.SetRange("Table ID", Database::"Warehouse Receipt Header");
        DocAtt.SetRange("No.", WhseReceiptNo);
        if not DocAtt.IsEmpty() then
            DocAtt.DeleteAll(true);
    end;
}
