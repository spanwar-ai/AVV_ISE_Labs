codeunit 50240 "BVR Receipt Approval Mgt"
{
    procedure MarkAPUpdated(var PurchHdr: Record "Purchase Header")
    begin
        PurchHdr.TestField("Document Type", PurchHdr."Document Type"::Order);
        PurchHdr.TestField("BVR Receive PO", true);
        PurchHdr.TestField(Status, PurchHdr.Status::Released);
        PurchHdr."BVR AP Updated":=true;
        PurchHdr.Modify(true);
    end;
    procedure SendForApproval(var PurchHdr: Record "Purchase Header")
    var
        NoSeriesMgt: Codeunit "No. Series";
        Setup: Record "Purchases & Payables Setup";
    begin
        PurchHdr.TestField("Document Type", PurchHdr."Document Type"::Order);
        PurchHdr.TestField("BVR Receive PO", true);
        PurchHdr.TestField(Status, PurchHdr.Status::Released);
        PurchHdr.TestField("BVR Requires Approval", true);
        PurchHdr.TestField("BVR AP Updated", true);
        // Assign batch no if missing
        Setup.Get();
        Setup.TestField("Posted Receipt Nos.");
        if PurchHdr."BVR Batch No." = '' then PurchHdr."BVR Batch No.":=NoSeriesMgt.GetNextNo(Setup."Posted Receipt Nos.", WorkDate(), true);
        PurchHdr."BVR Sent For Approval":=true;
        PurchHdr."BVR Approved":=false;
        PurchHdr.Modify(true);
    end;
    procedure Approve(var PurchHdr: Record "Purchase Header")
    begin
        PurchHdr.TestField("Document Type", PurchHdr."Document Type"::Order);
        PurchHdr.TestField("BVR Receive PO", true);
        PurchHdr.TestField("BVR Sent For Approval", true);
        PurchHdr."BVR Approved":=true;
        PurchHdr.Modify(true);
    end;
    procedure SendBack(var PurchHdr: Record "Purchase Header")
    var
        ReopenCU: Codeunit "Purchase Manual Reopen";
    begin
        PurchHdr.TestField("Document Type", PurchHdr."Document Type"::Order);
        PurchHdr.TestField("BVR Receive PO", true);
        PurchHdr."BVR Sent For Approval":=false;
        PurchHdr."BVR Approved":=false;
        PurchHdr."BVR AP Updated":=false;
        PurchHdr.Modify(true);
        if PurchHdr.Status = PurchHdr.Status::Released then ReopenCU.Run(PurchHdr);
    end;
}
