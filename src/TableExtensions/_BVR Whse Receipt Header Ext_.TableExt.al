tableextension 50122 "BVR Whse Receipt Header Ext" extends "Warehouse Receipt Header"
{
    // Step 1 of the Warehouse-Receipt approval flow. Carries the accrual accounts and the
    // single user-facing status onto the standard Warehouse Receipt document, so the AP /
    // approval flow (Open -> Sent to AP Team -> Pending Approval -> Released) can run on the
    // WR itself and posting can be gated until it is Released.   //AAV
    //
    // "BVR Requires Approval" marks a WR as belonging to this flow. Standard warehouse
    // receipts leave it false and post exactly as before - the posting gate only bites on
    // flow documents.   //AAV
    fields
    {
        field(50100; "BVR Vendor Accrual Acc No."; Code[20])
        {
            Caption = 'Vendor Accrual Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }
        field(50101; "BVR Expense Accrual Acc No."; Code[20])
        {
            Caption = 'Expense Accrual Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account"."No.";
        }
        // Reuses the same enum as the PO-based custom receipt flow (enum 50101).   //AAV
        field(50102; "BVR Receipt Status"; Enum "BVR Receipt Status")
        {
            Caption = 'Receipt Status';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50103; "BVR Requires Approval"; Boolean)
        {
            Caption = 'Requires Approval';
            DataClassification = CustomerContent;
        }
        field(50104; "BVR Sent To AP Team"; Boolean)
        {
            Caption = 'Sent To AP Team';
            DataClassification = CustomerContent;
            Editable = false;
        }
        // The two GLOBAL dimensions, captured on the Warehouse Receipt and pushed onto the source
        // Purchase Order header(s) when the receipt is posted (see codeunit "BVR Whse Receipt Mgt").
        // Plain shortcut codes - the Warehouse Receipt has no Dimension Set ID of its own, so the
        // TableRelation (filtered on the global dimension no., blocked values excluded) is the whole
        // validation. The real dimension set is built on the PO, by standard code.
        // CaptionClass '1,2,n' makes the captions follow the dimension names configured in General
        // Ledger Setup, exactly as on the Purchase Order.   //AAV.SP
        field(50105; "BVR Shortcut Dimension 1 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 1 Code';
            CaptionClass = '1,2,1';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
        }
        field(50106; "BVR Shortcut Dimension 2 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 2 Code';
            CaptionClass = '1,2,2';
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
        }
        // Set by the AP team while the receipt is Sent to AP Team, from the batch lookup (which also
        // allows creating a new batch inline). Carried onto the Posted Purchase Receipt by codeunit
        // "BVR Whse Receipt Mgt" when the WR posts.   //AAV.SP
        //
        // ValidateTableRelation is OFF so an unknown code reaches OnValidate, which offers to create
        // the batch rather than erroring - see "BVR Batch Doc Mgt".   //AAV.SP
        field(50107; "BVR Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            DataClassification = CustomerContent;
            ValidateTableRelation = false;
            TableRelation = "BVR Purch Rcpt Batch"."Code" where(Status = const(Open));

            trigger OnValidate()
            var
                BatchDocMgt: Codeunit "BVR Batch Doc Mgt";
            begin
                BatchDocMgt.CheckOrCreateWhseRcptBatch("BVR Batch No.");
            end;
        }
        // Typed on the Warehouse Receipt and pushed onto the source Purchase Order(s) just before the
        // receipt posts, by codeunit "BVR Whse Receipt Mgt" - it lands in the order's STANDARD
        // "Posting Description", which "Purch. Rcpt. Header" also holds at field 22. Purch.-Post
        // copies the two with TransferFields, so it reaches the Posted Purchase Receipt with no
        // posting code of ours at all, and shows there under its normal caption.
        //
        // Text[100] to match "Posting Description" exactly; anything longer would be silently cut off
        // on the way through.   //AAV.SP
        field(50108; "BVR Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
            DataClassification = CustomerContent;
        }
    }

    // What this receipt is about to bring in, in LCY.
    //
    // Calculated rather than stored. A Warehouse Receipt holds no amounts of its own - its lines
    // carry quantities only - so the value has to be read from the purchase lines behind them:
    // Qty. to Receive at the order's unit cost, less any line discount. Storing it would mean
    // keeping a field in step with every line insert, quantity change and deletion; reading it on
    // demand cannot go stale.
    //
    // Only Purchase Order lines count. A receipt line from any other source document has no purchase
    // amount to read, and is passed over rather than guessed at.
    //
    // Converted to LCY per source order, so that a batch total holds up when its orders are in
    // different currencies.   //AAV.SP
    procedure BVRCalcAmount(): Decimal
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        CurrExchRate: Record "Currency Exchange Rate";
        LineAmount: Decimal;
        Total: Decimal;
        ConversionDate: Date;
    begin
        WhseRcptLine.SetRange("No.", Rec."No.");
        WhseRcptLine.SetRange("Source Document", WhseRcptLine."Source Document"::"Purchase Order");
        if not WhseRcptLine.FindSet() then
            exit(0);

        repeat
            if PurchLine.Get(PurchLine."Document Type"::Order, WhseRcptLine."Source No.", WhseRcptLine."Source Line No.") then begin
                LineAmount := Round(
                    PurchLine."Direct Unit Cost" * WhseRcptLine."Qty. to Receive" *
                    (1 - PurchLine."Line Discount %" / 100));

                if PurchLine."Currency Code" <> '' then
                    if PurchHeader.Get(PurchHeader."Document Type"::Order, PurchLine."Document No.") then begin
                        // A blank posting date would make the exchange-rate lookup fail; the order is
                        // not posted yet, so today's rate is the honest stand-in.
                        ConversionDate := PurchHeader."Posting Date";
                        if ConversionDate = 0D then
                            ConversionDate := WorkDate();
                        LineAmount := Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                                ConversionDate, PurchHeader."Currency Code", LineAmount, PurchHeader."Currency Factor"));
                    end;

                Total += LineAmount;
            end;
        until WhseRcptLine.Next() = 0;

        exit(Total);
    end;
}
