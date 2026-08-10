tableextension 50128 "BVR Whse Shipment Header Ext" extends "Warehouse Shipment Header"
{
    // Sales mirror of "BVR Whse Receipt Header Ext". The shipment batch works on the WAREHOUSE
    // SHIPMENT, not on the sales order behind it - the same way the receipt batch works on the
    // Warehouse Receipt rather than the purchase order. Posting a batch of warehouse shipments
    // produces the Posted Sales Shipments, which is what the batch then reports on.   //AAV.SP
    fields
    {
        // Field 50107 to match "BVR Batch No." on "Warehouse Receipt Header" exactly, so the two
        // sides of the process read the same way.   //AAV.SP
        //
        // ValidateTableRelation is OFF so an unknown code reaches OnValidate, which offers to create
        // the batch rather than erroring - see "BVR Batch Doc Mgt".   //AAV.SP
        field(50107; "BVR Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            DataClassification = CustomerContent;
            ValidateTableRelation = false;
            TableRelation = "BVR Sales Shpt Batch"."Code" where(Status = const(Open));

            trigger OnValidate()
            var
                BatchDocMgt: Codeunit "BVR Batch Doc Mgt";
            begin
                BatchDocMgt.CheckOrCreateWhseShptBatch("BVR Batch No.");
            end;
        }
    }

    // What this shipment is about to send out, in LCY.
    //
    // Calculated, not stored, for the same reason as on the receipt side: a Warehouse Shipment holds
    // no amounts of its own, only quantities, so the value has to be read from the sales lines behind
    // them - Qty. to Ship at the order's unit price, less any line discount. Reading it on demand
    // cannot go stale; a stored field would have to be kept in step with every line change.
    //
    // Only Sales Order lines count. A shipment line from any other source document - a transfer, a
    // service order - has no sales amount to read, and is passed over rather than guessed at.
    //
    // Converted to LCY per source order, so a batch total holds up when its orders are in different
    // currencies.   //AAV.SP
    procedure BVRCalcAmount(): Decimal
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        BatchDocMgt: Codeunit "BVR Batch Doc Mgt";
        LineAmount: Decimal;
        Total: Decimal;
    begin
        WhseShptLine.SetRange("No.", Rec."No.");
        WhseShptLine.SetRange("Source Document", WhseShptLine."Source Document"::"Sales Order");
        if not WhseShptLine.FindSet() then
            exit(0);

        repeat
            if SalesLine.Get(SalesLine."Document Type"::Order, WhseShptLine."Source No.", WhseShptLine."Source Line No.") then begin
                LineAmount := Round(
                    SalesLine."Unit Price" * WhseShptLine."Qty. to Ship" *
                    (1 - SalesLine."Line Discount %" / 100));

                if SalesLine."Currency Code" <> '' then
                    if SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.") then
                        LineAmount := BatchDocMgt.ToLCY(
                            LineAmount, SalesHeader."Currency Code", SalesHeader."Currency Factor", SalesHeader."Posting Date");

                Total += LineAmount;
            end;
        until WhseShptLine.Next() = 0;

        exit(Total);
    end;
}
