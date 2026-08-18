codeunit 50153 "BVR Sales Batch Post"
{
    // Posts every selected sales document of a batch as ONE all-or-nothing unit: if any document
    // fails, nothing is posted. Serves Sales Credit Memo batches - the only sales documents batched.
    // Sales counterpart of "BVR Purch Inv Batch Post" - see that codeunit, and
    // "BVR Whse Rcpt Batch Post", for the full rationale.
    //
    // No Commit in the loop, and SetSuppressCommit on "Sales-Post" so the base routine does not make
    // each document durable as it goes. The first failure raises an error naming the document, which
    // unwinds the whole transaction.
    //
    // TableNo is "Sales Header" so this codeunit can run ITSELF once per document: that is what lets
    // us report WHICH document broke while still applying SetSuppressCommit to the instance that
    // actually posts.   //AAV.SP
    TableNo = "Sales Header";

    trigger OnRun()
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        // The batch is atomic - nothing may become durable until every document has succeeded.
        SalesPost.SetSuppressCommit(true);
        // Copied field for field from "Sales-Post (Yes/No)", so a batched document posts on exactly
        // the same terms as one posted from its own page.
        //
        // Ship is true for an INVOICE and a CREDIT MEMO as well as an order - which is not obvious,
        // and getting it wrong is silent. On the sales side Ship is what makes posting produce the
        // shipment or, for a credit memo, the return receipt that "Return Receipt on Credit Memo" in
        // Sales & Receivables Setup asks for. With Ship false, a batched credit memo would post its
        // ledger entries and quietly skip the return receipt that the same credit memo posted from
        // its own page would have created.   //AAV.SP
        Rec.Receive := Rec."Document Type" = Rec."Document Type"::"Return Order";
        Rec.Ship := Rec."Document Type" in [Rec."Document Type"::Order,
                                            Rec."Document Type"::Invoice,
                                            Rec."Document Type"::"Credit Memo"];
        Rec.Invoice := true;
        SalesPost.Run(Rec);
    end;

    procedure PostDocuments(var SalesHeader: Record "Sales Header")
    var
        TempDocToPost: Record "Sales Header" temporary;
        SalesHeaderToPost: Record "Sales Header";
        SelfPost: Codeunit "BVR Sales Batch Post";
        BatchCodes: List of [Code[20]];
        PostedCount: Integer;
    begin
        // Snapshot first. A fully posted document is deleted from "Sales Header", so iterating the
        // recordset would walk a cursor over rows disappearing underneath it. The snapshot keeps the
        // Document Type as well as the number, so orders and credit memos can both be re-read.
        if SalesHeader.FindSet() then
            repeat
                TempDocToPost := SalesHeader;
                TempDocToPost.Insert();
                // Remembered now: the document - and with it the batch no. - is gone after posting.
                if (SalesHeader."BVR Doc Batch No." <> '') and not BatchCodes.Contains(SalesHeader."BVR Doc Batch No.") then
                    BatchCodes.Add(SalesHeader."BVR Doc Batch No.");
            until SalesHeader.Next() = 0;

        if not TempDocToPost.FindSet() then
            Error(NothingSelectedErr);

        repeat
            if not SalesHeaderToPost.Get(TempDocToPost."Document Type", TempDocToPost."No.") then
                Error(BatchRolledBackErr, TempDocToPost."No.", GoneErr);

            ApplyBatchPostingDate(SalesHeaderToPost);

            Clear(SelfPost);
            if not SelfPost.Run(SalesHeaderToPost) then
                Error(BatchRolledBackErr, TempDocToPost."No.", GetLastErrorText());

            PostedCount += 1;
        until TempDocToPost.Next() = 0;

        CloseCompletedBatches(TempDocToPost."Document Type", BatchCodes, PostedCount);
    end;

    // The batch's posting date, where it has one, is forced onto the document before it posts, so a
    // batch books as ONE accounting event whatever dates the documents were entered with. Validate
    // rather than a plain assignment: the base trigger re-reads the currency exchange rate for the
    // new date and moves the document date with it where the setup links the two - all of which a
    // straight assignment would silently skip.
    //
    // Inside the batch transaction, so a rolled-back batch takes the date change with it. A batch
    // with no posting date changes nothing - every document keeps its own.   //AAV.SP
    local procedure ApplyBatchPostingDate(var SalesHeader: Record "Sales Header")
    var
        InvBatch: Record "BVR Sales Inv Batch";
        CrMemoBatch: Record "BVR Sales CrMemo Batch";
        BatchPostingDate: Date;
    begin
        if SalesHeader."BVR Doc Batch No." = '' then
            exit;

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                if InvBatch.Get(SalesHeader."BVR Doc Batch No.") then
                    BatchPostingDate := InvBatch."Posting Date";
            SalesHeader."Document Type"::"Credit Memo":
                if CrMemoBatch.Get(SalesHeader."BVR Doc Batch No.") then
                    BatchPostingDate := CrMemoBatch."Posting Date";
        end;

        if BatchPostingDate = 0D then
            exit;
        if SalesHeader."Posting Date" = BatchPostingDate then
            exit;

        SalesHeader.Validate("Posting Date", BatchPostingDate);
        SalesHeader.Modify(true);
    end;

    // A batch whose last document has just posted is closed, which also takes it out of the Batch No.
    // lookups. Inside the same transaction as the post, so a rollback undoes the close too.
    //
    // A Sales Order posted with a partial quantity stays in "Sales Header", so it stays in the batch
    // and the batch stays open - which is right: there is still something there to post.   //AAV.SP
    //
    // The document type decides WHICH batch table to close. Invoices and credit memos keep their
    // batches in separate tables and the same code can exist on both, so closing the wrong one would
    // shut a batch that still has documents in it.   //AAV.SP
    local procedure CloseCompletedBatches(DocType: Enum "Sales Document Type"; BatchCodes: List of [Code[20]]; PostedCount: Integer)
    var
        InvBatch: Record "BVR Sales Inv Batch";
        CrMemoBatch: Record "BVR Sales CrMemo Batch";
        BatchCode: Code[20];
        ClosedCount: Integer;
    begin
        foreach BatchCode in BatchCodes do
            case DocType of
                DocType::Invoice:
                    if InvBatch.Get(BatchCode) then
                        if InvBatch.CloseIfComplete() then
                            ClosedCount += 1;
                DocType::"Credit Memo":
                    if CrMemoBatch.Get(BatchCode) then
                        if CrMemoBatch.CloseIfComplete() then
                            ClosedCount += 1;
            end;

        if ClosedCount > 0 then
            Message(PostedAndClosedMsg, PostedCount, ClosedCount)
        else
            Message(AllPostedMsg, PostedCount);
    end;

    var
        NothingSelectedErr: Label 'Select at least one sales document to post.';
        GoneErr: Label 'The sales document no longer exists.';
        AllPostedMsg: Label '%1 sales document(s) posted.', Comment = '%1 = number of documents posted';
        PostedAndClosedMsg: Label '%1 sales document(s) posted.\%2 batch(es) had no documents left and have been closed.', Comment = '%1 = number of documents posted, %2 = number of batches closed';
        BatchRolledBackErr: Label 'Batch posting stopped at sales document %1:\%2\\Nothing has been posted - the whole batch was rolled back. Correct the problem and post the batch again.', Comment = '%1 = sales document no., %2 = the underlying posting error';
}
