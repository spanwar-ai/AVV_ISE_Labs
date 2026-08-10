codeunit 50149 "BVR Purch Inv Batch Post"
{
    // Posts every selected purchase document of a batch as ONE all-or-nothing unit: if any document
    // fails, nothing is posted. Serves both Purchase Invoice and Purchase Credit Memo batches - the
    // two differ only in the posting flags, which are read from the document itself. Counterpart of
    // "BVR Whse Rcpt Batch Post" - see that codeunit for the full rationale.
    //
    // No Commit in the loop, and SetSuppressCommit on "Purch.-Post" so the base routine does not
    // make each document durable as it goes. The first failure raises an error naming the document,
    // which unwinds the whole transaction.
    //
    // TableNo is "Purchase Header" so this codeunit can run ITSELF once per document: that is what
    // lets us report WHICH document broke while still applying SetSuppressCommit to the instance that
    // actually posts.   //AAV.SP
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        PurchPost: Codeunit "Purch.-Post";
    begin
        // The batch is atomic - nothing may become durable until every document has succeeded.
        PurchPost.SetSuppressCommit(true);
        // Exactly how "Purch.-Post (Yes/No)" sets them, so a batched document posts on the same terms
        // as one posted from its own page. A credit memo receives nothing and ships nothing; it is
        // invoiced only.
        Rec.Ship := Rec."Document Type" = Rec."Document Type"::"Return Order";
        Rec.Receive := Rec."Document Type" = Rec."Document Type"::Order;
        Rec.Invoice := true;
        PurchPost.Run(Rec);
    end;

    procedure PostDocuments(var PurchaseHeader: Record "Purchase Header")
    var
        TempDocToPost: Record "Purchase Header" temporary;
        PurchHeaderToPost: Record "Purchase Header";
        SelfPost: Codeunit "BVR Purch Inv Batch Post";
        BatchCodes: List of [Code[20]];
        PostedCount: Integer;
    begin
        // Snapshot first: a posted document is deleted from "Purchase Header", so iterating the
        // recordset would walk a cursor over rows disappearing underneath it. The snapshot keeps the
        // Document Type as well as the number, so invoices and credit memos can both be re-read.
        if PurchaseHeader.FindSet() then
            repeat
                TempDocToPost := PurchaseHeader;
                TempDocToPost.Insert();
                // Remembered now: the document - and with it the batch no. - is gone after posting.
                if (PurchaseHeader."BVR Doc Batch No." <> '') and not BatchCodes.Contains(PurchaseHeader."BVR Doc Batch No.") then
                    BatchCodes.Add(PurchaseHeader."BVR Doc Batch No.");
            until PurchaseHeader.Next() = 0;

        if not TempDocToPost.FindSet() then
            Error(NothingSelectedErr);

        repeat
            if not PurchHeaderToPost.Get(TempDocToPost."Document Type", TempDocToPost."No.") then
                Error(BatchRolledBackErr, TempDocToPost."No.", GoneErr);

            Clear(SelfPost);
            if not SelfPost.Run(PurchHeaderToPost) then
                Error(BatchRolledBackErr, TempDocToPost."No.", GetLastErrorText());

            PostedCount += 1;
        until TempDocToPost.Next() = 0;

        CloseCompletedBatches(TempDocToPost."Document Type", BatchCodes, PostedCount);
    end;

    // A batch whose last document has just posted is closed, which also takes it out of the Batch No.
    // lookups. Inside the same transaction as the post, so a rollback undoes the close too.   //AAV.SP
    //
    // The document type decides WHICH batch table to close. Invoices and credit memos now keep their
    // batches in separate tables, and the same code can exist on both - closing the wrong one would
    // shut a batch that still has documents in it.   //AAV.SP
    local procedure CloseCompletedBatches(DocType: Enum "Purchase Document Type"; BatchCodes: List of [Code[20]]; PostedCount: Integer)
    var
        InvBatch: Record "BVR Purch Inv Batch";
        CrMemoBatch: Record "BVR Purch CrMemo Batch";
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
        NothingSelectedErr: Label 'Select at least one purchase document to post.';
        GoneErr: Label 'The purchase document no longer exists.';
        AllPostedMsg: Label '%1 purchase document(s) posted.', Comment = '%1 = number of documents posted';
        PostedAndClosedMsg: Label '%1 purchase document(s) posted.\%2 batch(es) had no documents left and have been closed.', Comment = '%1 = number of documents posted, %2 = number of batches closed';
        BatchRolledBackErr: Label 'Batch posting stopped at purchase document %1:\%2\\Nothing has been posted - the whole batch was rolled back. Correct the problem and post the batch again.', Comment = '%1 = purchase document no., %2 = the underlying posting error';
}
