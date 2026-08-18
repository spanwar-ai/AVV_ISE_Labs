report 50255 "BVR Purch Rcpt Batch Report"
{
    // Edit list for a Purchase Receipt batch, printed BEFORE it posts: what the batch holds, what
    // each warehouse receipt is worth, the lines behind it, and the accrual entry each receipt will
    // book. The point is to catch problems on paper rather than in the ledger.
    //
    // Everything here is read from UNPOSTED data - the Warehouse Receipt and the purchase orders
    // behind it - because that is all there is before the batch is posted. A warehouse receipt holds
    // quantities only, so every amount is worked out from the source purchase line: Qty. to Receive
    // at the order's Direct Unit Cost.
    //
    // The accrual block is the reason this report is worth running. It is computed EXACTLY as
    // codeunit "BVR Std Rcpt Accrual" will book it - the same lines, the same rounding, and
    // deliberately WITHOUT the line discount, which the accrual does not apply either. If the two
    // ever disagree the report is wrong, not the posting, and the arithmetic here has to follow that
    // codeunit rather than the batch total.   //AAV.SP
    Caption = 'Purchase Receipt Batch';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = "BVRPurchRcptBatchLayout";

    dataset
    {
        dataitem(Batch; "BVR Purch Rcpt Batch")
        {
            RequestFilterFields = "Code", Status;

            column(BatchCode; "Code")
            {
            }
            column(BatchComment; Description)
            {
            }
            column(BatchStatus; Format(Status))
            {
            }
            // Not a Business Central concept. The caption is printed so the form reads the way the AP
            // team expects it to; the value stays blank unless something is mapped to it.   //AAV.SP
            column(AuditTrailCode; BVRAuditTrailCode)
            {
            }
            column(CompanyName; BVRCompanyName)
            {
            }
            column(ReportCaption; ReportCaptionLbl)
            {
            }
            column(BatchIdCaption; BatchIdCaptionLbl)
            {
            }
            column(AuditTrailCaption; AuditTrailCaptionLbl)
            {
            }
            column(BatchCommentCaption; BatchCommentCaptionLbl)
            {
            }
            // Page-header block. Printed at the top of every page rather than once per batch, so a
            // batch that runs over a page still carries who printed it and when.   //AAV.SP
            column(UserDateText; Format(WorkDate()))
            {
            }
            column(SystemCaption; SystemCaptionLbl)
            {
            }
            column(UserDateCaption; UserDateCaptionLbl)
            {
            }
            column(UserIdCaption; UserIdCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(SubTitleCaption; SubTitleCaptionLbl)
            {
            }

            dataitem(WhseRcpt; "Warehouse Receipt Header")
            {
                DataItemLink = "BVR Batch No." = field("Code");
                DataItemTableView = sorting("No.");

                column(RcptNo; "No.")
                {
                }
                column(RcptDocDate; BVRDocDateText)
                {
                }
                column(RcptPostDate; BVRPostDateText)
                {
                }
                column(RcptStatus; Format("BVR Receipt Status"))
                {
                }
                column(VendorNo; BVRVendorNo)
                {
                }
                column(VendorName; BVRVendorName)
                {
                }
                column(VendorDocNo; BVRVendorDocNo)
                {
                }
                column(VoucherNo; BVRVoucherNo)
                {
                }
                // What the receipt is worth: the value of the goods, the tax on them, and the two
                // added together. Net of any line discount, so Amount + Tax = Total with nothing
                // left implicit.   //AAV.SP
                column(RcptAmount; BVRRcptAmount)
                {
                }
                column(TaxAmount; BVRTaxAmount)
                {
                }
                column(RcptTotal; BVRRcptTotal)
                {
                }
                // Column captions, published from the report so they translate.
                column(RcptNoCaption; RcptNoCaptionLbl) { }
                column(DocDateCaption; DocDateCaptionLbl) { }
                column(PostDateCaption; PostDateCaptionLbl) { }
                column(VendorIdCaption; VendorIdCaptionLbl) { }
                column(NameCaption; NameCaptionLbl) { }
                column(VendorDocNoCaption; VendorDocNoCaptionLbl) { }
                column(StatusCaption; StatusCaptionLbl) { }
                column(VoucherNoCaption; VoucherNoCaptionLbl) { }
                column(AmountCaption; AmountCaptionLbl) { }
                column(TaxCaption; TaxCaptionLbl) { }
                column(TotalCaption; TotalCaptionLbl) { }

                dataitem(RcptLine; "Warehouse Receipt Line")
                {
                    DataItemLink = "No." = field("No.");
                    DataItemTableView = sorting("No.", "Line No.");

                    // A 1-based counter, not the table's "Line No." - the layout prints the column
                    // captions above the FIRST line of each receipt, and needs to recognise it. A
                    // warehouse receipt's line numbers start at 10000 and are not contiguous.
                    column(LineNoSeq; BVRLineSeq)
                    {
                    }
                    column(LineItemNo; "Item No.")
                    {
                    }
                    column(LineDescription; Description)
                    {
                    }
                    column(LineUOM; "Unit of Measure Code")
                    {
                    }
                    column(LineSiteId; "Location Code")
                    {
                    }
                    column(LinePONumber; "Source No.")
                    {
                    }
                    column(LineVendorItem; BVRLineVendorItem)
                    {
                    }
                    column(LineQtyShipped; "Qty. to Receive")
                    {
                    }
                    column(LineUnitCost; BVRLineUnitCost)
                    {
                    }
                    column(LineExtendedCost; BVRLineExtendedCost)
                    {
                    }
                    column(LinesHeaderCaption; LinesHeaderCaptionLbl) { }
                    column(ItemCaption; ItemCaptionLbl) { }
                    column(DescriptionCaption; DescriptionCaptionLbl) { }
                    column(UOMCaption; UOMCaptionLbl) { }
                    column(SiteIdCaption; SiteIdCaptionLbl) { }
                    column(PONumberCaption; PONumberCaptionLbl) { }
                    column(VendorItemCaption; VendorItemCaptionLbl) { }
                    column(QtyShippedCaption; QtyShippedCaptionLbl) { }
                    column(UnitCostCaption; UnitCostCaptionLbl) { }
                    column(ExtendedCostCaption; ExtendedCostCaptionLbl) { }

                    trigger OnPreDataItem()
                    begin
                        BVRLineSeq := 0;
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        BVRLineSeq += 1;
                        BVRBuildLine(RcptLine);
                    end;
                }

                // The accrual this receipt will book: two rows, a debit and a credit, in the order an
                // entry is read. Driven off the accounts on the WAREHOUSE RECEIPT header, which is
                // where the AP team sets them and what codeunit "BVR Whse Receipt Mgt" pushes onto the
                // order just before posting.
                //
                // When either account is missing nothing will be accrued at all, and the block says so
                // instead of printing an entry that will never exist - which is precisely the kind of
                // thing this report is run to find.   //AAV.SP
                dataitem(Accrual; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 .. 2));

                    column(AccrualLineNo; Number)
                    {
                    }
                    column(AccrualAccount; BVRAccrualAccount)
                    {
                    }
                    column(AccrualAccountName; BVRAccrualAccountName)
                    {
                    }
                    column(AccrualAccountType; BVRAccrualAccountType)
                    {
                    }
                    // The two global dimensions the accrual entry will carry into the G/L. Worked out
                    // the same way codeunit "BVR Std Rcpt Accrual" works them out, not read off the
                    // warehouse receipt directly - see BVRBuildAccrualDimensions.   //AAV.SP
                    column(AccrualGlobalDim1; BVRGlobalDim1)
                    {
                    }
                    column(AccrualGlobalDim2; BVRGlobalDim2)
                    {
                    }
                    column(AccrualDebit; BVRAccrualDebit)
                    {
                    }
                    column(AccrualCredit; BVRAccrualCredit)
                    {
                    }
                    column(AccrualNote; BVRAccrualNote)
                    {
                    }
                    column(AccrualHeaderCaption; AccrualHeaderCaptionLbl) { }
                    column(AccountCaption; AccountCaptionLbl) { }
                    column(AccountDescCaption; AccountDescCaptionLbl) { }
                    column(AccountTypeCaption; AccountTypeCaptionLbl) { }
                    column(GlobalDim1Caption; BVRDim1Caption) { }
                    column(GlobalDim2Caption; BVRDim2Caption) { }
                    column(DebitCaption; DebitCaptionLbl) { }
                    column(CreditCaption; CreditCaptionLbl) { }

                    trigger OnPreDataItem()
                    begin
                        // One row carries the "nothing will be accrued" note; a real accrual needs two.
                        if not BVRAccrualIsBookable(WhseRcpt) then
                            SetRange(Number, 1, 1);
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        BVRBuildAccrualRow(WhseRcpt, Number);
                    end;
                }

                // After the nested dataitems, because AL wants a dataitem's children declared before
                // its triggers - but it still runs before either of them for each receipt, which is
                // what the line and accrual blocks depend on.   //AAV.SP
                trigger OnAfterGetRecord()
                begin
                    BVRBuildReceiptTotals(WhseRcpt);
                end;
            }
        }
    }

    rendering
    {
        layout("BVRPurchRcptBatchLayout")
        {
            Type = RDLC;
            LayoutFile = './ReportLayouts/BVRPurchRcptBatch.rdl';
            Caption = 'Purchase Receipt Batch';
            Summary = 'Batch-wise edit list: receipts, their lines and the accrual each will book.';
        }
    }

    trigger OnInitReport()
    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
    begin
        if CompanyInfo.Get() then
            BVRCompanyName := CompanyInfo.Name;

        // The dimension columns are headed with what the two globals are actually CALLED in this
        // company - DEPARTMENT, PROJECT - because "Global Dimension 1" tells the reader nothing they
        // could act on. Falls back to the generic wording where a global is not set up.   //AAV.SP
        if GLSetup.Get() then begin
            BVRDim1Caption := GLSetup."Global Dimension 1 Code";
            BVRDim2Caption := GLSetup."Global Dimension 2 Code";
        end;
        if BVRDim1Caption = '' then
            BVRDim1Caption := GlobalDim1CaptionLbl;
        if BVRDim2Caption = '' then
            BVRDim2Caption := GlobalDim2CaptionLbl;
    end;

    // Everything a receipt is worth, worked out from the purchase lines behind it. A Warehouse
    // Receipt carries quantities and nothing else.
    //
    // Freight and Misc stay zero on purpose. On the ISE form they are columns of their own, but
    // Business Central puts freight and other charges on separate CHARGE (ITEM) lines rather than in
    // header buckets, so there is nothing to read into them - and inventing a split would be worse
    // than a truthful zero. The charges themselves are visible as their own lines.   //AAV.SP
    local procedure BVRBuildReceiptTotals(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WhseRcptLine2: Record "Warehouse Receipt Line";
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        LineGross: Decimal;
    begin
        Clear(BVRSubtotal);
        Clear(BVRTradeDiscount);
        Clear(BVRTaxAmount);
        Clear(BVRRcptAmount);
        Clear(BVRRcptTotal);
        Clear(BVRVendorNo);
        Clear(BVRVendorName);
        Clear(BVRVendorDocNo);
        Clear(BVRAccrualAmount);

        // A warehouse receipt has no document date of its own, so its posting date stands for the
        // document date - said plainly rather than left looking like two different dates that happen
        // to match.
        BVRDocDateText := Format(WarehouseReceiptHeader."Posting Date");
        // The date the receipt will ACTUALLY post on, which is the batch's where the batch has one:
        // "BVR Whse Rcpt Batch Post" forces it onto every receipt as it posts. Showing the receipt's
        // own date here would have the edit list state a date the posting is about to overrule.
        if Batch."Posting Date" <> 0D then
            BVRPostDateText := Format(Batch."Posting Date")
        else
            BVRPostDateText := Format(WarehouseReceiptHeader."Posting Date");
        // The vendor's own reference for the delivery, which is what the warehouse types on arrival.
        BVRVendorDocNo := WarehouseReceiptHeader."Vendor Shipment No.";
        // The voucher is the BATCH, not the receipt. Every receipt posted out of this batch carries
        // the same voucher number, which is how the AP team ties the ledger back to one run.
        BVRVoucherNo := WarehouseReceiptHeader."BVR Batch No.";

        WhseRcptLine2.SetRange("No.", WarehouseReceiptHeader."No.");
        WhseRcptLine2.SetRange("Source Document", WhseRcptLine2."Source Document"::"Purchase Order");
        if not WhseRcptLine2.FindSet() then
            exit;

        repeat
            if PurchLine.Get(PurchLine."Document Type"::Order, WhseRcptLine2."Source No.", WhseRcptLine2."Source Line No.") then begin
                LineGross := Round(PurchLine."Direct Unit Cost" * WhseRcptLine2."Qty. to Receive");
                BVRSubtotal += LineGross;
                BVRTradeDiscount += Round(LineGross * PurchLine."Line Discount %" / 100);

                // The accrual books the GROSS amount - no line discount - because that is what
                // "BVR Std Rcpt Accrual" sums. Kept as its own running total so the two can differ
                // without one quietly borrowing the other's figure.
                if WhseRcptLine2."Item No." <> '' then
                    BVRAccrualAmount += LineGross;

                if (BVRVendorNo = '') and PurchHeader.Get(PurchHeader."Document Type"::Order, WhseRcptLine2."Source No.") then begin
                    BVRVendorNo := PurchHeader."Buy-from Vendor No.";
                    BVRVendorName := PurchHeader."Buy-from Vendor Name";
                    if WarehouseReceiptHeader."Vendor Shipment No." = '' then
                        BVRVendorDocNo := PurchHeader."Vendor Invoice No.";
                end;
            end;
        until WhseRcptLine2.Next() = 0;

        // Amount is what the goods are worth after any line discount; Total adds the tax to it.
        // The trade discount is still worked out line by line above, it just is not a column of its
        // own any more - it is netted off here so Amount + Tax = Total with nothing implicit.
        BVRRcptAmount := BVRSubtotal - BVRTradeDiscount;
        BVRRcptTotal := BVRRcptAmount + BVRTaxAmount;

        BVRBuildAccrualDimensions(WarehouseReceiptHeader);
    end;

    // The two global dimensions the accrual entry will be posted with.
    //
    // Worked out the way codeunit "BVR Std Rcpt Accrual" works them out, and in the same order,
    // because anything else would print a dimension the posting is about to contradict:
    //   1. the SOURCE PURCHASE ORDER's dimension set, resolved back to its two global codes;
    //   2. then the warehouse receipt's own codes on top, where they are filled in - a blank one
    //      means "keep the order's", not "clear it".
    // The receipt's codes are read from the warehouse receipt rather than the order because this
    // report runs BEFORE posting: "BVR Whse Receipt Mgt" only stamps them onto the order at post
    // time, so on the order they are still blank while the receipt already has them.
    //
    // A warehouse receipt may draw on several purchase orders, and each posts its own accrual with
    // its own dimensions. Where the orders disagree, one code cannot describe them all, so the
    // column says so rather than showing whichever came first.   //AAV.SP
    local procedure BVRBuildAccrualDimensions(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WhseRcptLine2: Record "Warehouse Receipt Line";
        PurchHeader: Record "Purchase Header";
        DimMgt: Codeunit DimensionManagement;
        OrderNos: List of [Code[20]];
        Dim1: Code[20];
        Dim2: Code[20];
        FirstOrder: Boolean;
    begin
        Clear(BVRGlobalDim1);
        Clear(BVRGlobalDim2);
        FirstOrder := true;

        WhseRcptLine2.SetRange("No.", WarehouseReceiptHeader."No.");
        WhseRcptLine2.SetRange("Source Document", WhseRcptLine2."Source Document"::"Purchase Order");
        if not WhseRcptLine2.FindSet() then
            exit;

        repeat
            if not OrderNos.Contains(WhseRcptLine2."Source No.") then begin
                OrderNos.Add(WhseRcptLine2."Source No.");
                if PurchHeader.Get(PurchHeader."Document Type"::Order, WhseRcptLine2."Source No.") then begin
                    Clear(Dim1);
                    Clear(Dim2);
                    DimMgt.UpdateGlobalDimFromDimSetID(PurchHeader."Dimension Set ID", Dim1, Dim2);
                    if WarehouseReceiptHeader."BVR Shortcut Dimension 1 Code" <> '' then
                        Dim1 := WarehouseReceiptHeader."BVR Shortcut Dimension 1 Code";
                    if WarehouseReceiptHeader."BVR Shortcut Dimension 2 Code" <> '' then
                        Dim2 := WarehouseReceiptHeader."BVR Shortcut Dimension 2 Code";

                    if FirstOrder then begin
                        BVRGlobalDim1 := Dim1;
                        BVRGlobalDim2 := Dim2;
                        FirstOrder := false;
                    end else begin
                        if BVRGlobalDim1 <> Dim1 then
                            BVRGlobalDim1 := VariousDimTxt;
                        if BVRGlobalDim2 <> Dim2 then
                            BVRGlobalDim2 := VariousDimTxt;
                    end;
                end;
            end;
        until WhseRcptLine2.Next() = 0;
    end;

    // Cost and vendor item come from the source purchase line - the warehouse line has neither.
    local procedure BVRBuildLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        PurchLine: Record "Purchase Line";
    begin
        Clear(BVRLineUnitCost);
        Clear(BVRLineExtendedCost);
        Clear(BVRLineVendorItem);

        if WarehouseReceiptLine."Source Document" <> WarehouseReceiptLine."Source Document"::"Purchase Order" then
            exit;
        if not PurchLine.Get(PurchLine."Document Type"::Order, WarehouseReceiptLine."Source No.", WarehouseReceiptLine."Source Line No.") then
            exit;

        BVRLineUnitCost := PurchLine."Direct Unit Cost";
        BVRLineVendorItem := PurchLine."Vendor Item No.";
        BVRLineExtendedCost := Round(
            PurchLine."Direct Unit Cost" * WarehouseReceiptLine."Qty. to Receive" *
            (1 - PurchLine."Line Discount %" / 100));
    end;

    local procedure BVRAccrualIsBookable(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"): Boolean
    begin
        exit((WarehouseReceiptHeader."BVR Expense Accrual Acc No." <> '') and
             (WarehouseReceiptHeader."BVR Vendor Accrual Acc No." <> '') and
             (BVRAccrualAmount <> 0));
    end;

    local procedure BVRBuildAccrualRow(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; RowNo: Integer)
    begin
        Clear(BVRAccrualAccount);
        Clear(BVRAccrualAccountName);
        Clear(BVRAccrualAccountType);
        Clear(BVRAccrualDebit);
        Clear(BVRAccrualCredit);
        Clear(BVRAccrualNote);

        if not BVRAccrualIsBookable(WarehouseReceiptHeader) then begin
            if BVRAccrualAmount = 0 then
                BVRAccrualNote := NoAccrualAmountTxt
            else
                BVRAccrualNote := NoAccrualAccountsTxt;
            exit;
        end;

        case RowNo of
            1:
                begin
                    BVRAccrualAccount := WarehouseReceiptHeader."BVR Expense Accrual Acc No.";
                    BVRAccrualDebit := BVRAccrualAmount;
                end;
            2:
                begin
                    BVRAccrualAccount := WarehouseReceiptHeader."BVR Vendor Accrual Acc No.";
                    BVRAccrualCredit := BVRAccrualAmount;
                end;
        end;
        BVRAccrualAccountName := BVRAccountName(BVRAccrualAccount);
        BVRAccrualAccountType := BVRAccountType(BVRAccrualAccount);
    end;

    local procedure BVRAccountName(AccountNo: Code[20]): Text[100]
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(AccountNo) then
            exit(GLAccount.Name);
    end;

    local procedure BVRAccountType(AccountNo: Code[20]): Text[50]
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(AccountNo) then
            exit(CopyStr(Format(GLAccount."Income/Balance"), 1, 50));
    end;

    var
        BVRCompanyName: Text[100];
        BVRAuditTrailCode: Code[20];
        BVRGlobalDim1: Text[30];
        BVRGlobalDim2: Text[30];
        BVRDim1Caption: Text[30];
        BVRDim2Caption: Text[30];
        BVRDocDateText: Text[30];
        BVRPostDateText: Text[30];
        BVRVendorNo: Code[20];
        BVRVendorName: Text[100];
        BVRVendorDocNo: Text[35];
        BVRVoucherNo: Code[20];
        BVRSubtotal: Decimal;
        BVRTradeDiscount: Decimal;
        BVRTaxAmount: Decimal;
        BVRRcptAmount: Decimal;
        BVRRcptTotal: Decimal;
        BVRLineSeq: Integer;
        BVRLineUnitCost: Decimal;
        BVRLineExtendedCost: Decimal;
        BVRLineVendorItem: Text[50];
        BVRAccrualAmount: Decimal;
        BVRAccrualAccount: Code[20];
        BVRAccrualAccountName: Text[100];
        BVRAccrualAccountType: Text[50];
        BVRAccrualDebit: Decimal;
        BVRAccrualCredit: Decimal;
        BVRAccrualNote: Text[250];
        NoAccrualAccountsTxt: Label 'No accrual will be booked - the Vendor Accrual and Expense Accrual accounts are not both filled in on this warehouse receipt.';
        NoAccrualAmountTxt: Label 'No accrual will be booked - this receipt has no item quantity to receive.';
        ReportCaptionLbl: Label 'RECEIVINGS EDIT LIST';
        SystemCaptionLbl: Label 'System:';
        UserDateCaptionLbl: Label 'User Date:';
        UserIdCaptionLbl: Label 'User ID:';
        PageNoCaptionLbl: Label 'Page:';
        SubTitleCaptionLbl: Label 'Purchase Order Processing';
        BatchIdCaptionLbl: Label 'Batch ID:';
        AuditTrailCaptionLbl: Label 'Audit Trail Code:';
        BatchCommentCaptionLbl: Label 'Batch Comment:';
        RcptNoCaptionLbl: Label 'Receipt No.';
        DocDateCaptionLbl: Label 'Doc. Date';
        PostDateCaptionLbl: Label 'Post Date';
        VendorIdCaptionLbl: Label 'Vendor ID';
        NameCaptionLbl: Label 'Name';
        VendorDocNoCaptionLbl: Label 'Vendor Doc. No.';
        StatusCaptionLbl: Label 'Status';
        VoucherNoCaptionLbl: Label 'Voucher No.';
        AmountCaptionLbl: Label 'Amount';
        TaxCaptionLbl: Label 'Tax Amount';
        TotalCaptionLbl: Label 'Total Amount';
        LinesHeaderCaptionLbl: Label 'Warehouse Receipt Lines';
        ItemCaptionLbl: Label 'Item';
        DescriptionCaptionLbl: Label 'Description';
        UOMCaptionLbl: Label 'U of M';
        SiteIdCaptionLbl: Label 'Site ID';
        PONumberCaptionLbl: Label 'PO Number';
        VendorItemCaptionLbl: Label 'Vendor Item';
        QtyShippedCaptionLbl: Label 'Quantity Shipped';
        UnitCostCaptionLbl: Label 'Unit Cost';
        ExtendedCostCaptionLbl: Label 'Extended Cost';
        AccrualHeaderCaptionLbl: Label 'Accrual Entry';
        AccountCaptionLbl: Label 'Account';
        AccountDescCaptionLbl: Label 'Account Description';
        AccountTypeCaptionLbl: Label 'Account Type';
        GlobalDim1CaptionLbl: Label 'Global Dimension 1';
        GlobalDim2CaptionLbl: Label 'Global Dimension 2';
        VariousDimTxt: Label '(various)', Comment = 'Printed where the purchase orders behind one receipt carry different dimensions.';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
}
