page 50170 "BVR Sales Invoice API"
{
    // Creates a draft Sales Invoice from an external system's JSON, in the shape that system already
    // sends. The field names are Microsoft's own salesInvoices vocabulary, so a client written
    // against the standard API needs no changes to point at this one.
    //
    //   POST /api/ise/integration/v1.0/companies({id})/iseSalesInvoices
    //   {
    //     "number": "PIN20251200000",
    //     "customerNumber": "CS2018040003",
    //     "externalDocumentNumber": "MES_2026FEB",
    //     "invoiceDate": "2026-02-26",
    //     "postingDate": "2026-02-26",
    //     "dueDate": "2026-04-26",
    //     "customerPurchaseOrderReference": "PO-013435",
    //     "currencyCode": "USD",
    //     "shortcutDimension1Code": "ADMIN",
    //     "shortcutDimension2Code": "SITE-A",
    //     "iseSalesInvoiceLines": [ { "lineType": "Account", "lineObjectNumber": "4010", ... } ]
    //   }
    //
    // The invoice is created OPEN, not posted. Posting is a separate decision with its own approval
    // and its own batch, and an integration that posts as a side effect of receiving a document is
    // an integration nobody can stop once it is wrong.   //AAV.SP
    PageType = API;
    APIPublisher = 'ise';
    APIGroup = 'integration';
    APIVersion = 'v1.0';
    EntityName = 'iseSalesInvoice';
    EntitySetName = 'iseSalesInvoices';
    EntityCaption = 'Sales Invoice';
    EntitySetCaption = 'Sales Invoices';
    Caption = 'Sales Invoice API';
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = const(Invoice));
    ODataKeyFields = SystemId;
    // Required for the nested lines to arrive in the same POST: the header is not written until
    // OnInsertRecord, so the framework can hold the children until it has a parent to link them to.
    DelayedInsert = true;
    Extensible = false;
    Editable = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                }
                field(customerNumber; Rec."Sell-to Customer No.")
                {
                    Caption = 'Customer Number';
                }
                field(externalDocumentNumber; Rec."External Document No.")
                {
                    Caption = 'External Document Number';
                }
                field(invoiceDate; Rec."Document Date")
                {
                    Caption = 'Invoice Date';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(dueDate; Rec."Due Date")
                {
                    Caption = 'Due Date';
                }
                field(customerPurchaseOrderReference; Rec."Your Reference")
                {
                    Caption = 'Customer Purchase Order Reference';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(batchNumber; Rec."BVR Doc Batch No.")
                {
                    Caption = 'Batch Number';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                    Editable = false;
                }
                part(iseSalesInvoiceLines; "BVR Sales Invoice Line API")
                {
                    Caption = 'Lines';
                    EntityName = 'iseSalesInvoiceLine';
                    EntitySetName = 'iseSalesInvoiceLines';
                    SubPageLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                }
            }
        }
    }

    // The framework fills Rec straight from the JSON, field by field, with no ordering and no
    // validation. That is no way to build a Sales Header: validating the customer resets the dates
    // and the currency, validating the posting date re-reads the exchange rate, and a due date
    // written before the customer is silently replaced by the payment terms' own.
    //
    // So the values are taken off Rec, a clean header is inserted, and each one is then VALIDATED
    // back on in the order the table expects. Anything the caller did not send is left to Business
    // Central to default, which is why every assignment is guarded.   //AAV.SP
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
        CustomerNo: Code[20];
        ExternalDocNo: Code[35];
        YourRef: Text[35];
        CurrencyCode: Code[10];
        BatchNo: Code[20];
        ShortcutDim1: Code[20];
        ShortcutDim2: Code[20];
        DocumentDate: Date;
        PostingDate: Date;
        DueDate: Date;
    begin
        InvoiceNo := Rec."No.";
        CustomerNo := Rec."Sell-to Customer No.";
        ExternalDocNo := Rec."External Document No.";
        YourRef := Rec."Your Reference";
        CurrencyCode := Rec."Currency Code";
        BatchNo := Rec."BVR Doc Batch No.";
        ShortcutDim1 := Rec."Shortcut Dimension 1 Code";
        ShortcutDim2 := Rec."Shortcut Dimension 2 Code";
        DocumentDate := Rec."Document Date";
        PostingDate := Rec."Posting Date";
        DueDate := Rec."Due Date";

        if CustomerNo = '' then
            Error(CustomerRequiredErr);

        // A caller-supplied number is honoured; left blank, the number series assigns one. Sent
        // twice, the second POST fails on the primary key rather than quietly creating a duplicate
        // invoice - which is the behaviour an integration wants.
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := InvoiceNo;
        SalesHeader.Insert(true);

        // Customer first: it brings the posting groups, payment terms, currency and prices with it,
        // and overwrites anything set before it.
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        // Then the dates, posting date before document date because the exchange rate hangs off it.
        if PostingDate <> 0D then
            SalesHeader.Validate("Posting Date", PostingDate);
        if DocumentDate <> 0D then
            SalesHeader.Validate("Document Date", DocumentDate);
        if CurrencyCode <> '' then
            SalesHeader.Validate("Currency Code", CurrencyCode);
        // Due date LAST. Validating the customer derives one from the payment terms, so a caller's
        // own due date has to be applied after that or it is silently thrown away.
        if DueDate <> 0D then
            SalesHeader.Validate("Due Date", DueDate);
        if ExternalDocNo <> '' then
            SalesHeader.Validate("External Document No.", ExternalDocNo);
        if YourRef <> '' then
            SalesHeader.Validate("Your Reference", YourRef);
        // The two globals go on AFTER the customer, and they have to. Validating the customer builds
        // the document's dimension set from the customer's own default dimensions, so a code written
        // before that is replaced without a word. Validate rather than assign: the setter applies the
        // code as a delta to the Dimension Set ID, which is what the posting routines and every
        // dimension-based report actually read - a bare assignment leaves the set behind and the
        // invoice posts on the customer's dimensions instead of the caller's.
        //
        // A blank code means "keep the customer's default", not "clear it", which is why each one is
        // guarded. A caller that genuinely wants no dimension has to clear it on the customer.
        if ShortcutDim1 <> '' then
            SalesHeader.Validate("Shortcut Dimension 1 Code", ShortcutDim1);
        if ShortcutDim2 <> '' then
            SalesHeader.Validate("Shortcut Dimension 2 Code", ShortcutDim2);
        // Optional: drop the invoice straight into an open batch, so an integrated invoice can be
        // reviewed and posted with the rest of the run instead of on its own.
        if BatchNo <> '' then
            SalesHeader.Validate("BVR Doc Batch No.", BatchNo);

        SalesHeader.Modify(true);

        Rec := SalesHeader;
        Rec.SetRecFilter();
        // False: the record is already inserted above, so the framework must not insert it again.
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(Rec."Document Type", Rec."No.");
        // Only what the caller actually changed, and each one validated - a PATCH that moves the
        // posting date has to re-read the exchange rate the same way a POST does.
        if Rec."Sell-to Customer No." <> SalesHeader."Sell-to Customer No." then
            SalesHeader.Validate("Sell-to Customer No.", Rec."Sell-to Customer No.");
        if Rec."Posting Date" <> SalesHeader."Posting Date" then
            SalesHeader.Validate("Posting Date", Rec."Posting Date");
        if Rec."Document Date" <> SalesHeader."Document Date" then
            SalesHeader.Validate("Document Date", Rec."Document Date");
        if Rec."Currency Code" <> SalesHeader."Currency Code" then
            SalesHeader.Validate("Currency Code", Rec."Currency Code");
        if Rec."Due Date" <> SalesHeader."Due Date" then
            SalesHeader.Validate("Due Date", Rec."Due Date");
        if Rec."External Document No." <> SalesHeader."External Document No." then
            SalesHeader.Validate("External Document No.", Rec."External Document No.");
        if Rec."Your Reference" <> SalesHeader."Your Reference" then
            SalesHeader.Validate("Your Reference", Rec."Your Reference");
        if Rec."Shortcut Dimension 1 Code" <> SalesHeader."Shortcut Dimension 1 Code" then
            SalesHeader.Validate("Shortcut Dimension 1 Code", Rec."Shortcut Dimension 1 Code");
        if Rec."Shortcut Dimension 2 Code" <> SalesHeader."Shortcut Dimension 2 Code" then
            SalesHeader.Validate("Shortcut Dimension 2 Code", Rec."Shortcut Dimension 2 Code");
        if Rec."BVR Doc Batch No." <> SalesHeader."BVR Doc Batch No." then
            SalesHeader.Validate("BVR Doc Batch No.", Rec."BVR Doc Batch No.");

        SalesHeader.Modify(true);
        Rec := SalesHeader;
        exit(false);
    end;

    var
        CustomerRequiredErr: Label 'customerNumber is required to create a sales invoice.';
}
