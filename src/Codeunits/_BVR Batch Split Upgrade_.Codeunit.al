codeunit 50155 "BVR Batch Split Upgrade"
{
    // Moves existing batches out of the old shared "BVR Doc Batch" table into the five per-process
    // tables that replaced it.
    //
    // This has to run, and has to run before anyone opens a document. Every Warehouse Receipt,
    // Purchase Invoice, Credit Memo and Sales document already carries a Batch No., and those fields
    // now point at the new tables. Without the copy the codes would still be there but would resolve
    // to nothing - the documents would look batched while their batches did not exist.
    //
    // Copy, not move: the old table is left untouched, marked obsolete rather than emptied. If
    // anything about the split turns out to be wrong, the original rows are still there to read.
    //
    // Re-runnable. Each row is only inserted when it is not already present, so running the upgrade
    // twice - which BC will do if the extension is reinstalled - cannot duplicate or overwrite a batch
    // whose Status has since moved on.   //AAV.SP
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        SplitDocBatches();
    end;

    // Also exposed as an action so it can be run by hand on a company that was upgraded before this
    // codeunit existed.   //AAV.SP
    procedure SplitDocBatches()
    var
        DocBatch: Record "BVR Doc Batch";
        RcptBatch: Record "BVR Purch Rcpt Batch";
        InvBatch: Record "BVR Purch Inv Batch";
        PurchCrMemoBatch: Record "BVR Purch CrMemo Batch";
        SalesShptBatch: Record "BVR Sales Shpt Batch";
        SalesCrMemoBatch: Record "BVR Sales CrMemo Batch";
    begin
        if not DocBatch.FindSet() then
            exit;

        repeat
            case DocBatch.Type of
                DocBatch.Type::Receipt:
                    if not RcptBatch.Get(DocBatch."Code") then begin
                        RcptBatch.Init();
                        RcptBatch."Code" := DocBatch."Code";
                        RcptBatch.Description := DocBatch.Description;
                        RcptBatch.Status := DocBatch.Status;
                        RcptBatch.Insert();
                    end;
                DocBatch.Type::"Purchase Invoice":
                    if not InvBatch.Get(DocBatch."Code") then begin
                        InvBatch.Init();
                        InvBatch."Code" := DocBatch."Code";
                        InvBatch.Description := DocBatch.Description;
                        InvBatch.Status := DocBatch.Status;
                        InvBatch.Insert();
                    end;
                DocBatch.Type::"Purch. Credit Memo":
                    if not PurchCrMemoBatch.Get(DocBatch."Code") then begin
                        PurchCrMemoBatch.Init();
                        PurchCrMemoBatch."Code" := DocBatch."Code";
                        PurchCrMemoBatch.Description := DocBatch.Description;
                        PurchCrMemoBatch.Status := DocBatch.Status;
                        PurchCrMemoBatch.Insert();
                    end;
                // The old Sales Order batches become Sales Shipment batches: the sales side now batches
                // the Warehouse Shipment rather than the order. The batch codes carry over as they
                // are - what changed is which documents hang off them.   //AAV.SP
                DocBatch.Type::"Sales Order":
                    if not SalesShptBatch.Get(DocBatch."Code") then begin
                        SalesShptBatch.Init();
                        SalesShptBatch."Code" := DocBatch."Code";
                        SalesShptBatch.Description := DocBatch.Description;
                        SalesShptBatch.Status := DocBatch.Status;
                        SalesShptBatch.Insert();
                    end;
                DocBatch.Type::"Sales Credit Memo":
                    if not SalesCrMemoBatch.Get(DocBatch."Code") then begin
                        SalesCrMemoBatch.Init();
                        SalesCrMemoBatch."Code" := DocBatch."Code";
                        SalesCrMemoBatch.Description := DocBatch.Description;
                        SalesCrMemoBatch.Status := DocBatch.Status;
                        SalesCrMemoBatch.Insert();
                    end;
            end;
        until DocBatch.Next() = 0;
    end;
}
