codeunit 50132 "BVR Whse Rcpt Doc Attach"
{
    // Makes the standard Document Attachment framework understand two tables that Microsoft's
    // "Document Attachment Mgmt" does NOT list in its hardcoded table maps:
    //   * Warehouse Receipt Header (7316) - so the Attachments factbox on the WR works.
    //   * Purch. Rcpt. Header      (122)  - so the Attachments factbox on the POSTED receipt works,
    //                                       both for the documents copied forward when the WR posts
    //                                       and for any file a user attaches on the posted receipt.
    //
    // Without this, uploading through the "Doc. Attachment List Factbox" fails with "The record is
    // not open." - the factbox calls GetRefTable, which returns a never-opened RecordRef for these
    // tables, and SaveAttachment then throws on it. (Merely DISPLAYING already-saved rows works
    // without this glue, because the factbox just filters Document Attachment by Table ID + No.;
    // it is upload / view-single / send-as-email that need the ref.)
    //
    // Two extension points cover the whole lifecycle:
    //   OnAfterGetRefTable                  -> open + fetch the record so upload / view / email work.
    //   OnAfterTableHasNumberFieldPrimaryKey-> tell InitFieldsFromRecRef which field is the "No."
    //                                          key, so the saved row is stamped and shows up.
    // "No." is field 1 on Warehouse Receipt Header and field 3 on Purch. Rcpt. Header.   //AAV.SP

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterGetRefTable', '', false, false)]
    local procedure OnAfterGetRefTable(var RecRef: RecordRef; DocumentAttachment: Record "Document Attachment")
    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        // GetRefTable only checks RecRef.Number > 0 for success, so opening the ref is what matters;
        // Get() may legitimately fail for an already-deleted record, leaving an open-but-empty ref -
        // the same shape the base app produces for its own tables.   //AAV.SP
        case DocumentAttachment."Table ID" of
            Database::"Warehouse Receipt Header":
                begin
                    RecRef.Open(Database::"Warehouse Receipt Header");
                    if WhseReceiptHeader.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(WhseReceiptHeader);
                end;
            Database::"Purch. Rcpt. Header":
                begin
                    RecRef.Open(Database::"Purch. Rcpt. Header");
                    if PurchRcptHeader.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(PurchRcptHeader);
                end;
        end;
    end;

    // Declare the "No." primary-key field so InitFieldsFromRecRef stamps "Document Attachment"."No."
    // from the record - otherwise it saves blank and the factbox (SubPageLink "No." = field("No."))
    // never shows it.   //AAV.SP
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Attachment Mgmt", 'OnAfterTableHasNumberFieldPrimaryKey', '', false, false)]
    local procedure OnAfterTableHasNumberFieldPrimaryKey(TableNo: Integer; var Result: Boolean; var FieldNo: Integer)
    begin
        case TableNo of
            Database::"Warehouse Receipt Header":
                begin
                    FieldNo := 1;   // "No."
                    Result := true;
                end;
            Database::"Purch. Rcpt. Header":
                begin
                    FieldNo := 3;   // "No."
                    Result := true;
                end;
        end;
    end;
}
