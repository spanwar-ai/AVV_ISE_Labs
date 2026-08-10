codeunit 50156 "BVR Whse Shpt Batch Post"
{
    // Posts every selected Warehouse Shipment of a batch as ONE all-or-nothing unit: if any shipment
    // fails, nothing is posted. Sales mirror of "BVR Whse Rcpt Batch Post" - see that codeunit for the
    // full rationale.
    //
    // No Commit anywhere in the loop, and SetSuppressCommit on "Whse.-Post Shipment" so the base
    // routine does not make each shipment durable as it goes. The first failure raises an error naming
    // the document, which unwinds the entire transaction.
    //
    // TableNo is "Warehouse Shipment Line" so this codeunit can run ITSELF once per shipment: that is
    // what lets us report WHICH shipment broke while still applying SetSuppressCommit to the instance
    // that actually posts.   //AAV.SP
    TableNo = "Warehouse Shipment Line";

    trigger OnRun()
    var
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
    begin
        // The batch is atomic - nothing may become durable until every shipment has succeeded.
        WhsePostShipment.SetSuppressCommit(true);
        WhsePostShipment.Run(Rec);
    end;

    procedure PostShipments(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        SelfPost: Codeunit "BVR Whse Shpt Batch Post";
        WhseShipmentMgt: Codeunit "BVR Whse Shipment Mgt";
        ShipmentNos: List of [Code[20]];
        ShipmentNo: Code[20];
        BatchCodes: List of [Code[20]];
        PostedCount: Integer;
    begin
        // Snapshot the numbers first. A fully posted Warehouse Shipment is deleted, so iterating the
        // recordset would walk a cursor over rows disappearing underneath it.
        if WhseShptHeader.FindSet() then
            repeat
                ShipmentNos.Add(WhseShptHeader."No.");
                // Remembered now: the shipment - and with it the batch no. - may be gone after posting.
                if (WhseShptHeader."BVR Batch No." <> '') and not BatchCodes.Contains(WhseShptHeader."BVR Batch No.") then
                    BatchCodes.Add(WhseShptHeader."BVR Batch No.");
            until WhseShptHeader.Next() = 0;

        if ShipmentNos.Count() = 0 then
            Error(NothingSelectedErr);

        foreach ShipmentNo in ShipmentNos do begin
            WhseShptLine.Reset();
            WhseShptLine.SetRange("No.", ShipmentNo);
            if not WhseShptLine.FindFirst() then
                Error(BatchRolledBackErr, ShipmentNo, NoLinesErr);

            Clear(SelfPost);
            // The captured batch is cleared before the error is raised. "Whse.-Post Shipment" clears
            // it itself on a successful run, but not on a failed one - and it lives in a SingleInstance
            // codeunit, which the rollback does not touch. Left set, it would be stamped onto whatever
            // sales shipment this session posted next.   //AAV.SP
            if not SelfPost.Run(WhseShptLine) then begin
                WhseShipmentMgt.ClearCapturedBatch();
                Error(BatchRolledBackErr, ShipmentNo, GetLastErrorText());
            end;

            PostedCount += 1;
        end;

        CloseCompletedBatches(BatchCodes, PostedCount);
    end;

    // A batch whose last shipment has just posted is closed, which also takes it out of the Batch No.
    // lookups. Inside the same transaction as the post, so a rollback undoes the close too.
    //
    // A Warehouse Shipment posted with a partial quantity stays put, so it stays in the batch and the
    // batch stays open - which is right: there is still something there to ship.   //AAV.SP
    local procedure CloseCompletedBatches(BatchCodes: List of [Code[20]]; PostedCount: Integer)
    var
        ShptBatch: Record "BVR Sales Shpt Batch";
        BatchCode: Code[20];
        ClosedCount: Integer;
    begin
        foreach BatchCode in BatchCodes do
            if ShptBatch.Get(BatchCode) then
                if ShptBatch.CloseIfComplete() then
                    ClosedCount += 1;

        if ClosedCount > 0 then
            Message(PostedAndClosedMsg, PostedCount, ClosedCount)
        else
            Message(AllPostedMsg, PostedCount);
    end;

    var
        NothingSelectedErr: Label 'Select at least one warehouse shipment to post.';
        NoLinesErr: Label 'The warehouse shipment has no lines.';
        AllPostedMsg: Label '%1 warehouse shipment(s) posted.', Comment = '%1 = number of shipments posted';
        PostedAndClosedMsg: Label '%1 warehouse shipment(s) posted.\%2 batch(es) had no documents left and have been closed.', Comment = '%1 = number of shipments posted, %2 = number of batches closed';
        BatchRolledBackErr: Label 'Batch posting stopped at warehouse shipment %1:\%2\\Nothing has been posted - the whole batch was rolled back. Correct the problem and post the batch again.', Comment = '%1 = warehouse shipment no., %2 = the underlying posting error';
}
