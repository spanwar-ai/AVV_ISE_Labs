codeunit 50142 "BVR Custom Inv Post"
{
    Permissions = TableData "Sales Header"=rm,
        TableData "Sales Line"=rm,
        TableData "Purchase Line"=rimd,
        TableData "Vendor Posting Group"=rimd,
        TableData "Inventory Posting Group"=rimd,
        TableData "Sales Shipment Header"=rimd,
        TableData "Sales Shipment Line"=rimd,
        TableData "Purch. Rcpt. Header"=rimd,
        TableData "Purch. Rcpt. Line"=rimd,
        TableData "Purch. Inv. Header"=rimd,
        TableData "Purch. Inv. Line"=rimd,
        TableData "Purch. Cr. Memo Hdr."=rimd,
        TableData "Purch. Cr. Memo Line"=rimd,
        TableData "Drop Shpt. Post. Buffer"=rimd,
        TableData "Item Entry Relation"=ri,
        TableData "Value Entry Relation"=rid,
        TableData "Return Shipment Header"=rimd,
        TableData "Return Shipment Line"=rimd,
        tabledata "G/L Entry"=r;

    procedure Post(var InvHdr: Record "Purchase Header")
    var
        InvLine: Record "Purchase Line";
        RcptLine: Record "Purch. Rcpt. Line";
        Vend: Record Vendor;
        VendPostGrp: Record "Vendor Posting Group";
        TaxSetup: Record "Tax Setup";
        SalesTaxCalc: Codeunit "Sales Tax Calculate";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PurchPaySetup: Record "Purchases & Payables Setup";
        NoSeriesMgt: Codeunit "No. Series";
        PostedInvHdr: Record "Purch. Inv. Header";
        PostedInvLine: Record "Purch. Inv. Line";
        PayablesAcc: Code[20];
        VendAccrAcc: Code[20];
        ExpAcc: Code[20];
        PurchTaxAcc: Code[20];
        ReceiptBaseAmt: Decimal;
        InvoiceBaseAmt: Decimal;
        TaxAmt: Decimal;
        TotalInvoiceAmt: Decimal;
        DiffBase: Decimal;
        PostInvNo: Code[20];
        LineNo: Integer;
        DimSetId: Integer;
        TaxGroupCode: Code[20];
        LineTax: Decimal;
        ExchRate: Decimal;
    begin
        InvHdr.TestField("Document Type", InvHdr."Document Type"::Invoice);
        InvHdr.TestField("Buy-from Vendor No.");
        InvHdr.TestField("Pay-to Vendor No.");
        InvHdr.TestField("Posting Date");
        InvHdr.TestField("BVR Vendor Accrual Acc No.");
        InvHdr.TestField("BVR Expense Accrual Acc No.");
        if InvHdr."BVR Custom Inv Posted" then Error('Already posted. Posted Invoice No.: %1', InvHdr."BVR Posted Inv No.");
        VendAccrAcc:=InvHdr."BVR Vendor Accrual Acc No.";
        ExpAcc:=InvHdr."BVR Expense Accrual Acc No.";
        Vend.Get(InvHdr."Pay-to Vendor No.");
        VendPostGrp.Get(Vend."Vendor Posting Group");
        VendPostGrp.TestField("Payables Account");
        PayablesAcc:=VendPostGrp."Payables Account";
        // Tax setup (Sales Tax engine). Tax account for purchases is defined here.
        TaxSetup.Get();
        TaxSetup.TestField("Tax Account (Purchases)");
        PurchTaxAcc:=TaxSetup."Tax Account (Purchases)";
        ReceiptBaseAmt:=0;
        InvoiceBaseAmt:=0;
        TaxAmt:=0;
        InvLine.SetRange("Document Type", InvHdr."Document Type");
        InvLine.SetRange("Document No.", InvHdr."No.");
        //InvLine.SetRange("BVR From Custom Receipt", true);
        if not InvLine.FindSet()then Error('No invoice lines from custom receipts. Use Get Receipt (Custom).');
        // Exchange rate factor for Sales Tax Calculate (use 1 for LCY, can be enhanced)
        ExchRate:=1;
        repeat InvLine.TestField("Direct Unit Cost");
            DimSetId:=InvLine."Dimension Set ID";
            if DimSetId = 0 then DimSetId:=InvHdr."Dimension Set ID";
            InvoiceBaseAmt+=Round(InvLine."Direct Unit Cost" * InvLine.Quantity, 0.01);
            if InvoiceBaseAmt = 0 then error('Amount is zero, please check the values for Quantity and Cost');
            // Pull accrued amount from source receipt line
            if(InvLine."BVR Source Rcpt No." <> '') and (InvLine."BVR Source Rcpt Line No." <> 0)then begin
                RcptLine.Get(InvLine."BVR Source Rcpt No.", InvLine."BVR Source Rcpt Line No.");
                ReceiptBaseAmt+=Round(RcptLine."BVR Accrued Unit Cost" * InvLine.Quantity, 0.01);
            end;
            // Sales/Use tax calculation by Tax Area Code + Tax Group Code
            TaxGroupCode:=InvLine."Tax Group Code";
            if(InvHdr."Tax Area Code" <> '') and (TaxGroupCode <> '')then begin
                LineTax:=SalesTaxCalc.CalculateTax(InvHdr."Tax Area Code", TaxGroupCode, InvHdr."Tax Liable", InvHdr."Posting Date", InvLine."Line Amount", InvLine.Quantity, ExchRate);
                TaxAmt+=Round(LineTax, 0.01);
            end;
        until InvLine.Next() = 0;
        DiffBase:=Round(InvoiceBaseAmt - ReceiptBaseAmt, 0.01);
        TotalInvoiceAmt:=Round(InvoiceBaseAmt + TaxAmt, 0.01);
        // Create standard Posted Purchase Invoice for history
        PurchPaySetup.Get();
        PurchPaySetup.TestField("Posted Invoice Nos.");
        PostInvNo:=NoSeriesMgt.GetNextNo(PurchPaySetup."Posted Invoice Nos.", InvHdr."Posting Date", true);
        // 1) Reverse vendor accrual for receipt BASE amount and move to payables
        //    Debit Vendor Accrual, Credit Payables
        if ReceiptBaseAmt <> 0 then begin
            Clear(GenJnlLine);
            GenJnlLine.Init();
            GenJnlLine.Validate("Journal Template Name", 'GENERAL');
            GenJnlLine.Validate("Journal Batch Name", 'DEFAULT');
            GenJnlLine.Validate("Posting Date", InvHdr."Posting Date");
            GenJnlLine.Validate("Document Date", InvHdr."Document Date");
            GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Invoice);
            GenJnlLine.Validate("Document No.", PostInvNo);
            GenJnlLine.Validate("External Document No.", InvHdr."Vendor Invoice No.");
            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
            GenJnlLine.Validate("Account No.", VendAccrAcc);
            GenJnlLine.Validate(Amount, ReceiptBaseAmt);
            GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
            GenJnlLine.Validate("Bal. Account No.", PayablesAcc);
            GenJnlLine."Dimension Set ID":=InvHdr."Dimension Set ID";
            GenJnlPostLine.RunWithCheck(GenJnlLine);
        end;
        // 2) Post BASE variance to expense (only difference) and balance to payables
        if DiffBase <> 0 then begin
            Clear(GenJnlLine);
            GenJnlLine.Init();
            GenJnlLine.Validate("Journal Template Name", 'GENERAL');
            GenJnlLine.Validate("Journal Batch Name", 'DEFAULT');
            GenJnlLine.Validate("Posting Date", InvHdr."Posting Date");
            GenJnlLine.Validate("Document Date", InvHdr."Document Date");
            GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Invoice);
            GenJnlLine.Validate("Document No.", PostInvNo);
            GenJnlLine.Validate("External Document No.", InvHdr."Vendor Invoice No.");
            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
            GenJnlLine.Validate("Account No.", ExpAcc);
            GenJnlLine.Validate(Amount, DiffBase);
            GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
            GenJnlLine.Validate("Bal. Account No.", PayablesAcc);
            GenJnlLine."Dimension Set ID":=InvHdr."Dimension Set ID";
            GenJnlPostLine.RunWithCheck(GenJnlLine);
        end;
        // 3) Post SALES/USE tax to Tax Account (Purchases) and balance to payables
        if TaxAmt <> 0 then begin
            Clear(GenJnlLine);
            GenJnlLine.Init();
            GenJnlLine.Validate("Journal Template Name", 'GENERAL');
            GenJnlLine.Validate("Journal Batch Name", 'DEFAULT');
            GenJnlLine.Validate("Posting Date", InvHdr."Posting Date");
            GenJnlLine.Validate("Document Date", InvHdr."Document Date");
            GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Invoice);
            GenJnlLine.Validate("Document No.", PostInvNo);
            GenJnlLine.Validate("External Document No.", InvHdr."Vendor Invoice No.");
            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
            GenJnlLine.Validate("Account No.", PurchTaxAcc);
            GenJnlLine.Validate(Amount, TaxAmt);
            GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
            GenJnlLine.Validate("Bal. Account No.", PayablesAcc);
            GenJnlLine."Dimension Set ID":=InvHdr."Dimension Set ID";
            GenJnlPostLine.RunWithCheck(GenJnlLine);
        end;
        PostedInvHdr.Init();
        PostedInvHdr."No.":=PostInvNo;
        PostedInvHdr."Buy-from Vendor No.":=InvHdr."Buy-from Vendor No.";
        PostedInvHdr."Pay-to Vendor No.":=InvHdr."Pay-to Vendor No.";
        PostedInvHdr."Posting Date":=InvHdr."Posting Date";
        PostedInvHdr."Document Date":=InvHdr."Document Date";
        PostedInvHdr."Vendor Invoice No.":=InvHdr."Vendor Invoice No.";
        //PostedInvHdr."External Document No." := InvHdr."Vendor Invoice No.";
        PostedInvHdr."Shortcut Dimension 1 Code":=InvHdr."Shortcut Dimension 1 Code";
        PostedInvHdr."Shortcut Dimension 2 Code":=InvHdr."Shortcut Dimension 2 Code";
        PostedInvHdr."Dimension Set ID":=InvHdr."Dimension Set ID";
        PostedInvHdr.Insert(true);
        // Copy lines to posted invoice lines
        LineNo:=0;
        InvLine.Reset();
        InvLine.SetRange("Document Type", InvHdr."Document Type");
        InvLine.SetRange("Document No.", InvHdr."No.");
        if InvLine.FindSet()then repeat LineNo+=10000;
                PostedInvLine.Init();
                PostedInvLine."Document No.":=PostedInvHdr."No.";
                PostedInvLine."Line No.":=LineNo;
                PostedInvLine.Type:=InvLine.Type;
                PostedInvLine."No.":=InvLine."No.";
                PostedInvLine.Description:=InvLine.Description;
                PostedInvLine.Quantity:=InvLine.Quantity;
                PostedInvLine."Direct Unit Cost":=InvLine."Direct Unit Cost";
                PostedInvLine."Line Amount":=InvLine."Line Amount";
                PostedInvLine."Location Code":=InvLine."Location Code";
                PostedInvLine."Dimension Set ID":=InvLine."Dimension Set ID";
                PostedInvLine.Insert(true);
            until InvLine.Next() = 0;
        // Mark receipt lines as invoiced (custom)
        InvLine.Reset();
        InvLine.SetRange("Document Type", InvHdr."Document Type");
        InvLine.SetRange("Document No.", InvHdr."No.");
        InvLine.SetRange("BVR From Custom Receipt", true);
        if InvLine.FindSet()then repeat if(InvLine."BVR Source Rcpt No." <> '') and (InvLine."BVR Source Rcpt Line No." <> 0)then begin
                    RcptLine.Get(InvLine."BVR Source Rcpt No.", InvLine."BVR Source Rcpt Line No.");
                    RcptLine."BVR Invoiced Qty":=RcptLine."BVR Invoiced Qty" + InvLine.Quantity;
                    RcptLine.Modify(true);
                end;
            until InvLine.Next() = 0;
        // Mark invoice header
        InvHdr."BVR Custom Inv Posted":=true;
        InvHdr."BVR Posted Inv No.":=PostedInvHdr."No.";
        InvHdr.Modify(true);
        Message('Custom Invoice posted. Invoice: %1, Posted Invoice: %2. Total=%3 (Base=%4, Tax=%5)', InvHdr."No.", PostedInvHdr."No.", TotalInvoiceAmt, InvoiceBaseAmt, TaxAmt);
    end;
}
