codeunit 50149 "BVR Purch Inv Batch Post"
{
    // Posts every selected Purchase Invoice of a batch as ONE all-or-nothing unit: if any invoice
    // fails, nothing is posted. Invoice counterpart of "BVR Whse Rcpt Batch Post" - see that
    // codeunit for the full rationale.
    //
    // No Commit in the loop, and SetSuppressCommit on "Purch.-Post" so the base routine does not
    // make each invoice durable as it goes. The first failure raises an error naming the invoice,
    // which unwinds the whole transaction.
    //
    // TableNo is "Purchase Header" so this codeunit can run ITSELF once per invoice: that is what
    // lets us report WHICH invoice broke while still applying SetSuppressCommit to the instance that
    // actually posts.   //AAV.SP
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        PurchPost: Codeunit "Purch.-Post";
    begin
        // The batch is atomic - nothing may become durable until every invoice has succeeded.
        PurchPost.SetSuppressCommit(true);
        Rec.Receive := true;
        Rec.Invoice := true;
        PurchPost.Run(Rec);
    end;

    procedure PostInvoices(var PurchaseHeader: Record "Purchase Header")
    var
        PurchHeaderToPost: Record "Purchase Header";
        SelfPost: Codeunit "BVR Purch Inv Batch Post";
        InvoiceNos: List of [Code[20]];
        InvoiceNo: Code[20];
        BatchCodes: List of [Code[20]];
        PostedCount: Integer;
    begin
        // Snapshot first: a posted invoice is deleted from "Purchase Header", so iterating the
        // recordset would walk a cursor over rows disappearing underneath it.
        if PurchaseHeader.FindSet() then
            repeat
                InvoiceNos.Add(PurchaseHeader."No.");
                // Remembered now: the invoice - and with it the batch no. - is gone after posting.
                if (PurchaseHeader."BVR Doc Batch No." <> '') and not BatchCodes.Contains(PurchaseHeader."BVR Doc Batch No.") then
                    BatchCodes.Add(PurchaseHeader."BVR Doc Batch No.");
            until PurchaseHeader.Next() = 0;

        if InvoiceNos.Count() = 0 then
            Error(NothingSelectedErr);

        foreach InvoiceNo in InvoiceNos do begin
            if not PurchHeaderToPost.Get(PurchHeaderToPost."Document Type"::Invoice, InvoiceNo) then
                Error(BatchRolledBackErr, InvoiceNo, GoneErr);

            Clear(SelfPost);
            if not SelfPost.Run(PurchHeaderToPost) then
                Error(BatchRolledBackErr, InvoiceNo, GetLastErrorText());

            PostedCount += 1;
        end;

        CloseCompletedBatches(BatchCodes, PostedCount);
    end;

    // A batch whose last document has just posted is closed, which also takes it out of the Batch No.
    // lookups. Inside the same transaction as the post, so a rollback undoes the close too.   //AAV.SP
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
        NothingSelectedErr: Label 'Select at least one purchase invoice to post.';
        GoneErr: Label 'The purchase invoice no longer exists.';
        AllPostedMsg: Label '%1 purchase invoice(s) posted.', Comment = '%1 = number of invoices posted';
        PostedAndClosedMsg: Label '%1 purchase invoice(s) posted.\%2 batch(es) had no documents left and have been closed.', Comment = '%1 = number of invoices posted, %2 = number of batches closed';
        BatchRolledBackErr: Label 'Batch posting stopped at purchase invoice %1:\%2\\No invoices have been posted - the whole batch was rolled back. Correct the problem and post the batch again.', Comment = '%1 = purchase invoice no., %2 = the underlying posting error';
}
