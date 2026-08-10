codeunit 50147 "BVR Whse Rcpt Batch Post"
{
    // Posts every selected Warehouse Receipt of a batch as ONE all-or-nothing unit: if any receipt
    // fails, nothing is posted.
    //
    // Two things make that work, and both are required:
    //   * no Commit anywhere in the loop, so the whole run stays inside a single write transaction;
    //   * SetSuppressCommit on "Whse.-Post Receipt", because the base posting routine commits per
    //     document by default - without this, earlier receipts would already be durable and could
    //     not be rolled back.
    // The first failure raises an error naming the document, which unwinds the entire transaction.
    //
    // TableNo is "Warehouse Receipt Line" so this codeunit can run ITSELF once per receipt. That is
    // what lets us catch the failure and report WHICH document broke, while still applying
    // SetSuppressCommit / SetHideValidationDialog to the instance that actually posts - Codeunit.Run
    // always creates a fresh instance, so the flags could not otherwise be set on it.   //AAV.SP
    TableNo = "Warehouse Receipt Line";

    trigger OnRun()
    var
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
    begin
        // Suppressed so a 20-receipt batch does not raise 20 separate confirmation dialogs.
        WhsePostReceipt.SetHideValidationDialog(true);
        // The batch is atomic - nothing may become durable until every receipt has succeeded.
        WhsePostReceipt.SetSuppressCommit(true);
        WhsePostReceipt.Run(Rec);
    end;

    procedure PostReceipts(var WhseRcptHeader: Record "Warehouse Receipt Header")
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        SelfPost: Codeunit "BVR Whse Rcpt Batch Post";
        ReceiptNos: List of [Code[20]];
        ReceiptNo: Code[20];
        BatchCodes: List of [Code[20]];
        PostedCount: Integer;
    begin
        // Snapshot the numbers first. A posted Warehouse Receipt is deleted (codeunit "BVR Whse
        // Receipt Mgt" removes it even on a partial receipt), so iterating the recordset would be
        // walking a cursor over rows being deleted underneath it.
        if WhseRcptHeader.FindSet() then
            repeat
                ReceiptNos.Add(WhseRcptHeader."No.");
                // Remembered now: the receipt - and with it the batch no. - is gone after posting.
                if (WhseRcptHeader."BVR Batch No." <> '') and not BatchCodes.Contains(WhseRcptHeader."BVR Batch No.") then
                    BatchCodes.Add(WhseRcptHeader."BVR Batch No.");
            until WhseRcptHeader.Next() = 0;

        if ReceiptNos.Count() = 0 then
            Error(NothingSelectedErr);

        foreach ReceiptNo in ReceiptNos do begin
            WhseRcptLine.Reset();
            WhseRcptLine.SetRange("No.", ReceiptNo);
            if not WhseRcptLine.FindFirst() then
                Error(BatchRolledBackErr, ReceiptNo, NoLinesErr);

            Clear(SelfPost);
            if not SelfPost.Run(WhseRcptLine) then
                Error(BatchRolledBackErr, ReceiptNo, GetLastErrorText());

            PostedCount += 1;
        end;

        CloseCompletedBatches(BatchCodes, PostedCount);
    end;

    // A batch whose last document has just posted is closed, which also takes it out of the Batch No.
    // lookups. Inside the same transaction as the post, so a rollback undoes the close too.   //AAV.SP
    local procedure CloseCompletedBatches(BatchCodes: List of [Code[20]]; PostedCount: Integer)
    var
        DocBatch: Record "BVR Purch Rcpt Batch";
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
        NothingSelectedErr: Label 'Select at least one warehouse receipt to post.';
        NoLinesErr: Label 'The warehouse receipt has no lines.';
        AllPostedMsg: Label '%1 warehouse receipt(s) posted.', Comment = '%1 = number of receipts posted';
        PostedAndClosedMsg: Label '%1 warehouse receipt(s) posted.\%2 batch(es) had no documents left and have been closed.', Comment = '%1 = number of receipts posted, %2 = number of batches closed';
        BatchRolledBackErr: Label 'Batch posting stopped at warehouse receipt %1:\%2\\No receipts have been posted - the whole batch was rolled back. Correct the problem and post the batch again.', Comment = '%1 = warehouse receipt no., %2 = the underlying posting error';
}
