codeunit 50250 "BVR Posting Preview Mgt"
{
    // SAFE V2 preview: Qty. to Receive > 0 only
    // Shows both debit & credit G/L lines + Item Ledger entries (quantity only)
    procedure PreviewCustomReceiptSafeV2(PurchHdr: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        ItemRec: Record Item;
        Prev: Record "BVR Posting Preview Line" temporary;
        LineNo: Integer;
        QtyToReceive: Decimal;
        AmountLCY: Decimal;
        TotalAccrualAmt: Decimal;
        ExpAcc: Code[20];
        VendAccrAcc: Code[20];
    begin
        PurchHdr.TestField("Document Type", PurchHdr."Document Type"::Order);
        PurchHdr.TestField("BVR Receive PO", true);
        PurchHdr.TestField("BVR Vendor Accrual Acc No.");
        PurchHdr.TestField("BVR Expense Accrual Acc No.");
        ExpAcc:=PurchHdr."BVR Expense Accrual Acc No.";
        VendAccrAcc:=PurchHdr."BVR Vendor Accrual Acc No.";
        LineNo:=0;
        TotalAccrualAmt:=0;
        PurchLine.SetRange("Document Type", PurchHdr."Document Type");
        PurchLine.SetRange("Document No.", PurchHdr."No.");
        PurchLine.SetFilter(Type, '%1|%2', PurchLine.Type::Item, PurchLine.Type::"G/L Account");
        if PurchLine.FindSet()then repeat QtyToReceive:=PurchLine."Qty. to Receive";
                if QtyToReceive <= 0 then continue;
                AmountLCY:=Round(PurchLine."Direct Unit Cost" * QtyToReceive, 0.01);
                TotalAccrualAmt+=AmountLCY;
                // Item Ledger preview (Inventory items only)
                if PurchLine.Type = PurchLine.Type::Item then begin
                    ItemRec.Get(PurchLine."No.");
                    if ItemRec.Type = ItemRec.Type::Inventory then begin
                        LineNo+=10000;
                        Prev.Init();
                        Prev."Document No.":=PurchHdr."No.";
                        Prev."Line No.":=LineNo;
                        Prev."Entry Type":=Prev."Entry Type"::Item;
                        Prev."Account/Doc":=PurchLine."No.";
                        Prev.Description:='Item Ledger Entry (Purchase)';
                        Prev.Quantity:=QtyToReceive;
                        Prev.Amount:=0;
                        Prev."Bal. Account":='';
                        Prev."Debit/Credit":=Prev."Debit/Credit"::None;
                        Prev."Is Item Ledger":=true;
                        Prev.Insert();
                    end;
                end;
                // G/L Debit (Expense Accrual)
                LineNo+=10000;
                Prev.Init();
                Prev."Document No.":=PurchHdr."No.";
                Prev."Line No.":=LineNo;
                Prev."Entry Type":=Prev."Entry Type"::"G/L";
                Prev."Account/Doc":=ExpAcc;
                Prev.Description:=StrSubstNo('Accrual Vendor - %1', CopyStr(PurchLine.Description, 1, 50));
                Prev.Quantity:=0;
                Prev.Amount:=AmountLCY;
                Prev."Bal. Account":=VendAccrAcc;
                Prev."Debit/Credit":=Prev."Debit/Credit"::Debit;
                prev."Item No":=PurchLine."No.";
                Prev."Line Description":=PurchLine.Description;
                Prev."Source PO Quantity":=PurchLine."BVR Source PO Qty";
                Prev."Source PO Cost":=PurchLine."Direct Unit Cost";
                Prev."Source Dimension 1":=PurchLine."Shortcut Dimension 1 Code";
                Prev."Source Dimension 2":=PurchLine."Shortcut Dimension 2 Code";
                Prev."Is Item Ledger":=false;
                Prev.Insert();
                // G/L Credit (Vendor Accrual)
                LineNo+=10000;
                Prev.Init();
                Prev."Document No.":=PurchHdr."No.";
                Prev."Line No.":=LineNo;
                Prev."Entry Type":=Prev."Entry Type"::"G/L";
                Prev."Account/Doc":=VendAccrAcc;
                Prev.Description:=StrSubstNo('Expense Account - %1', CopyStr(PurchLine.Description, 1, 50));
                Prev.Quantity:=0;
                Prev.Amount:=-AmountLCY;
                Prev."Bal. Account":=ExpAcc;
                Prev."Debit/Credit":=Prev."Debit/Credit"::Credit;
                prev."Item No":=PurchLine."No.";
                Prev."Line Description":=PurchLine.Description;
                Prev."Source PO Quantity":=PurchLine."BVR Source PO Qty";
                Prev."Source PO Cost":=PurchLine."Direct Unit Cost";
                Prev."Source Dimension 1":=PurchLine."Shortcut Dimension 1 Code";
                Prev."Source Dimension 2":=PurchLine."Shortcut Dimension 2 Code";
                Prev."Is Item Ledger":=false;
                Prev.Insert();
            until PurchLine.Next() = 0;
        if TotalAccrualAmt = 0 then Error('Preview: No quantities entered in Qty. to Receive.');
        // Totals
        LineNo+=10000;
        Prev.Init();
        Prev."Document No.":=PurchHdr."No.";
        Prev."Line No.":=LineNo;
        Prev."Entry Type":=Prev."Entry Type"::"G/L";
        Prev."Account/Doc":=ExpAcc;
        Prev.Description:='TOTAL Accrual (Debit Expense Accrual)';
        Prev.Amount:=TotalAccrualAmt;
        Prev.Quantity:=0;
        Prev."Bal. Account":=VendAccrAcc;
        Prev."Debit/Credit":=Prev."Debit/Credit"::Debit;
        Prev.Insert();
        LineNo+=10000;
        Prev.Init();
        Prev."Document No.":=PurchHdr."No.";
        Prev."Line No.":=LineNo;
        Prev."Entry Type":=Prev."Entry Type"::"G/L";
        Prev."Account/Doc":=VendAccrAcc;
        Prev.Description:='TOTAL Accrual (Credit Vendor Accrual)';
        Prev.Amount:=-TotalAccrualAmt;
        Prev.Quantity:=0;
        Prev."Bal. Account":=ExpAcc;
        Prev."Debit/Credit":=Prev."Debit/Credit"::Credit;
        Prev.Insert();
        Page.RunModal(Page::"BVR Posting Preview", Prev);
    end;
    procedure BuildPreviewForReceipt(PurchHdr: Record "Purchase Header"; var TempPreview: Record "BVR Posting Preview Line" temporary)
    var
        PurchLine: Record "Purchase Line";
        ItemRec: Record Item;
        LineNo: Integer;
        QtyToReceive: Decimal;
        AmountLCY: Decimal;
        TotalAccrualAmt: Decimal;
        ExpAcc: Code[20];
        VendAccrAcc: Code[20];
    begin
        // --- Validations ---
        PurchHdr.TestField("Document Type", PurchHdr."Document Type"::Order);
        PurchHdr.TestField("BVR Receive PO", true);
        PurchHdr.TestField("BVR Vendor Accrual Acc No.");
        PurchHdr.TestField("BVR Expense Accrual Acc No.");
        // --- Init ---
        TempPreview.DeleteAll();
        LineNo:=0;
        TotalAccrualAmt:=0;
        ExpAcc:=PurchHdr."BVR Expense Accrual Acc No.";
        VendAccrAcc:=PurchHdr."BVR Vendor Accrual Acc No.";
        PurchLine.SetRange("Document Type", PurchHdr."Document Type");
        PurchLine.SetRange("Document No.", PurchHdr."No.");
        PurchLine.SetFilter(Type, '%1|%2', PurchLine.Type::Item, PurchLine.Type::"G/L Account");
        if PurchLine.FindSet()then repeat QtyToReceive:=PurchLine."Qty. to Receive";
                if QtyToReceive <= 0 then continue;
                if(QtyToReceive = 0)then if(PurchLine."Quantity Received" = PurchLine.Quantity)then QtyToReceive:=PurchLine.Quantity
                    else
                        QtyToReceive:=PurchLine."BVR Remaining Qty";
                AmountLCY:=Round(PurchLine."Direct Unit Cost" * QtyToReceive, 0.01);
                TotalAccrualAmt+=AmountLCY;
                // =====================================================
                // ITEM LEDGER PREVIEW (Inventory items only)
                // =====================================================
                if PurchLine.Type = PurchLine.Type::Item then begin
                    if ItemRec.Get(PurchLine."No.")then if ItemRec.Type = ItemRec.Type::Inventory then begin
                            LineNo+=10000;
                            TempPreview.Init();
                            TempPreview."Document No.":=PurchHdr."No.";
                            TempPreview."Line No.":=LineNo;
                            TempPreview."Entry Type":=TempPreview."Entry Type"::Item;
                            TempPreview."Account/Doc":=PurchLine."No.";
                            TempPreview.Description:='Item Ledger Entry (Purchase Receipt)';
                            TempPreview.Quantity:=QtyToReceive;
                            TempPreview.Amount:=0;
                            TempPreview."Bal. Account":='';
                            TempPreview."Debit/Credit":=TempPreview."Debit/Credit"::None;
                            TempPreview."Is Item Ledger":=true;
                            TempPreview.Insert();
                        end;
                end;
                // =====================================================
                // G/L DEBIT – Expense Accrual
                // =====================================================
                LineNo+=10000;
                TempPreview.Init();
                TempPreview."Document No.":=PurchHdr."No.";
                TempPreview."Line No.":=LineNo;
                TempPreview."Entry Type":=TempPreview."Entry Type"::"G/L";
                TempPreview."Account/Doc":=ExpAcc;
                TempPreview.Description:=StrSubstNo('Accrual Expense - %1', CopyStr(PurchLine.Description, 1, 50));
                TempPreview.Quantity:=0;
                TempPreview.Amount:=AmountLCY;
                TempPreview."Bal. Account":=VendAccrAcc;
                TempPreview."Debit/Credit":=TempPreview."Debit/Credit"::Debit;
                TempPreview."Is Item Ledger":=false;
                TempPreview."Item No":=PurchLine."No.";
                TempPreview."Line Description":=PurchLine.Description;
                TempPreview."Source PO Quantity":=PurchLine."BVR Source PO Qty";
                TempPreview."Source PO Cost":=PurchLine."Direct Unit Cost";
                TempPreview."Source Dimension 1":=PurchLine."Shortcut Dimension 1 Code";
                TempPreview."Source Dimension 2":=PurchLine."Shortcut Dimension 2 Code";
                TempPreview.Insert();
                // =====================================================
                // G/L CREDIT – Vendor Accrual
                // =====================================================
                LineNo+=10000;
                TempPreview.Init();
                TempPreview."Document No.":=PurchHdr."No.";
                TempPreview."Line No.":=LineNo;
                TempPreview."Entry Type":=TempPreview."Entry Type"::"G/L";
                TempPreview."Account/Doc":=VendAccrAcc;
                TempPreview.Description:=StrSubstNo('Accrual Vendor - %1', CopyStr(PurchLine.Description, 1, 50));
                TempPreview.Quantity:=0;
                TempPreview.Amount:=-AmountLCY;
                TempPreview."Bal. Account":=ExpAcc;
                TempPreview."Debit/Credit":=TempPreview."Debit/Credit"::Credit;
                TempPreview."Item No":=PurchLine."No.";
                TempPreview."Line Description":=PurchLine.Description;
                TempPreview."Source PO Quantity":=PurchLine."BVR Source PO Qty";
                TempPreview."Source PO Cost":=PurchLine."Direct Unit Cost";
                TempPreview."Source Dimension 1":=PurchLine."Shortcut Dimension 1 Code";
                TempPreview."Source Dimension 2":=PurchLine."Shortcut Dimension 2 Code";
                TempPreview."Is Item Ledger":=false;
                TempPreview.Insert();
            until PurchLine.Next() = 0;
        if TotalAccrualAmt = 0 then Error('Preview: No quantities entered in Qty. to Receive.');
        // =========================================================
        // TOTALS (optional but useful for report)
        // =========================================================
        LineNo+=10000;
        TempPreview.Init();
        TempPreview."Document No.":=PurchHdr."No.";
        TempPreview."Line No.":=LineNo;
        TempPreview."Entry Type":=TempPreview."Entry Type"::"G/L";
        TempPreview."Account/Doc":=ExpAcc;
        TempPreview.Description:='TOTAL Accrual (Debit Expense Accrual)';
        TempPreview.Amount:=TotalAccrualAmt;
        TempPreview.Quantity:=0;
        TempPreview."Bal. Account":=VendAccrAcc;
        TempPreview."Debit/Credit":=TempPreview."Debit/Credit"::Debit;
        TempPreview.Insert();
        LineNo+=10000;
        TempPreview.Init();
        TempPreview."Document No.":=PurchHdr."No.";
        TempPreview."Line No.":=LineNo;
        TempPreview."Entry Type":=TempPreview."Entry Type"::"G/L";
        TempPreview."Account/Doc":=VendAccrAcc;
        TempPreview.Description:='TOTAL Accrual (Credit Vendor Accrual)';
        TempPreview.Amount:=-TotalAccrualAmt;
        TempPreview.Quantity:=0;
        TempPreview."Bal. Account":=ExpAcc;
        TempPreview."Debit/Credit":=TempPreview."Debit/Credit"::Credit;
        TempPreview.Insert();
    end;
    // -----------------------------------------------------------------
    // Custom Purchase Invoice preview - aligned 1:1 with Codeunit 50142 "BVR Custom Inv Post".
    // -----------------------------------------------------------------
    procedure PreviewCustomInvoice(InvHdr: Record "Purchase Header")
    var
        Prev: Record "BVR Posting Preview Line" temporary;
    begin
        BuildPreviewForCustomInvoice(InvHdr, Prev);
        Page.RunModal(Page::"BVR Posting Preview", Prev);
    end;
    procedure BuildPreviewForCustomInvoice(InvHdr: Record "Purchase Header"; var TempPreview: Record "BVR Posting Preview Line" temporary)
    var
        InvoiceBaseAmt: Decimal;
        InvLine: Record "Purchase Line";
        ReceiptBaseAmt: Decimal;
        TaxAmt: Decimal;
        DiscountAmt: Decimal;
        DiffBase: Decimal;
        TotalInvoiceAmt: Decimal;
    begin
        BuildPreviewForCustomInvoiceWithTotals(InvHdr, TempPreview, InvoiceBaseAmt, ReceiptBaseAmt, TaxAmt, DiscountAmt, DiffBase, TotalInvoiceAmt);
    end;
    procedure BuildPreviewForCustomInvoiceWithTotals(InvHdr: Record "Purchase Header"; var TempPreview: Record "BVR Posting Preview Line" temporary; var InvoiceBaseAmt: Decimal; var ReceiptBaseAmt: Decimal; var TaxAmt: Decimal; var DiscountAmt: Decimal; var DiffBase: Decimal; var TotalInvoiceAmt: Decimal)
    var
        Vend: Record Vendor;
        VendPostGrp: Record "Vendor Posting Group";
        TaxSetup: Record "Tax Setup";
        LineNo: Integer;
        PayablesAcc: Code[20];
        VendAccrAcc: Code[20];
        ExpAcc: Code[20];
        InvLine: Record "Purchase Line";
        PurchTaxAcc: Code[20];
    begin
        // Validations identical to posting codeunit 50142
        InvHdr.TestField("Document Type", InvHdr."Document Type"::Invoice);
        InvHdr.TestField("Buy-from Vendor No.");
        InvHdr.TestField("Pay-to Vendor No.");
        InvHdr.TestField("Posting Date");
        InvHdr.TestField("BVR Vendor Accrual Acc No.");
        InvHdr.TestField("BVR Expense Accrual Acc No.");
        TempPreview.DeleteAll();
        LineNo:=0;
        VendAccrAcc:=InvHdr."BVR Vendor Accrual Acc No.";
        ExpAcc:=InvHdr."BVR Expense Accrual Acc No.";
        Vend.Get(InvHdr."Pay-to Vendor No.");
        VendPostGrp.Get(Vend."Vendor Posting Group");
        VendPostGrp.TestField("Payables Account");
        PayablesAcc:=VendPostGrp."Payables Account";
        TaxSetup.Get();
        TaxSetup.TestField("Tax Account (Purchases)");
        PurchTaxAcc:=TaxSetup."Tax Account (Purchases)";
        // Compute amounts using the exact posting logic
        CalcCustomInvoiceAmounts(InvHdr, InvoiceBaseAmt, ReceiptBaseAmt, TaxAmt, DiscountAmt, DiffBase, TotalInvoiceAmt);
        // (1) Reverse vendor accrual for receipt base (only if ReceiptBaseAmt <> 0)
        if ReceiptBaseAmt <> 0 then InsertPairGL(TempPreview, InvHdr, InvLine, InvHdr."No.", LineNo, VendAccrAcc, PayablesAcc, 'Reverse Vendor Accrual (Receipt Base)', ReceiptBaseAmt);
        // (2) Post variance to expense
        if DiffBase <> 0 then InsertPairGL(TempPreview, InvHdr, InvLine, InvHdr."No.", LineNo, ExpAcc, PayablesAcc, 'Post Difference (Invoice Base - Receipt Base)', DiffBase);
        // (3) Post tax
        if TaxAmt <> 0 then InsertPairGL(TempPreview, InvHdr, InvLine, InvHdr."No.", LineNo, PurchTaxAcc, PayablesAcc, 'Post Tax (Purchases)', TaxAmt);
        // SUMMARY lines for UI/report
        InsertSummaryAmountOnly(TempPreview, InvHdr."No.", LineNo, 'SUMMARY: Invoice Base (Direct Unit Cost * Qty)', InvoiceBaseAmt);
        InsertSummaryAmountOnly(TempPreview, InvHdr."No.", LineNo, 'SUMMARY: Receipt Base (Accrued Unit Cost * Qty)', ReceiptBaseAmt);
        InsertSummaryAmountOnly(TempPreview, InvHdr."No.", LineNo, 'SUMMARY: Difference Base (posted)', DiffBase);
        InsertSummaryAmountOnly(TempPreview, InvHdr."No.", LineNo, 'SUMMARY: Discount Amount (Line + Invoice Discount)', DiscountAmt);
        InsertSummaryAmountOnly(TempPreview, InvHdr."No.", LineNo, 'SUMMARY: Tax Amount', TaxAmt);
        InsertSummaryAmountOnly(TempPreview, InvHdr."No.", LineNo, 'SUMMARY: Total (Base + Tax)', TotalInvoiceAmt);
    end;
    local procedure CalcCustomInvoiceAmounts(InvHdr: Record "Purchase Header"; var InvoiceBaseAmt: Decimal; var ReceiptBaseAmt: Decimal; var TaxAmt: Decimal; var DiscountAmt: Decimal; var DiffBase: Decimal; var TotalInvoiceAmt: Decimal)
    var
        InvLine: Record "Purchase Line";
        RcptLine: Record "Purch. Rcpt. Line";
        SalesTaxCalc: Codeunit "Sales Tax Calculate";
        TaxGroupCode: Code[20];
        LineTax: Decimal;
        ExchRate: Decimal;
        LineBase: Decimal;
    begin
        ReceiptBaseAmt:=0;
        InvoiceBaseAmt:=0;
        TaxAmt:=0;
        DiscountAmt:=0;
        ExchRate:=1;
        InvLine.SetRange("Document Type", InvHdr."Document Type");
        InvLine.SetRange("Document No.", InvHdr."No.");
        //InvLine.SetRange("BVR From Custom Receipt", true);
        if not InvLine.FindSet()then Error('No invoice lines from custom receipts. Use Get Receipt (Custom).');
        repeat InvLine.TestField("Direct Unit Cost");
            LineBase:=Round(InvLine."Direct Unit Cost" * InvLine.Quantity, 0.01);
            InvoiceBaseAmt+=LineBase;
            if InvoiceBaseAmt = 0 then Error('Amount is zero, please check the values for Quantity and Cost');
            if(InvLine."BVR Source Rcpt No." <> '') and (InvLine."BVR Source Rcpt Line No." <> 0)then begin
                RcptLine.Get(InvLine."BVR Source Rcpt No.", InvLine."BVR Source Rcpt Line No.");
                ReceiptBaseAmt+=Round(RcptLine."BVR Accrued Unit Cost" * InvLine.Quantity, 0.01);
            end;
            DiscountAmt+=Round(InvLine."Line Discount Amount" + InvLine."Inv. Discount Amount", 0.01);
            TaxGroupCode:=InvLine."Tax Group Code";
            if(InvHdr."Tax Area Code" <> '') and (TaxGroupCode <> '')then begin
                LineTax:=SalesTaxCalc.CalculateTax(InvHdr."Tax Area Code", TaxGroupCode, InvHdr."Tax Liable", InvHdr."Posting Date", InvLine."Line Amount", InvLine.Quantity, ExchRate);
                TaxAmt+=Round(LineTax, 0.01);
            end;
        until InvLine.Next() = 0;
        DiffBase:=Round(InvoiceBaseAmt - ReceiptBaseAmt, 0.01);
        TotalInvoiceAmt:=Round(InvoiceBaseAmt + TaxAmt, 0.01);
    end;
    // ----------------- helpers -----------------
    local procedure InsertPairGL(var TempPreview: Record "BVR Posting Preview Line" temporary; Var InvHdr: Record "Purchase Header"; Var InvLine: Record "Purchase Line"; DocNo: Code[20]; var LineNo: Integer; DebitAcc: Code[20]; CreditAcc: Code[20]; Desc: Text[100]; Amt: Decimal)
    begin
        // Debit line
        LineNo+=10000;
        TempPreview.Init();
        TempPreview."Document No.":=DocNo;
        TempPreview."Line No.":=LineNo;
        TempPreview."Entry Type":=TempPreview."Entry Type"::"G/L";
        TempPreview."Account/Doc":=DebitAcc;
        TempPreview.Description:=Desc;
        TempPreview.Quantity:=0;
        TempPreview.Amount:=Amt;
        TempPreview."Bal. Account":=CreditAcc;
        TempPreview."Debit/Credit":=TempPreview."Debit/Credit"::Debit;
        TempPreview."Is Item Ledger":=false;
        TempPreview."Is Summary":=false;
        TempPreview.Insert();
        // Credit line
        LineNo+=10000;
        TempPreview.Init();
        TempPreview."Document No.":=DocNo;
        TempPreview."Line No.":=LineNo;
        TempPreview."Entry Type":=TempPreview."Entry Type"::"G/L";
        TempPreview."Account/Doc":=CreditAcc;
        TempPreview.Description:=Desc;
        TempPreview.Quantity:=0;
        TempPreview.Amount:=-Amt;
        TempPreview."Bal. Account":=DebitAcc;
        TempPreview."Debit/Credit":=TempPreview."Debit/Credit"::Credit;
        TempPreview."Is Item Ledger":=false;
        TempPreview."Is Summary":=false;
        TempPreview.Insert();
    end;
    local procedure InsertSummaryLine(var TempPreview: Record "BVR Posting Preview Line" temporary; DocNo: Code[20]; var LineNo: Integer; EntryType: Option; Acc: Code[20]; Desc: Text[100]; Amt: Decimal; BalAcc: Code[20]; DC: Option)
    begin
        LineNo+=10000;
        TempPreview.Init();
        TempPreview."Document No.":=DocNo;
        TempPreview."Line No.":=LineNo;
        TempPreview."Entry Type":=EntryType;
        TempPreview."Account/Doc":=Acc;
        TempPreview.Description:=Desc;
        TempPreview.Quantity:=0;
        TempPreview.Amount:=Amt;
        TempPreview."Bal. Account":=BalAcc;
        TempPreview."Debit/Credit":=DC;
        TempPreview."Is Item Ledger":=false;
        TempPreview."Is Summary":=true;
        TempPreview.Insert();
    end;
    local procedure InsertSummaryAmountOnly(var TempPreview: Record "BVR Posting Preview Line" temporary; DocNo: Code[20]; var LineNo: Integer; Desc: Text[100]; Amt: Decimal)
    begin
        LineNo+=10000;
        TempPreview.Init();
        TempPreview."Document No.":=DocNo;
        TempPreview."Line No.":=LineNo;
        if Desc = 'SUMMARY: Receipt Base (Accrued Unit Cost * Qty)' then TempPreview."Entry Type":=TempPreview."Entry Type"::"Receipt"
        else
            TempPreview."Entry Type":=TempPreview."Entry Type"::Invoice;
        TempPreview."Account/Doc":='';
        TempPreview.Description:=Desc;
        TempPreview.Quantity:=0;
        TempPreview.Amount:=Amt;
        TempPreview."Bal. Account":='';
        TempPreview."Debit/Credit":=TempPreview."Debit/Credit"::None;
        TempPreview."Is Item Ledger":=false;
        TempPreview."Is Summary":=true;
        TempPreview.Insert();
    end;
}
