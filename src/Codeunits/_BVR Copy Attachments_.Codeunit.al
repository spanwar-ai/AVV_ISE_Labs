codeunit 50320 "BVR Copy Attachments"
{
    Permissions = tabledata "Document Attachment" = rimd;

    procedure CopyReceiptAttachments(SourcePurchHdr: Record "Purchase Header"; PostedRcptHdr: Record "Purch. Rcpt. Header")
    var
        DocAtt: Record "Document Attachment";
        NewAtt: Record "Document Attachment";
    begin
        // Copy attachments from Custom Receipt (Purchase Header) to Posted Receipt
        DocAtt.SetRange("Table ID", Database::"Purchase Header");
        DocAtt.SetRange("No.", SourcePurchHdr."No.");
        if DocAtt.FindSet()then repeat NewAtt.Init();
                NewAtt.TransferFields(DocAtt, false);
                NewAtt."Table ID":=Database::"Purch. Rcpt. Header";
                NewAtt."No.":=PostedRcptHdr."No.";
                NewAtt.Insert(true);
            until DocAtt.Next() = 0;
    end;

    // Copy every attachment on a Warehouse Receipt (table 7316) onto the posted Purchase Receipt.
    // Called once per posted receipt during Whse.-Post Receipt, so a WR spanning several POs copies
    // its documents onto each resulting posted receipt. The WR is deleted after posting, so this is
    // the copy half of a MOVE - the source rows are removed by DeleteWhseReceiptAttachments.   //AAV.SP
    procedure CopyWhseReceiptAttachmentsToPosted(WhseReceiptNo: Code[20]; PostedRcptHdr: Record "Purch. Rcpt. Header")
    var
        DocAtt: Record "Document Attachment";
        NewAtt: Record "Document Attachment";
    begin
        if WhseReceiptNo = '' then
            exit;
        DocAtt.SetRange("Table ID", Database::"Warehouse Receipt Header");
        DocAtt.SetRange("No.", WhseReceiptNo);
        if DocAtt.FindSet() then
            repeat
                // Skip anything already copied to this receipt (e.g. a re-entrant post), so the same
                // file is not attached twice.   //AAV.SP
                NewAtt.SetRange("Table ID", Database::"Purch. Rcpt. Header");
                NewAtt.SetRange("No.", PostedRcptHdr."No.");
                NewAtt.SetRange("File Name", DocAtt."File Name");
                NewAtt.SetRange("File Extension", DocAtt."File Extension");
                if NewAtt.IsEmpty() then begin
                    NewAtt.Init();
                    NewAtt.TransferFields(DocAtt, false);
                    NewAtt."Table ID" := Database::"Purch. Rcpt. Header";
                    NewAtt."No." := PostedRcptHdr."No.";
                    NewAtt.Insert(true);
                end;
            until DocAtt.Next() = 0;
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
