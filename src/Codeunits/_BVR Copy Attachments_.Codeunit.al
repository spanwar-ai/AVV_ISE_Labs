codeunit 50320 "BVR Copy Attachments"
{
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
}
