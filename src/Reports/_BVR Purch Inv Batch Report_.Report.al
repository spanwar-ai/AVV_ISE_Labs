report 50256 "BVR Purch Inv Batch Report"
{
    // Edit list for a Purchase Invoice batch, printed BEFORE it posts: what the batch holds, what
    // each invoice is worth, the lines behind it, and the G/L distribution each invoice will book.
    // The sister report of "BVR Purch Rcpt Batch Report" and deliberately the same shape - batch,
    // document, lines, and what hits the ledger - so the two read alike.
    //
    // Everything here is read from UNPOSTED data, because that is all there is before the batch is
    // posted. The distribution block is therefore DERIVED rather than observed: it works out the
    // account each line will debit by following the same rules the posting engine follows, in the
    // same order. See BVRLineAccount for that order, and BVRBuildDistributions for the credit side.
    //
    // The block is the reason the report is worth running. This flow's invoices exist to clear the
    // GRNI that "BVR Std Rcpt Accrual" credited at receipt: codeunit "BVR Std Get Receipt Lines"
    // stamps a Vendor Accrual account onto every line it pulls from a receipt, and either writes the
    // line straight to that account or redirects its debit there at posting time. So a healthy
    // invoice in this flow books Dr Vendor Accrual / Cr Vendor - and an invoice that does NOT is
    // exactly what an edit list is for.   //AAV.SP
    Caption = 'Purchase Invoice Batch';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = "BVRPurchInvBatchLayout";

    dataset
    {
        dataitem(Batch; "BVR Purch Inv Batch")
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

            dataitem(PurchInv; "Purchase Header")
            {
                DataItemLink = "BVR Doc Batch No." = field("Code");
                DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Invoice));

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
                column(VendorNo; "Buy-from Vendor No.")
                {
                }
                column(VendorName; "Buy-from Vendor Name")
                {
                }
                column(VendorDocNo; "Vendor Invoice No.")
                {
                }
                column(VoucherNo; BVRVoucherNo)
                {
                }
                // What the invoice is worth: the goods, the tax on them, and the two added together.
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

                dataitem(InvLine; "Purchase Line")
                {
                    DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                    // A 1-based counter, not the table's "Line No." - the layout prints the column
                    // captions above the FIRST line of each invoice and needs to recognise it.
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
                    // Which receipt this line came off, where it came off one. That is the link an AP
                    // clerk needs to tie an invoice line back to what was actually delivered.
                    column(LineRcptNo; "BVR Source Rcpt No.")
                    {
                    }
                    column(LineType; Format(Type))
                    {
                    }
                    column(LineQty; Quantity)
                    {
                    }
                    column(LineUnitCost; "Direct Unit Cost")
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

                // The G/L distribution this invoice will book: a row per debit account, then the
                // credit to Payables. Built into a temporary buffer by BVRBuildDistributions before
                // this dataitem runs, and walked here one row per Number.
                //
                // When nothing can be resolved the block prints a note instead of a phantom entry -
                // which is precisely the kind of thing this report is run to find.   //AAV.SP
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
                        // One row carries the "nothing to distribute" note; a real distribution needs
                        // as many rows as the buffer holds.
                        if BVRDistCount = 0 then
                            SetRange(Number, 1, 1)
                        else
                            SetRange(Number, 1, BVRDistCount);
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        BVRReadDistribution(Number);
                    end;
                }

                // After the nested dataitems, because AL wants a dataitem's children declared before
                // its triggers - but it still runs before either of them for each invoice, which is
                // what the line and distribution blocks depend on.   //AAV.SP
                trigger OnAfterGetRecord()
                begin
                    BVRBuildInvoiceTotals(PurchInv);
                    BVRBuildDistributions(PurchInv);
                end;
            }
        }
    }

    rendering
    {
        layout("BVRPurchInvBatchLayout")
        {
            Type = RDLC;
            LayoutFile = './ReportLayouts/BVRPurchInvBatch.rdl';
            Caption = 'Purchase Invoice Batch';
            Summary = 'Batch-wise edit list: invoices, their lines and the G/L distribution each will book.';
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

    // What the invoice is worth, summed off its lines - a Purchase Header carries no totals of its
    // own. Amount is net of VAT and of any invoice discount; Total is what the vendor will be
    // credited with; Tax is the difference, so the three always agree.   //AAV.SP
    local procedure BVRBuildInvoiceTotals(var PurchaseHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        Clear(BVRInvAmount);
        Clear(BVRInvTotal);
        Clear(BVRTaxAmount);

        // The voucher is the BATCH, not the invoice. Every document posted out of this batch carries
        // the same voucher number, which is how the AP team ties the ledger back to one run.
        BVRVoucherNo := PurchaseHeader."BVR Doc Batch No.";
        // The date the invoice will ACTUALLY post on, which is the batch's where the batch has one:
        // "BVR Purch Inv Batch Post" forces it onto every document as it posts. Showing the
        // document's own date would have the edit list state a date the posting is about to
        // overrule.   //AAV.SP
        if Batch."Posting Date" <> 0D then
            BVRPostDateText := Format(Batch."Posting Date")
        else
            BVRPostDateText := Format(PurchaseHeader."Posting Date");

        PurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchLine.SetFilter(Type, '<>%1', PurchLine.Type::" ");
        if PurchLine.FindSet() then
            repeat
                BVRInvAmount += PurchLine.Amount;
                BVRInvTotal += PurchLine."Amount Including VAT";
            until PurchLine.Next() = 0;

        BVRTaxAmount := BVRInvTotal - BVRInvAmount;
    end;

    // The G/L distribution the invoice will book, into a temporary buffer.
    //
    // Debits come from the lines, one aggregated row per account and dimension pair - the same
    // grouping the G/L ends up with, so the report shows the entries rather than the lines. The
    // credit is the vendor's Payables Account for the whole invoice including tax, which is what
    // standard posting books. Tax gets its own debit row when there is any, so the two sides
    // balance; a distribution that does NOT balance is reported rather than hidden.   //AAV.SP
    local procedure BVRBuildDistributions(var PurchaseHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VendPostingGroup: Record "Vendor Posting Group";
        AccountNo: Code[20];
        Dim1: Code[20];
        Dim2: Code[20];
        VATAmount: Decimal;
        UnresolvedAmount: Decimal;
        TotalDebit: Decimal;
    begin
        BVRDistBuffer.Reset();
        BVRDistBuffer.DeleteAll();
        BVRDistCount := 0;
        Clear(BVRDistNote);
        Clear(UnresolvedAmount);

        PurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchLine.SetFilter(Type, '<>%1', PurchLine.Type::" ");
        if PurchLine.FindSet() then
            repeat
                BVRLineDimensions(PurchaseHeader, PurchLine, Dim1, Dim2);
                if BVRLineAccount(PurchLine, AccountNo) then
                    BVRAddDistribution(AccountNo, Dim1, Dim2, PurchLine.Amount)
                else
                    UnresolvedAmount += PurchLine.Amount;
                VATAmount += PurchLine."Amount Including VAT" - PurchLine.Amount;
            until PurchLine.Next() = 0;

        // Tax, where there is any. One row on the purchase VAT account of the FIRST line that
        // carries tax - splitting it by VAT posting group would be a second opinion, and the figure
        // that matters on an edit list is that the entry balances.
        if VATAmount <> 0 then
            BVRAddDistribution(BVRPurchaseVATAccount(PurchaseHeader), '', '', VATAmount);

        // The credit side. The vendor is credited with the whole invoice, tax included.
        if Vendor.Get(PurchaseHeader."Pay-to Vendor No.") then
            if VendPostingGroup.Get(Vendor."Vendor Posting Group") then begin
                BVRHeaderDimensions(PurchaseHeader, Dim1, Dim2);
                BVRAddDistribution(VendPostingGroup."Payables Account", Dim1, Dim2, -BVRInvTotal);
            end;

        BVRDistBuffer.Reset();
        if BVRDistBuffer.FindSet() then
            repeat
                TotalDebit += BVRDistBuffer.Amount;
            until BVRDistBuffer.Next() = 0;

        // Anything the report could not account for is said out loud. A silent omission on an edit
        // list is worse than no edit list, because it reads as "checked and fine".   //AAV.SP
        if BVRDistCount = 0 then
            BVRDistNote := NoDistributionTxt
        else
            if UnresolvedAmount <> 0 then
                BVRDistNote := StrSubstNo(UnresolvedTxt, UnresolvedAmount)
            else
                if TotalDebit <> 0 then
                    BVRDistNote := StrSubstNo(OutOfBalanceTxt, TotalDebit);
    end;

    // The account a line will debit, by the same rules the posting engine uses and in the same
    // order. Returns false where the account cannot be known without running the post itself -
    // fixed assets, charges and resources all resolve through setup this report does not read - and
    // the caller reports the amount as unaccounted rather than guessing.   //AAV.SP
    local procedure BVRLineAccount(var PurchaseLine: Record "Purchase Line"; var AccountNo: Code[20]): Boolean
    var
        Item: Record Item;
        GenPostingSetup: Record "General Posting Setup";
        InvtPostingSetup: Record "Inventory Posting Setup";
    begin
        Clear(AccountNo);

        // 1. The accrual redirect wins. "BVR Std Get Receipt Lines" stamps this account onto every
        //    line it pulls from a receipt, and its OnPrepareLineOnBeforeSetAccount subscriber forces
        //    the debit there whatever the line's own posting setup says.
        if PurchaseLine."BVR Vendor Accrual Acc No." <> '' then begin
            AccountNo := PurchaseLine."BVR Vendor Accrual Acc No.";
            exit(true);
        end;

        case PurchaseLine.Type of
            PurchaseLine.Type::"G/L Account":
                begin
                    AccountNo := PurchaseLine."No.";
                    exit(AccountNo <> '');
                end;
            PurchaseLine.Type::Item:
                begin
                    if not Item.Get(PurchaseLine."No.") then
                        exit(false);
                    // A stocked item goes to inventory; anything else is an expense on the spot.
                    if Item.Type = Item.Type::Inventory then begin
                        if not InvtPostingSetup.Get(PurchaseLine."Location Code", PurchaseLine."Posting Group") then
                            exit(false);
                        AccountNo := InvtPostingSetup."Inventory Account";
                        exit(AccountNo <> '');
                    end;
                    if not GenPostingSetup.Get(
                        PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group")
                    then
                        exit(false);
                    AccountNo := GenPostingSetup."Purch. Account";
                    exit(AccountNo <> '');
                end;
        end;
        exit(false);
    end;

    local procedure BVRPurchaseVATAccount(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        PurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchLine.SetFilter("Amount Including VAT", '<>%1', 0);
        if PurchLine.FindSet() then
            repeat
                if PurchLine."Amount Including VAT" <> PurchLine.Amount then
                    if VATPostingSetup.Get(PurchLine."VAT Bus. Posting Group", PurchLine."VAT Prod. Posting Group") then
                        exit(VATPostingSetup."Purchase VAT Account");
            until PurchLine.Next() = 0;
    end;

    // A line's two global dimensions, falling back to the header's where the line has no set of its
    // own - which is what posting does.   //AAV.SP
    local procedure BVRLineDimensions(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var Dim1: Code[20]; var Dim2: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        Clear(Dim1);
        Clear(Dim2);
        if PurchaseLine."Dimension Set ID" <> 0 then begin
            DimMgt.UpdateGlobalDimFromDimSetID(PurchaseLine."Dimension Set ID", Dim1, Dim2);
            exit;
        end;
        BVRHeaderDimensions(PurchaseHeader, Dim1, Dim2);
    end;

    local procedure BVRHeaderDimensions(var PurchaseHeader: Record "Purchase Header"; var Dim1: Code[20]; var Dim2: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        Clear(Dim1);
        Clear(Dim2);
        DimMgt.UpdateGlobalDimFromDimSetID(PurchaseHeader."Dimension Set ID", Dim1, Dim2);
    end;

    // Adds to the buffer, merging into the existing row for the same account and dimension pair.
    // A positive amount is a debit, a negative one a credit - the sign is split into the two columns
    // when the row is read.   //AAV.SP
    local procedure BVRAddDistribution(AccountNo: Code[20]; Dim1: Code[20]; Dim2: Code[20]; Amount: Decimal)
    begin
        if (AccountNo = '') or (Amount = 0) then
            exit;

        BVRDistBuffer.Reset();
        BVRDistBuffer.SetRange("Account/Doc", AccountNo);
        BVRDistBuffer.SetRange("Source Dimension 1", Dim1);
        BVRDistBuffer.SetRange("Source Dimension 2", Dim2);
        if BVRDistBuffer.FindFirst() then begin
            BVRDistBuffer.Amount += Amount;
            BVRDistBuffer.Modify();
            exit;
        end;

        BVRDistCount += 1;
        BVRDistBuffer.Init();
        BVRDistBuffer."Document No." := '';
        BVRDistBuffer."Line No." := BVRDistCount;
        BVRDistBuffer."Account/Doc" := AccountNo;
        BVRDistBuffer."Source Dimension 1" := Dim1;
        BVRDistBuffer."Source Dimension 2" := Dim2;
        BVRDistBuffer.Amount := Amount;
        BVRDistBuffer.Description := BVRAccountName(AccountNo);
        BVRDistBuffer."Line Description" := BVRAccountType(AccountNo);
        BVRDistBuffer.Insert();
    end;

    local procedure BVRReadDistribution(RowNo: Integer)
    begin
        Clear(BVRDistAccount);
        Clear(BVRDistAccountName);
        Clear(BVRDistAccountType);
        Clear(BVRDistGlobalDim1);
        Clear(BVRDistGlobalDim2);
        Clear(BVRDistDebit);
        Clear(BVRDistCredit);

        BVRDistBuffer.Reset();
        if not BVRDistBuffer.Get('', RowNo) then
            exit;

        BVRDistAccount := BVRDistBuffer."Account/Doc";
        BVRDistAccountName := BVRDistBuffer.Description;
        BVRDistAccountType := CopyStr(BVRDistBuffer."Line Description", 1, 50);
        BVRDistGlobalDim1 := BVRDistBuffer."Source Dimension 1";
        BVRDistGlobalDim2 := BVRDistBuffer."Source Dimension 2";
        if BVRDistBuffer.Amount > 0 then
            BVRDistDebit := BVRDistBuffer.Amount
        else
            BVRDistCredit := -BVRDistBuffer.Amount;
    end;

    local procedure BVRAccountName(AccountNo: Code[20]): Text[100]
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(AccountNo) then
            exit(GLAccount.Name);
    end;

    local procedure BVRAccountType(AccountNo: Code[20]): Text[100]
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(AccountNo) then
            exit(CopyStr(Format(GLAccount."Income/Balance"), 1, 100));
    end;

    var
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
        NoDistributionTxt: Label 'Nothing will be distributed - this invoice has no line whose account can be determined.';
        UnresolvedTxt: Label '%1 of this invoice posts to accounts that are resolved during posting and are not shown above.', Comment = '%1 = the unaccounted amount';
        OutOfBalanceTxt: Label 'The distribution above is out of balance by %1. Check the invoice before posting the batch.', Comment = '%1 = the difference between debits and credits';
        ReportCaptionLbl: Label 'PAYABLES TRANSACTION EDIT LIST';
        SystemCaptionLbl: Label 'System:';
        UserDateCaptionLbl: Label 'User Date:';
        UserIdCaptionLbl: Label 'User ID:';
        PageNoCaptionLbl: Label 'Page:';
        SubTitleCaptionLbl: Label 'Purchase Order Processing';
        BatchIdCaptionLbl: Label 'Batch ID:';
        AuditTrailCaptionLbl: Label 'Audit Trail Code:';
        BatchCommentCaptionLbl: Label 'Batch Comment:';
        InvNoCaptionLbl: Label 'Invoice No.';
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
        LinesHeaderCaptionLbl: Label 'Purchase Invoice Lines';
        ItemCaptionLbl: Label 'No.';
        DescriptionCaptionLbl: Label 'Description';
        UOMCaptionLbl: Label 'U of M';
        SiteIdCaptionLbl: Label 'Site ID';
        RcptNoCaptionLbl: Label 'Receipt No.';
        LineTypeCaptionLbl: Label 'Type';
        QtyCaptionLbl: Label 'Quantity';
        UnitCostCaptionLbl: Label 'Unit Cost';
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
