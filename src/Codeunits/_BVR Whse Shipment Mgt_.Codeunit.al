codeunit 50157 "BVR Whse Shipment Mgt"
{
    // Carries the batch from a Warehouse Shipment onto the Posted Sales Shipments it produces.
    //
    // The purchase side gets this for free: its batch sits on the purchase order, and Purch.-Post
    // copies header fields onto the posted receipt with TransferFields. Nothing equivalent happens
    // here - the batch is on the WAREHOUSE SHIPMENT, which is not the record Sales-Post transfers
    // from - so the value has to be carried across by hand.
    //
    // How: the batch is captured when "Whse.-Post Shipment" picks up its header, and stamped onto each
    // Sales Shipment Header as it is inserted. SingleInstance so the value captured at the first step
    // survives to the second within the same post.
    //
    // The stamp is gated on a non-blank captured batch, and the capture is cleared once the post ends.
    // That matters because the insert subscriber fires for EVERY sales shipment in the system,
    // including ones posted straight off a sales order with no warehouse involved - those must be left
    // alone.   //AAV.SP
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnCodeOnAfterGetWhseShptHeader', '', false, false)]
    local procedure CaptureBatchOnPost(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        CurrentBatchNo := WarehouseShipmentHeader."BVR Batch No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Shipment Header", 'OnAfterInsertEvent', '', false, false)]
    local procedure StampBatchOnSalesShipment(var Rec: Record "Sales Shipment Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        if CurrentBatchNo = '' then
            exit;
        if Rec."BVR Batch No." = CurrentBatchNo then
            exit;

        Rec."BVR Batch No." := CurrentBatchNo;
        Rec.Modify();
    end;

    // Cleared as the post finishes, so a batch can never leak onto a sales shipment posted later in
    // the same session by some other route.   //AAV.SP
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnAfterRun', '', false, false)]
    local procedure ClearBatchAfterPost()
    begin
        CurrentBatchNo := '';
    end;

    // OnAfterRun does NOT fire when the post fails, and a rollback does not undo a SingleInstance
    // variable - so a failed batch post would leave the batch captured, and the very next sales
    // shipment posted by ANY route in that session would be stamped with it. The batch poster calls
    // this on its way out of a failure to close that window.   //AAV.SP
    procedure ClearCapturedBatch()
    begin
        CurrentBatchNo := '';
    end;

    var
        CurrentBatchNo: Code[20];
}
