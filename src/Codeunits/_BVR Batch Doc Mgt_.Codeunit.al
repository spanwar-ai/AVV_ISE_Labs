codeunit 50154 "BVR Batch Doc Mgt"
{
    // Shared behaviour for the five batch tables.
    //
    // Each batch process now has its own table, so a batch code means one thing on one table and the
    // tables carry no Type field. What they DO share is how a batch is valued and when it is finished,
    // and that lives here rather than being copied five times.
    //
    // Every total is in LCY and counts RELEASED documents only - the same ones the batch pages list
    // and the same ones Post Whole Batch would post, so a batch total always ties back to the lines
    // on screen.   //AAV.SP

    procedure WhseRcptTotal(BatchCode: Code[20]) Total: Decimal
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
    begin
        FilterWhseRcpts(WhseRcptHeader, BatchCode, true);
        if WhseRcptHeader.FindSet() then
            repeat
                Total += WhseRcptHeader.BVRCalcAmount();
            until WhseRcptHeader.Next() = 0;
    end;

    procedure WhseShptTotal(BatchCode: Code[20]) Total: Decimal
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
    begin
        FilterWhseShpts(WhseShptHeader, BatchCode, true);
        if WhseShptHeader.FindSet() then
            repeat
                Total += WhseShptHeader.BVRCalcAmount();
            until WhseShptHeader.Next() = 0;
    end;

    procedure WhseShptBatchIsEmpty(BatchCode: Code[20]): Boolean
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
    begin
        FilterWhseShpts(WhseShptHeader, BatchCode, false);
        exit(WhseShptHeader.IsEmpty());
    end;

    // Released, not the AP receipt status: a Warehouse Shipment carries BC's own Open/Released status,
    // and only a Released one can be posted.   //AAV.SP
    procedure FilterWhseShpts(var WhseShptHeader: Record "Warehouse Shipment Header"; BatchCode: Code[20]; ReleasedOnly: Boolean)
    begin
        WhseShptHeader.Reset();
        WhseShptHeader.SetRange("BVR Batch No.", BatchCode);
        if ReleasedOnly then
            WhseShptHeader.SetRange(Status, WhseShptHeader.Status::Released);
    end;

    procedure PurchDocTotal(DocType: Enum "Purchase Document Type"; BatchCode: Code[20]) Total: Decimal
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        FilterPurchDocs(PurchaseHeader, DocType, BatchCode, true);
        if PurchaseHeader.FindSet() then
            repeat
                PurchaseHeader.CalcFields("Amount Including VAT");
                Total += ToLCY(
                    PurchaseHeader."Amount Including VAT", PurchaseHeader."Currency Code",
                    PurchaseHeader."Currency Factor", PurchaseHeader."Posting Date");
            until PurchaseHeader.Next() = 0;
    end;

    procedure SalesDocTotal(DocType: Enum "Sales Document Type"; BatchCode: Code[20]) Total: Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        FilterSalesDocs(SalesHeader, DocType, BatchCode, true);
        if SalesHeader.FindSet() then
            repeat
                SalesHeader.CalcFields("Amount Including VAT");
                Total += ToLCY(
                    SalesHeader."Amount Including VAT", SalesHeader."Currency Code",
                    SalesHeader."Currency Factor", SalesHeader."Posting Date");
            until SalesHeader.Next() = 0;
    end;

    // "Is anything left in this batch" - deliberately counting EVERY document, released or not. A
    // batch still holding an unreleased document is not finished, even though the batch pages, which
    // list released documents only, would look empty.   //AAV.SP
    procedure WhseRcptBatchIsEmpty(BatchCode: Code[20]): Boolean
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
    begin
        FilterWhseRcpts(WhseRcptHeader, BatchCode, false);
        exit(WhseRcptHeader.IsEmpty());
    end;

    procedure PurchBatchIsEmpty(DocType: Enum "Purchase Document Type"; BatchCode: Code[20]): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        FilterPurchDocs(PurchaseHeader, DocType, BatchCode, false);
        exit(PurchaseHeader.IsEmpty());
    end;

    procedure SalesBatchIsEmpty(DocType: Enum "Sales Document Type"; BatchCode: Code[20]): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        FilterSalesDocs(SalesHeader, DocType, BatchCode, false);
        exit(SalesHeader.IsEmpty());
    end;

    procedure FilterWhseRcpts(var WhseRcptHeader: Record "Warehouse Receipt Header"; BatchCode: Code[20]; ReleasedOnly: Boolean)
    begin
        WhseRcptHeader.Reset();
        WhseRcptHeader.SetRange("BVR Batch No.", BatchCode);
        if ReleasedOnly then
            WhseRcptHeader.SetRange("BVR Receipt Status", WhseRcptHeader."BVR Receipt Status"::Released);
    end;

    procedure FilterPurchDocs(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; BatchCode: Code[20]; ReleasedOnly: Boolean)
    begin
        PurchaseHeader.Reset();
        PurchaseHeader.SetRange("Document Type", DocType);
        PurchaseHeader.SetRange("BVR Doc Batch No.", BatchCode);
        if ReleasedOnly then
            PurchaseHeader.SetRange(Status, PurchaseHeader.Status::Released);
    end;

    procedure FilterSalesDocs(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; BatchCode: Code[20]; ReleasedOnly: Boolean)
    begin
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", DocType);
        SalesHeader.SetRange("BVR Doc Batch No.", BatchCode);
        if ReleasedOnly then
            SalesHeader.SetRange(Status, SalesHeader.Status::Released);
    end;

    // Batch No. entered on a document: check it, and offer to create the batch if it is new.
    //
    // A batch is a working label the AP/AR team invents as it goes - "AUG-W2", "VENDOR-QUERY" - so
    // making them leave the document, go to the batch list, create the code and come back is friction
    // for no gain. Typing a code that does not exist yet asks whether to create it.
    //
    // This is why the batch fields carry ValidateTableRelation = false: the automatic relation check
    // errors on an unknown code before any of this can run. The check is not lost, it is made here by
    // hand - a code that is not created is still rejected, so the field can never hold a batch that
    // does not exist.   //AAV.SP
    procedure CheckOrCreatePurchBatch(DocType: Enum "Purchase Document Type"; BatchCode: Code[20])
    var
        InvBatch: Record "BVR Purch Inv Batch";
        CrMemoBatch: Record "BVR Purch CrMemo Batch";
    begin
        if BatchCode = '' then
            exit;

        // Only the two document types that are batched. Any other type is left alone rather than
        // errored on: the field is not shown on those pages, and nothing of ours writes it there.
        case DocType of
            DocType::Invoice:
                if InvBatch.Get(BatchCode) then
                    CheckOpen(InvBatch.Status, BatchCode)
                else
                    if CreateConfirmed(BatchCode) then begin
                        InvBatch.Init();
                        InvBatch."Code" := BatchCode;
                        InvBatch.Insert(true);
                    end;
            DocType::"Credit Memo":
                if CrMemoBatch.Get(BatchCode) then
                    CheckOpen(CrMemoBatch.Status, BatchCode)
                else
                    if CreateConfirmed(BatchCode) then begin
                        CrMemoBatch.Init();
                        CrMemoBatch."Code" := BatchCode;
                        CrMemoBatch.Insert(true);
                    end;
        end;
    end;

    procedure CheckOrCreateSalesBatch(DocType: Enum "Sales Document Type"; BatchCode: Code[20])
    var
        CrMemoBatch: Record "BVR Sales CrMemo Batch";
    begin
        if BatchCode = '' then
            exit;

        // Credit memos only. Sales shipments are batched on the Warehouse Shipment, not the order.
        case DocType of
            DocType::"Credit Memo":
                if CrMemoBatch.Get(BatchCode) then
                    CheckOpen(CrMemoBatch.Status, BatchCode)
                else
                    if CreateConfirmed(BatchCode) then begin
                        CrMemoBatch.Init();
                        CrMemoBatch."Code" := BatchCode;
                        CrMemoBatch.Insert(true);
                    end;
        end;
    end;

    procedure CheckOrCreateWhseRcptBatch(BatchCode: Code[20])
    var
        RcptBatch: Record "BVR Purch Rcpt Batch";
    begin
        if BatchCode = '' then
            exit;

        if RcptBatch.Get(BatchCode) then begin
            CheckOpen(RcptBatch.Status, BatchCode);
            exit;
        end;

        if CreateConfirmed(BatchCode) then begin
            RcptBatch.Init();
            RcptBatch."Code" := BatchCode;
            RcptBatch.Insert(true);
        end;
    end;

    procedure CheckOrCreateWhseShptBatch(BatchCode: Code[20])
    var
        ShptBatch: Record "BVR Sales Shpt Batch";
    begin
        if BatchCode = '' then
            exit;

        if ShptBatch.Get(BatchCode) then begin
            CheckOpen(ShptBatch.Status, BatchCode);
            exit;
        end;

        if CreateConfirmed(BatchCode) then begin
            ShptBatch.Init();
            ShptBatch."Code" := BatchCode;
            ShptBatch.Insert(true);
        end;
    end;

    // Declining the question errors rather than quietly clearing the field: the value the user typed
    // has to go somewhere definite, and leaving it in place would put a batch code on the document
    // that no batch table knows about.
    //
    // GuiAllowed guards the Confirm - a batch cannot be invented on the user's behalf by a job queue
    // or a web service, so those get the plain "does not exist" error instead.   //AAV.SP
    local procedure CreateConfirmed(BatchCode: Code[20]): Boolean
    begin
        if not GuiAllowed() then
            Error(BatchMissingErr, BatchCode);
        if not Confirm(CreateBatchQst, true, BatchCode) then
            Error(BatchMissingErr, BatchCode);
        exit(true);
    end;

    // A closed batch is history - it has already been posted through. Assigning to one would put the
    // document somewhere the batch pages no longer look. Reopen it first, from the batch list.
    local procedure CheckOpen(Status: Enum "BVR Batch Status"; BatchCode: Code[20])
    begin
        if Status = Status::Closed then
            Error(BatchClosedErr, BatchCode);
    end;

    // A batch can hold documents in several currencies; adding their face values would be arithmetic
    // on unlike units. A blank posting date would fail the rate lookup, so an unposted document falls
    // back to today's rate.   //AAV.SP
    procedure ToLCY(Amount: Decimal; CurrencyCode: Code[10]; CurrencyFactor: Decimal; PostingDate: Date): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        ConversionDate: Date;
    begin
        if (Amount = 0) or (CurrencyCode = '') then
            exit(Amount);

        ConversionDate := PostingDate;
        if ConversionDate = 0D then
            ConversionDate := WorkDate();
        exit(Round(CurrExchRate.ExchangeAmtFCYToLCY(ConversionDate, CurrencyCode, Amount, CurrencyFactor)));
    end;

    var
        CreateBatchQst: Label 'Batch %1 does not exist.\\Do you want to create it?', Comment = '%1 = batch code';
        BatchMissingErr: Label 'Batch %1 does not exist. Choose an existing batch, or create it from the Batch No. lookup.', Comment = '%1 = batch code';
        BatchClosedErr: Label 'Batch %1 is closed and cannot take any more documents. Reopen it from the batch list first.', Comment = '%1 = batch code';
}
