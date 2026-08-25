report 50259 "BVR Sales CrMemo Batch Report"
{
    // Edit list for a Sales Credit Memo batch, printed BEFORE it posts: what the batch holds, what each document
    // is worth, the lines behind it, and the G/L distribution each will book. One of the four
    // document batch edit lists, all generated from the same template so they cannot drift apart -
    // see the scratchpad's BuildDocBatchReports.py.
    //
    // Everything is read from UNPOSTED data, because that is all there is before the batch posts. The
    // distribution block is therefore DERIVED rather than observed: codeunit "BVR Batch Dist Mgt"
    // works out the account each line will hit by following the same rules the posting engine
    // follows, in the same order, and reports anything it cannot know rather than guessing.
    //
    // The REVENUE side only. An item line also books cost of goods sold against inventory, but that
    // pair is computed from the item's cost at posting time and is not knowable from an unposted
    // document, so it is left out rather than guessed at.   //AAV.SP
    Caption = 'Sales Credit Memo Batch';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = "BVRSalesCrMemoBatchLayout";

    dataset
    {
        dataitem(Batch; "BVR Sales CrMemo Batch")
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

            dataitem(Doc; "Sales Header")
            {
                DataItemLink = "BVR Doc Batch No." = field("Code");
                DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const("Credit Memo"));

                column(InvNo; "No.")
                {
                }
                column(InvDocDate; Format("Document Date"))
                {
                }
                column(InvPostDate; BVRPostDateText)
                {
                }
                column(InvStatus; Format(Status))
                {
                }
                column(VendorNo; "Sell-to Customer No.")
                {
                }
                column(VendorName; "Sell-to Customer Name")
                {
                }
                column(VendorDocNo; "External Document No.")
                {
                }
                column(VoucherNo; BVRVoucherNo)
                {
                }
                // What the document is worth: the goods, the tax on them, and the two added together.
                // Read off the lines rather than the header, which carries no totals.   //AAV.SP
                column(InvAmount; BVRInvAmount)
                {
                }
                column(TaxAmount; BVRTaxAmount)
                {
                }
                column(InvTotal; BVRInvTotal)
                {
                }
                // Column captions, published from the report so they translate.
                column(InvNoCaption; InvNoCaptionLbl) { }
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

                dataitem(DocLine; "Sales Line")
                {
                    DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                    // A 1-based counter, not the table's "Line No." - the layout prints the column
                    // captions above the FIRST line of each document and needs to recognise it.
                    column(LineNoSeq; BVRLineSeq)
                    {
                    }
                    column(LineItemNo; "No.")
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
                    column(LineRcptNo; Format("Shipment Date"))
                    {
                    }
                    column(LineType; Format(Type))
                    {
                    }
                    column(LineQty; Quantity)
                    {
                    }
                    column(LineUnitCost; "Unit Price")
                    {
                    }
                    column(LineExtendedCost; "Line Amount")
                    {
                    }
                    column(LinesHeaderCaption; LinesHeaderCaptionLbl) { }
                    column(ItemCaption; ItemCaptionLbl) { }
                    column(DescriptionCaption; DescriptionCaptionLbl) { }
                    column(UOMCaption; UOMCaptionLbl) { }
                    column(SiteIdCaption; SiteIdCaptionLbl) { }
                    column(RcptNoCaption; RcptNoCaptionLbl) { }
                    column(LineTypeCaption; LineTypeCaptionLbl) { }
                    column(QtyCaption; QtyCaptionLbl) { }
                    column(UnitCostCaption; UnitCostCaptionLbl) { }
                    column(ExtendedCostCaption; ExtendedCostCaptionLbl) { }

                    trigger OnPreDataItem()
                    begin
                        BVRLineSeq := 0;
                        // Description-only and blank lines carry nothing an edit list can check.
                        SetFilter(Type, '<>%1', Type::" ");
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        BVRLineSeq += 1;
                    end;
                }

                // The G/L distribution, one row per account and dimension pair, built into a temporary
                // buffer before this dataitem runs and walked here one row per Number.   //AAV.SP
                dataitem(Distribution; "Integer")
                {
                    DataItemTableView = sorting(Number);

                    column(DistLineNo; Number)
                    {
                    }
                    column(DistAccount; BVRDistAccount)
                    {
                    }
                    column(DistAccountName; BVRDistAccountName)
                    {
                    }
                    column(DistAccountType; BVRDistAccountType)
                    {
                    }
                    column(DistGlobalDim1; BVRDistGlobalDim1)
                    {
                    }
                    column(DistGlobalDim2; BVRDistGlobalDim2)
                    {
                    }
                    column(DistDebit; BVRDistDebit)
                    {
                    }
                    column(DistCredit; BVRDistCredit)
                    {
                    }
                    column(DistNote; BVRDistNote)
                    {
                    }
                    column(DistHeaderCaption; DistHeaderCaptionLbl) { }
                    column(AccountCaption; AccountCaptionLbl) { }
                    column(AccountDescCaption; AccountDescCaptionLbl) { }
                    column(AccountTypeCaption; AccountTypeCaptionLbl) { }
                    column(GlobalDim1Caption; BVRDim1Caption) { }
                    column(GlobalDim2Caption; BVRDim2Caption) { }
                    column(DebitCaption; DebitCaptionLbl) { }
                    column(CreditCaption; CreditCaptionLbl) { }

                    trigger OnPreDataItem()
                    begin
                        // One row carries the note; a real distribution needs as many as were built.
                        if BVRDistCount = 0 then
                            SetRange(Number, 1, 1)
                        else
                            SetRange(Number, 1, BVRDistCount);
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        BVRDistMgt.ReadRow(
                            BVRDistBuffer, Number, BVRDistAccount, BVRDistAccountName, BVRDistAccountType,
                            BVRDistGlobalDim1, BVRDistGlobalDim2, BVRDistDebit, BVRDistCredit);
                    end;
                }

                // After the nested dataitems, because AL wants a dataitem's children declared before
                // its triggers - but it still runs before either of them for each document, which is
                // what the line and distribution blocks depend on.   //AAV.SP
                trigger OnAfterGetRecord()
                begin
                    BVRBuildTotals(Doc);
                    BVRDistCount := BVRDistMgt.BuildForSales(Doc, BVRDistBuffer, BVRDistNote);
                end;
            }
        }
    }

    rendering
    {
        layout("BVRSalesCrMemoBatchLayout")
        {
            Type = RDLC;
            LayoutFile = './ReportLayouts/BVRSalesCrMemoBatch.rdl';
            Caption = 'Sales Credit Memo Batch';
            Summary = 'Batch-wise edit list: documents, their lines and the G/L distribution each will book.';
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

    // What the document is worth, summed off its lines - the header carries no totals of its own.
    // Amount is net of tax and of any invoice discount; Total is what the customer will be charged;
    // Tax is the difference, so the three always agree.   //AAV.SP
    local procedure BVRBuildTotals(var DocHeader: Record "Sales Header")
    var
        DocLine2: Record "Sales Line";
    begin
        Clear(BVRInvAmount);
        Clear(BVRInvTotal);
        Clear(BVRTaxAmount);

        // The voucher is the BATCH, not the document. Everything posted out of this batch carries the
        // same voucher number, which is how the team ties the ledger back to one run.
        BVRVoucherNo := DocHeader."BVR Doc Batch No.";
        // The date the document will ACTUALLY post on, which is the batch's where the batch has one:
        // the batch posting codeunit forces it onto every document as it posts. Showing the
        // document's own date would have the edit list state a date the posting is about to
        // overrule.   //AAV.SP
        if Batch."Posting Date" <> 0D then
            BVRPostDateText := Format(Batch."Posting Date")
        else
            BVRPostDateText := Format(DocHeader."Posting Date");

        DocLine2.SetRange("Document Type", DocHeader."Document Type");
        DocLine2.SetRange("Document No.", DocHeader."No.");
        DocLine2.SetFilter(Type, '<>%1', DocLine2.Type::" ");
        if DocLine2.FindSet() then
            repeat
                BVRInvAmount += DocLine2.Amount;
                BVRInvTotal += DocLine2."Amount Including VAT";
            until DocLine2.Next() = 0;

        BVRTaxAmount := BVRInvTotal - BVRInvAmount;
    end;

    var
        BVRDistMgt: Codeunit "BVR Batch Dist Mgt";
        BVRDistBuffer: Record "BVR Posting Preview Line" temporary;
        BVRCompanyName: Text[100];
        BVRAuditTrailCode: Code[20];
        BVRPostDateText: Text[30];
        BVRVoucherNo: Code[20];
        BVRInvAmount: Decimal;
        BVRTaxAmount: Decimal;
        BVRInvTotal: Decimal;
        BVRLineSeq: Integer;
        BVRDistCount: Integer;
        BVRDistAccount: Code[20];
        BVRDistAccountName: Text[100];
        BVRDistAccountType: Text[50];
        BVRDistGlobalDim1: Code[20];
        BVRDistGlobalDim2: Code[20];
        BVRDistDebit: Decimal;
        BVRDistCredit: Decimal;
        BVRDistNote: Text[250];
        BVRDim1Caption: Text[30];
        BVRDim2Caption: Text[30];
        ReportCaptionLbl: Label 'RECEIVABLES TRANSACTION EDIT LIST';
        SystemCaptionLbl: Label 'System:';
        UserDateCaptionLbl: Label 'User Date:';
        UserIdCaptionLbl: Label 'User ID:';
        PageNoCaptionLbl: Label 'Page:';
        SubTitleCaptionLbl: Label 'Sales Order Processing';
        BatchIdCaptionLbl: Label 'Batch ID:';
        AuditTrailCaptionLbl: Label 'Audit Trail Code:';
        BatchCommentCaptionLbl: Label 'Batch Comment:';
        InvNoCaptionLbl: Label 'Cr. Memo No.';
        DocDateCaptionLbl: Label 'Doc. Date';
        PostDateCaptionLbl: Label 'Post Date';
        VendorIdCaptionLbl: Label 'Customer ID';
        NameCaptionLbl: Label 'Name';
        VendorDocNoCaptionLbl: Label 'Cust. Doc. No.';
        StatusCaptionLbl: Label 'Status';
        VoucherNoCaptionLbl: Label 'Voucher No.';
        AmountCaptionLbl: Label 'Amount';
        TaxCaptionLbl: Label 'Tax Amount';
        TotalCaptionLbl: Label 'Total Amount';
        LinesHeaderCaptionLbl: Label 'Sales Credit Memo Lines';
        ItemCaptionLbl: Label 'No.';
        DescriptionCaptionLbl: Label 'Description';
        UOMCaptionLbl: Label 'U of M';
        SiteIdCaptionLbl: Label 'Site ID';
        RcptNoCaptionLbl: Label 'Shipment Date';
        LineTypeCaptionLbl: Label 'Type';
        QtyCaptionLbl: Label 'Quantity';
        UnitCostCaptionLbl: Label 'Unit Price';
        ExtendedCostCaptionLbl: Label 'Extended Cost';
        DistHeaderCaptionLbl: Label 'G/L Distribution';
        AccountCaptionLbl: Label 'Account';
        AccountDescCaptionLbl: Label 'Account Description';
        AccountTypeCaptionLbl: Label 'Account Type';
        GlobalDim1CaptionLbl: Label 'Global Dimension 1';
        GlobalDim2CaptionLbl: Label 'Global Dimension 2';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
}
