page 50171 "BVR Sales Invoice Line API"
{
    // The lines of "BVR Sales Invoice API". Reachable both as a nested collection inside a single
    // POST of the invoice, and on its own:
    //
    //   POST /api/ise/integration/v1.0/companies({id})/iseSalesInvoices({id})/iseSalesInvoiceLines
    //   { "lineType": "Account", "lineObjectNumber": "4010",
    //     "description": "Trade Sales - Domestic", "quantity": 1, "unitPrice": 2972.50,
    //     "shipmentDate": "2025-10-21",
    //     "shortcutDimension1Code": "ADMIN", "shortcutDimension2Code": "SITE-A" }
    //
    // A line that sends no dimension codes inherits the invoice's, which is what most callers want.
    // Sending them overrides the invoice on that line only.
    //
    // "lineType" is the CALLER's word, not Business Central's - see enum "BVR API Sales Line Type"
    // for why, and BVRToSalesLineType for the translation.   //AAV.SP
    PageType = API;
    APIPublisher = 'ise';
    APIGroup = 'integration';
    APIVersion = 'v1.0';
    EntityName = 'iseSalesInvoiceLine';
    EntitySetName = 'iseSalesInvoiceLines';
    EntityCaption = 'Sales Invoice Line';
    EntitySetCaption = 'Sales Invoice Lines';
    Caption = 'Sales Invoice Line API';
    SourceTable = "Sales Line";
    SourceTableView = where("Document Type" = const(Invoice));
    ODataKeyFields = SystemId;
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
                field(documentNumber; Rec."Document No.")
                {
                    Caption = 'Document Number';
                    Editable = false;
                }
                field(sequence; Rec."Line No.")
                {
                    Caption = 'Sequence';
                    Editable = false;
                }
                // Backed by a page variable rather than Rec.Type, because the caller's vocabulary and
                // the table's are not the same. Filled from the record on read, translated back on
                // write.   //AAV.SP
                field(lineType; BVRLineType)
                {
                    Caption = 'Line Type';
                }
                // Every writable field below is a page variable, NOT the Sales Line field, for the same
                // reason as lineType. The framework runs each field's OnValidate as it copies the JSON
                // onto Rec - before OnInsertRecord - and on a Sales Line those validations depend on
                // things that are not there yet. "No." is looked up in a table chosen by Type, and Type
                // is still blank at that point, so an account number was checked against STANDARD TEXT
                // ("The Standard Text does not exist. Code='4010'", target lineObjectNumber) although
                // the G/L account exists. Quantity runs TestStatusOpen and Unit Price has type-dependent
                // checks, so they would have been next. Held here instead, and applied by OnInsertRecord
                // in the order the table expects: Type, No., Description, Quantity, Unit Price, dates,
                // dimensions.   //AAV.SP
                field(lineObjectNumber; BVRObjectNo)
                {
                    Caption = 'Line Object Number';
                }
                field(description; BVRDescription)
                {
                    Caption = 'Description';
                }
                field(quantity; BVRQuantity)
                {
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                }
                field(unitPrice; BVRUnitPrice)
                {
                    Caption = 'Unit Price';
                    AutoFormatType = 2;
                }
                field(shipmentDate; BVRShipmentDate)
                {
                    Caption = 'Shipment Date';
                }
                field(shortcutDimension1Code; BVRShortcutDim1)
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; BVRShortcutDim2)
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(amountExcludingTax; Rec.Amount)
                {
                    Caption = 'Amount Excluding Tax';
                    Editable = false;
                }
                field(amountIncludingTax; Rec."Amount Including VAT")
                {
                    Caption = 'Amount Including Tax';
                    Editable = false;
                }
            }
        }
    }

    // Loads the variables from the line on every read. A PATCH also starts from these, so a field it
    // leaves out still holds the line's current value and is not changed.   //AAV.SP
    trigger OnAfterGetRecord()
    begin
        BVRLoadFromLine(Rec);
    end;

    // Same reasoning as the header: the framework writes the fields in no particular order and
    // without validation, and a Sales Line will not tolerate that. Validating Type clears "No.",
    // validating "No." overwrites the description and the unit price from the account or item, and
    // quantity has to come after both or the price is calculated against nothing. So the values are
    // taken off Rec first and then applied in the order the table expects.   //AAV.SP
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        ObjectNo: Code[20];
        LineDescription: Text[100];
        Qty: Decimal;
        UnitPrice: Decimal;
        ShortcutDim1: Code[20];
        ShortcutDim2: Code[20];
        ShipmentDate: Date;
    begin
        DocumentNo := BVRParentDocumentNo();
        if DocumentNo = '' then
            Error(DocumentRequiredErr);

        ObjectNo := BVRObjectNo;
        LineDescription := BVRDescription;
        Qty := BVRQuantity;
        UnitPrice := BVRUnitPrice;
        ShipmentDate := BVRShipmentDate;
        ShortcutDim1 := BVRShortcutDim1;
        ShortcutDim2 := BVRShortcutDim2;

        SalesLine.Init();
        SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
        SalesLine."Document No." := DocumentNo;
        SalesLine."Line No." := BVRNextLineNo(DocumentNo);
        SalesLine.Insert(true);

        SalesLine.Validate(Type, BVRToSalesLineType(BVRLineType));
        if ObjectNo <> '' then
            SalesLine.Validate("No.", ObjectNo);
        // After "No.", which brings the account's or item's own description with it. A caller that
        // sent one meant it, so it is applied last and wins.
        if LineDescription <> '' then
            SalesLine.Validate(Description, LineDescription);
        if Qty <> 0 then
            SalesLine.Validate(Quantity, Qty);
        // After the quantity: validating Quantity re-runs price calculation and would overwrite a
        // caller's own unit price with the price list's.
        if UnitPrice <> 0 then
            SalesLine.Validate("Unit Price", UnitPrice);
        if ShipmentDate <> 0D then
            SalesLine.Validate("Shipment Date", ShipmentDate);
        // The two globals go on AFTER "No.", and they have to. Validating "No." replaces the line's
        // dimension set with the G/L account's or the item's own default dimensions, so a code written
        // before that is thrown away without a word. Validate rather than assign, so the code is
        // applied as a delta to the Dimension Set ID - which is what posting reads. A blank code means
        // "inherit the invoice's", not "clear it".
        if ShortcutDim1 <> '' then
            SalesLine.Validate("Shortcut Dimension 1 Code", ShortcutDim1);
        if ShortcutDim2 <> '' then
            SalesLine.Validate("Shortcut Dimension 2 Code", ShortcutDim2);

        SalesLine.Modify(true);

        // The response reports the line as it was actually saved - the account's description, the
        // invoice's dimensions - wherever the caller left something out.   //AAV.SP
        BVRLoadFromLine(SalesLine);

        Rec := SalesLine;
        Rec.SetRecFilter();
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.");

        if BVRToSalesLineType(BVRLineType) <> SalesLine.Type then
            SalesLine.Validate(Type, BVRToSalesLineType(BVRLineType));
        if BVRObjectNo <> SalesLine."No." then
            SalesLine.Validate("No.", BVRObjectNo);
        if BVRDescription <> SalesLine.Description then
            SalesLine.Validate(Description, BVRDescription);
        if BVRQuantity <> SalesLine.Quantity then
            SalesLine.Validate(Quantity, BVRQuantity);
        if BVRUnitPrice <> SalesLine."Unit Price" then
            SalesLine.Validate("Unit Price", BVRUnitPrice);
        if BVRShipmentDate <> SalesLine."Shipment Date" then
            SalesLine.Validate("Shipment Date", BVRShipmentDate);
        if BVRShortcutDim1 <> SalesLine."Shortcut Dimension 1 Code" then
            SalesLine.Validate("Shortcut Dimension 1 Code", BVRShortcutDim1);
        if BVRShortcutDim2 <> SalesLine."Shortcut Dimension 2 Code" then
            SalesLine.Validate("Shortcut Dimension 2 Code", BVRShortcutDim2);

        SalesLine.Modify(true);
        BVRLoadFromLine(SalesLine);
        Rec := SalesLine;
        exit(false);
    end;

    // Which invoice the line belongs to. On a nested POST the framework has already linked the part
    // to its parent, so the document number arrives as a filter; on a direct POST to the lines
    // endpoint it arrives the same way, from the URL.   //AAV.SP
    local procedure BVRParentDocumentNo(): Code[20]
    begin
        if Rec."Document No." <> '' then
            exit(Rec."Document No.");
        exit(CopyStr(Rec.GetFilter("Document No."), 1, MaxStrLen(Rec."Document No.")));
    end;

    local procedure BVRLoadFromLine(SalesLine: Record "Sales Line")
    begin
        BVRLineType := BVRToApiLineType(SalesLine.Type);
        BVRObjectNo := SalesLine."No.";
        BVRDescription := SalesLine.Description;
        BVRQuantity := SalesLine.Quantity;
        BVRUnitPrice := SalesLine."Unit Price";
        BVRShipmentDate := SalesLine."Shipment Date";
        BVRShortcutDim1 := SalesLine."Shortcut Dimension 1 Code";
        BVRShortcutDim2 := SalesLine."Shortcut Dimension 2 Code";
    end;

    local procedure BVRNextLineNo(DocumentNo: Code[20]): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", DocumentNo);
        if SalesLine.FindLast() then
            exit(SalesLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure BVRToSalesLineType(ApiType: Enum "BVR API Sales Line Type"): Enum "Sales Line Type"
    begin
        case ApiType of
            ApiType::Comment:
                exit("Sales Line Type"::" ");
            ApiType::Account:
                exit("Sales Line Type"::"G/L Account");
            ApiType::Item:
                exit("Sales Line Type"::Item);
            ApiType::Resource:
                exit("Sales Line Type"::Resource);
            ApiType::"Fixed Asset":
                exit("Sales Line Type"::"Fixed Asset");
            ApiType::Charge:
                exit("Sales Line Type"::"Charge (Item)");
        end;
        exit("Sales Line Type"::" ");
    end;

    local procedure BVRToApiLineType(SalesLineType: Enum "Sales Line Type"): Enum "BVR API Sales Line Type"
    begin
        case SalesLineType of
            "Sales Line Type"::"G/L Account":
                exit("BVR API Sales Line Type"::Account);
            "Sales Line Type"::Item:
                exit("BVR API Sales Line Type"::Item);
            "Sales Line Type"::Resource:
                exit("BVR API Sales Line Type"::Resource);
            "Sales Line Type"::"Fixed Asset":
                exit("BVR API Sales Line Type"::"Fixed Asset");
            "Sales Line Type"::"Charge (Item)":
                exit("BVR API Sales Line Type"::Charge);
        end;
        exit("BVR API Sales Line Type"::Comment);
    end;

    var
        BVRLineType: Enum "BVR API Sales Line Type";
        BVRObjectNo: Code[20];
        BVRDescription: Text[100];
        BVRQuantity: Decimal;
        BVRUnitPrice: Decimal;
        BVRShipmentDate: Date;
        BVRShortcutDim1: Code[20];
        BVRShortcutDim2: Code[20];
        DocumentRequiredErr: Label 'The sales invoice line must be posted to an invoice - no document number was supplied.';
}
