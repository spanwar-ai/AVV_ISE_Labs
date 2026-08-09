codeunit 50153 "BVR Sales Batch Post"
{
    // Posts every selected sales document of a batch as ONE all-or-nothing unit: if any document
    // fails, nothing is posted. Serves both Sales Order and Sales Credit Memo batches - the two
    // differ only in the posting flags, which are read from the document itself. Sales counterpart of
    // "BVR Purch Inv Batch Post" - see that codeunit, and "BVR Whse Rcpt Batch Post", for the full
    // rationale.
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
        // Exactly how "Sales-Post (Yes/No)" sets them, so a batched document posts on the same terms
        // as one posted from its own page: an order ships and invoices, a credit memo invoices only.
        Rec.Ship := Rec."Document Type" = Rec."Document Type"::Order;
        Rec.Receive := Rec."Document Type" = Rec."Document Type"::"Return Order";
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

            Clear(SelfPost);
            if not SelfPost.Run(SalesHeaderToPost) then
                Error(BatchRolledBackErr, TempDocToPost."No.", GetLastErrorText());

            PostedCount += 1;
        until TempDocToPost.Next() = 0;

        CloseCompletedBatches(BatchCodes, PostedCount);
    end;

    // A batch whose last document has just posted is closed, which also takes it out of the Batch No.
    // lookups. Inside the same transaction as the post, so a rollback undoes the close too.
    //
    // A Sales Order posted with a partial quantity stays in "Sales Header", so it stays in the batch
    // and the batch stays open - which is right: there is still something there to post.   //AAV.SP
    local procedure CloseCompletedBatches(BatchCodes: List of [Code[20]]; PostedCount: Integer)
    var
        DocBatch: Record "BVR Doc Batch";
        BatchCode: Code[20];
        ClosedCount: Integer;
    begin
        foreach BatchCode in BatchCodes do
            if DocBatch.Get(BatchCode) then
                if DocBatch.CloseIfComplete() then
                    ClosedCount += 1;

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
