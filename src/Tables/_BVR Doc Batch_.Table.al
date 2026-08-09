table 50151 "BVR Doc Batch"
{
    // User-named batch that groups documents for AP review, in the spirit of a General Journal
    // Batch. The AP team assigns one to a Warehouse Receipt; it is carried onto the resulting
    // Posted Purchase Receipt when the WR posts (codeunit "BVR Whse Receipt Mgt").   //AAV.SP
    Caption = 'Document Batch';
    DataClassification = CustomerContent;
    LookupPageId = "BVR Doc Batch List";
    DrillDownPageId = "BVR Doc Batch List";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        // One batch belongs to one document kind. The Batch No. lookups on the Warehouse Receipt and
        // the Purchase Invoice each filter on this, so the two processes cannot pick each other's
        // batches. Note the primary key stays "Code" alone: a batch code is unique across ALL types,
        // so B1 is either a Receipt batch or an Invoice batch, never both.   //AAV.SP
        field(3; Type; Enum "BVR Batch Type")
        {
            Caption = 'Type';
        }
        // Set to Closed by CloseIfComplete when the last document leaves the batch. Not editable by
        // hand - use the Reopen action, so reopening is a deliberate act rather than a stray click.
        //   //AAV.SP
        field(4; Status; Enum "BVR Batch Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(10; "No. of Whse. Receipts"; Integer)
        {
            Caption = 'No. of Warehouse Receipts';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Warehouse Receipt Header" where("BVR Batch No." = field("Code")));
        }
        field(11; "No. of Posted Receipts"; Integer)
        {
            Caption = 'No. of Posted Receipts';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Purch. Rcpt. Header" where("BVR Batch No." = field("Code")));
        }
        field(12; "No. of Purch. Invoices"; Integer)
        {
            Caption = 'No. of Purchase Invoices';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Purchase Header" where("Document Type" = const(Invoice),
                                                         "BVR Doc Batch No." = field("Code")));
        }
        field(13; "No. of Posted Purch. Inv."; Integer)
        {
            Caption = 'No. of Posted Purchase Invoices';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Purch. Inv. Header" where("BVR Doc Batch No." = field("Code")));
        }
        field(14; "No. of Purch. Cr. Memos"; Integer)
        {
            Caption = 'No. of Purchase Credit Memos';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Purchase Header" where("Document Type" = const("Credit Memo"),
                                                         "BVR Doc Batch No." = field("Code")));
        }
        field(15; "No. of Posted Purch. Cr.Memo"; Integer)
        {
            Caption = 'No. of Posted Purchase Credit Memos';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Purch. Cr. Memo Hdr." where("BVR Doc Batch No." = field("Code")));
        }
        field(16; "No. of Sales Orders"; Integer)
        {
            Caption = 'No. of Sales Orders';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Sales Header" where("Document Type" = const(Order),
                                                      "BVR Doc Batch No." = field("Code")));
        }
        field(17; "No. of Posted Sales Invoices"; Integer)
        {
            Caption = 'No. of Posted Sales Invoices';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Sales Invoice Header" where("BVR Doc Batch No." = field("Code")));
        }
        field(18; "No. of Sales Cr. Memos"; Integer)
        {
            Caption = 'No. of Sales Credit Memos';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Sales Header" where("Document Type" = const("Credit Memo"),
                                                      "BVR Doc Batch No." = field("Code")));
        }
        field(19; "No. of Posted Sales Cr.Memo"; Integer)
        {
            Caption = 'No. of Posted Sales Credit Memos';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Sales Cr.Memo Header" where("BVR Doc Batch No." = field("Code")));
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    // Closes the batch once nothing is left in it to post. Called at the end of a successful batch
    // post; runs inside that same transaction, so if the batch post is rolled back the close goes
    // with it. Returns whether it actually closed the batch.   //AAV.SP
    procedure CloseIfComplete(): Boolean
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        StillHasDocuments: Boolean;
    begin
        if Status = Status::Closed then
            exit(false);

        // Deliberately counts EVERY document left in the batch, released or not. A batch that still
        // holds an unreleased document is not finished, even though the batch pages - which list
        // released documents only - would look empty.
        case Type of
            Type::Receipt:
                begin
                    WhseRcptHeader.SetRange("BVR Batch No.", "Code");
                    StillHasDocuments := not WhseRcptHeader.IsEmpty();
                end;
            Type::Invoice, Type::"Purch. Credit Memo":
                begin
                    FilterPurchaseDocs(PurchaseHeader);
                    StillHasDocuments := not PurchaseHeader.IsEmpty();
                end;
            Type::"Sales Order", Type::"Sales Credit Memo":
                begin
                    FilterSalesDocs(SalesHeader);
                    StillHasDocuments := not SalesHeader.IsEmpty();
                end;
        end;

        if StillHasDocuments then
            exit(false);

        Status := Status::Closed;
        Modify();
        exit(true);
    end;

    // What the batch is worth, in LCY - the sum of the documents still waiting in it.
    //
    // Each type totals the same figure its batch page lists per document, so the total always ties
    // back to the lines above it: receipts are valued at Qty. to Receive x unit cost, invoices at
    // Amount Including VAT. A batch only ever holds one type, so the two are never added together.
    //
    // Only RELEASED documents are counted - the same ones the batch pages list. A document still
    // being worked on cannot be posted, so counting it would overstate what the batch is about to
    // book and would not tie back to the lines on screen.
    //
    // Only unposted documents are counted. Once a document posts it leaves the batch, and the total
    // falls by its value - the batch shows what is left to post, not what went through it.   //AAV.SP
    procedure CalcTotalAmount(): Decimal
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        Total: Decimal;
    begin
        case Type of
            Type::Receipt:
                begin
                    WhseRcptHeader.SetRange("BVR Batch No.", "Code");
                    WhseRcptHeader.SetRange("BVR Receipt Status", WhseRcptHeader."BVR Receipt Status"::Released);
                    if WhseRcptHeader.FindSet() then
                        repeat
                            Total += WhseRcptHeader.BVRCalcAmount();
                        until WhseRcptHeader.Next() = 0;
                end;
            Type::Invoice, Type::"Purch. Credit Memo":
                begin
                    FilterPurchaseDocs(PurchaseHeader);
                    PurchaseHeader.SetRange(Status, PurchaseHeader.Status::Released);
                    if PurchaseHeader.FindSet() then
                        repeat
                            PurchaseHeader.CalcFields("Amount Including VAT");
                            Total += ToLCY(
                                PurchaseHeader."Amount Including VAT", PurchaseHeader."Currency Code",
                                PurchaseHeader."Currency Factor", PurchaseHeader."Posting Date");
                        until PurchaseHeader.Next() = 0;
                end;
            Type::"Sales Order", Type::"Sales Credit Memo":
                begin
                    FilterSalesDocs(SalesHeader);
                    SalesHeader.SetRange(Status, SalesHeader.Status::Released);
                    if SalesHeader.FindSet() then
                        repeat
                            SalesHeader.CalcFields("Amount Including VAT");
                            Total += ToLCY(
                                SalesHeader."Amount Including VAT", SalesHeader."Currency Code",
                                SalesHeader."Currency Factor", SalesHeader."Posting Date");
                        until SalesHeader.Next() = 0;
                end;
        end;

        exit(Total);
    end;

    // Filters to this batch's purchase documents. The document type comes from the batch type, so an
    // Invoice batch can never pick up a credit memo that happens to carry the same batch code - which
    // the conditional TableRelation on "Purchase Header" already prevents, but the filter should not
    // depend on that holding.   //AAV.SP
    procedure FilterPurchaseDocs(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Reset();
        if Type = Type::"Purch. Credit Memo" then
            PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo")
        else
            PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.SetRange("BVR Doc Batch No.", "Code");
    end;

    procedure FilterSalesDocs(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Reset();
        if Type = Type::"Sales Credit Memo" then
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo")
        else
            SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("BVR Doc Batch No.", "Code");
    end;

    // A batch can hold documents in several currencies; adding their face values would be arithmetic
    // on unlike units. A blank posting date would fail the rate lookup, so an unposted document falls
    // back to today's rate.   //AAV.SP
    local procedure ToLCY(Amount: Decimal; CurrencyCode: Code[10]; CurrencyFactor: Decimal; PostingDate: Date): Decimal
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

    procedure Reopen()
    begin
        if Status = Status::Open then
            exit;
        Status := Status::Open;
        Modify();
    end;
}
