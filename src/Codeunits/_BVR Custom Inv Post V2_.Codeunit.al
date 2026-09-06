codeunit 50144 "BVR Custom Inv Post V2"
{
    // Optimized rewrite of codeunit 50142 "BVR Custom Inv Post".
    //  - All journal lines are collected into a temporary Gen. Journal Line buffer first,
    //    then posted in a single pass (classic BC "build buffer, then post" pattern).
    //  - The four near-identical posting blocks are replaced by one helper (AddBufferLine).
    //  - Type = "G/L Account" invoice lines are combined by account and posted directly to
    //    the account on the line; they are kept out of the receipt-accrual math.

    Permissions = TableData "Sales Header" = rm,
        TableData "Sales Line" = rm,
        TableData "Purchase Line" = rimd,
        TableData "Vendor Posting Group" = rimd,
        TableData "Inventory Posting Group" = rimd,
        TableData "Sales Shipment Header" = rimd,
        TableData "Sales Shipment Line" = rimd,
        TableData "Purch. Rcpt. Header" = rimd,
        TableData "Purch. Rcpt. Line" = rimd,
        TableData "Purch. Inv. Header" = rimd,
        TableData "Purch. Inv. Line" = rimd,
        TableData "Purch. Cr. Memo Hdr." = rimd,
        TableData "Purch. Cr. Memo Line" = rimd,
        TableData "Drop Shpt. Post. Buffer" = rimd,
        TableData "Item Entry Relation" = ri,
        TableData "Value Entry Relation" = rid,
        TableData "Return Shipment Header" = rimd,
        TableData "Return Shipment Line" = rimd,
        tabledata "G/L Entry" = r;

    var
        TemplateNameTxt: Label 'GENERAL', Locked = true;
        BatchNameTxt: Label 'DEFAULT', Locked = true;
        AlreadyPostedErr: Label 'Already posted. Posted Invoice No.: %1', Comment = '%1 = Posted Invoice No.';
        NoLinesErr: Label 'No invoice lines from custom receipts. Use Get Receipt (Custom).';
        ZeroAmtErr: Label 'Amount is zero, please check the values for Quantity and Cost';
        MissingRcptErr: Label 'Source receipt line %1 / %2 no longer exists.', Comment = '%1 = Receipt No., %2 = Receipt Line No.';
        PostedMsg: Label 'Custom Invoice posted. Invoice: %1, Posted Invoice: %2. Total=%3 (Base=%4, G/L=%5)', Comment = '%1 Invoice No., %2 Posted Invoice No., %3 Total, %4 Base, %5 G/L';

    procedure Post(var InvHdr: Record "Purchase Header")
    var
        InvLine: Record "Purchase Line";
        RcptLine: Record "Purch. Rcpt. Line";
        Vend: Record Vendor;
        VendPostGrp: Record "Vendor Posting Group";
        PurchPaySetup: Record "Purchases & Payables Setup";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        NoSeriesMgt: Codeunit "No. Series";
        GLAccAmounts: Dictionary of [Code[20], Decimal];
        PayablesAcc: Code[20];
        VendAccrAcc: Code[20];
        ExpAcc: Code[20];
        PostInvNo: Code[20];
        GLAcc: Code[20];
        ReceiptBaseAmt: Decimal;
        InvoiceBaseAmt: Decimal;
        GLTotal: Decimal;
        DiffBase: Decimal;
        TotalInvoiceAmt: Decimal;
        LineAmt: Decimal;
        BufferLineNo: Integer;
        balAccType: Enum "Gen. Journal Account Type";
    begin
        InvHdr.TestField("Document Type", InvHdr."Document Type"::Invoice);
        InvHdr.TestField("Buy-from Vendor No.");
        InvHdr.TestField("Pay-to Vendor No.");
        InvHdr.TestField("Posting Date");
        InvHdr.TestField("BVR Vendor Accrual Acc No.");
        InvHdr.TestField("BVR Expense Accrual Acc No.");
        if InvHdr."BVR Custom Inv Posted" then
            Error(AlreadyPostedErr, InvHdr."BVR Posted Inv No.");

        VendAccrAcc := InvHdr."BVR Vendor Accrual Acc No.";
        ExpAcc := InvHdr."BVR Expense Accrual Acc No.";
        Vend.Get(InvHdr."Pay-to Vendor No.");
        VendPostGrp.Get(Vend."Vendor Posting Group");
        VendPostGrp.TestField("Payables Account");
        PayablesAcc := VendPostGrp."Payables Account";
        PayablesAcc := vend."No.";
        InvLine.SetRange("Document Type", InvHdr."Document Type");
        InvLine.SetRange("Document No.", InvHdr."No.");
        if not InvLine.FindSet() then
            Error(NoLinesErr);

        // --- Pass 1: accumulate amounts (no posting yet) ---
        repeat
            if InvLine.Type = InvLine.Type::"G/L Account" then begin
                // G/L Account lines carry no receipt accrual: combine them by account.
                InvLine.TestField("No.");
                LineAmt := Round(InvLine."Line Amount", 0.01);
                if GLAccAmounts.ContainsKey(InvLine."No.") then
                    GLAccAmounts.Set(InvLine."No.", GLAccAmounts.Get(InvLine."No.") + LineAmt)
                else
                    GLAccAmounts.Add(InvLine."No.", LineAmt);
                GLTotal += LineAmt;
            end else begin
                InvLine.TestField("Direct Unit Cost");
                InvoiceBaseAmt += Round(InvLine."Direct Unit Cost" * InvLine.Quantity, 0.01);
                // Pull accrued amount from source receipt line
                if (InvLine."BVR Source Rcpt No." <> '') and (InvLine."BVR Source Rcpt Line No." <> 0) then begin
                    if not RcptLine.Get(InvLine."BVR Source Rcpt No.", InvLine."BVR Source Rcpt Line No.") then
                        Error(MissingRcptErr, InvLine."BVR Source Rcpt No.", InvLine."BVR Source Rcpt Line No.");
                    ReceiptBaseAmt += Round(RcptLine."BVR Accrued Unit Cost" * InvLine.Quantity, 0.01);
                end;
            end;
        until InvLine.Next() = 0;

        if (InvoiceBaseAmt = 0) and (GLTotal = 0) then
            Error(ZeroAmtErr);
        DiffBase := Round(InvoiceBaseAmt - ReceiptBaseAmt, 0.01);
        TotalInvoiceAmt := Round(InvoiceBaseAmt + GLTotal, 0.01);

        PurchPaySetup.Get();
        PurchPaySetup.TestField("Posted Invoice Nos.");
        PostInvNo := NoSeriesMgt.GetNextNo(PurchPaySetup."Posted Invoice Nos.", InvHdr."Posting Date", true);

        // --- Pass 2: build the journal buffer (still no posting) ---
        // 1) Reverse vendor accrual for the receipt BASE amount:   Dr Vendor Accrual / Cr Payables
        AddBufferLine(TempGenJnlLine, BufferLineNo, InvHdr, PostInvNo, VendAccrAcc, ReceiptBaseAmt, PayablesAcc, BalAccType::Vendor,
                      InvHdr."BVR Vendor Accrual Dim 1 Code", InvHdr."BVR Vendor Accrual Dim 2 Code");
        // 2) Post BASE variance to expense (difference only):       Dr Expense / Cr Payables
        AddBufferLine(TempGenJnlLine, BufferLineNo, InvHdr, PostInvNo, ExpAcc, DiffBase, PayablesAcc, BalAccType::Vendor,
                      InvHdr."BVR WH Shortcut Dim 1 Code", InvHdr."BVR WH Shortcut Dim 2 Code");
        // 3) Post combined G/L Account lines, one entry per account: Dr G/L Account / Cr Payables
        foreach GLAcc in GLAccAmounts.Keys() do
            AddBufferLine(TempGenJnlLine, BufferLineNo, InvHdr, PostInvNo, GLAcc, Round(GLAccAmounts.Get(GLAcc), 0.01), PayablesAcc, BalAccType::Vendor,
                          '', '');

        // --- Pass 3: post the whole buffer in one loop ---
        if TempGenJnlLine.FindSet() then
            repeat
                GenJnlPostLine.RunWithCheck(TempGenJnlLine);
            until TempGenJnlLine.Next() = 0;

        // --- History + custom bookkeeping ---
        CreatePostedInvoice(InvHdr, InvLine, PostInvNo);
        UpdateReceiptInvoicedQty(InvHdr, InvLine, RcptLine);

        InvHdr."BVR Custom Inv Posted" := true;
        InvHdr."BVR Posted Inv No." := PostInvNo;
        InvHdr.Modify(true);

        Message(PostedMsg, InvHdr."No.", PostInvNo, TotalInvoiceAmt, InvoiceBaseAmt, GLTotal);
    end;

    // Builds one fully-validated Gen. Journal Line in the temp buffer (skips zero amounts).
    // Dim1/Dim2 are the dimensions THIS line posts under, blank meaning "the invoice header's own".
    // They exist so the vendor accrual reversal lands on the same dimensions the receipt accrued
    // under - see codeunit "BVR Std Rcpt Accrual".   //AAV.SP
    local procedure AddBufferLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary;
                                    var LineNo: Integer; InvHdr: Record "Purchase Header";
                                    DocNo: Code[20]; AccNo: Code[20]; Amt: Decimal;
                                    BalAccNo: Code[20]; BalAccType: Enum "Gen. Journal Account Type";
                                    Dim1: Code[20]; Dim2: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        if Amt = 0 then
            exit;
        LineNo += 10000;
        TempGenJnlLine.Init();
        TempGenJnlLine."Line No." := LineNo;
        TempGenJnlLine.Validate("Journal Template Name", TemplateNameTxt);
        TempGenJnlLine.Validate("Journal Batch Name", BatchNameTxt);
        TempGenJnlLine.Validate("Posting Date", InvHdr."Posting Date");
        TempGenJnlLine.Validate("Document Date", InvHdr."Document Date");
        TempGenJnlLine.Validate("Document Type", TempGenJnlLine."Document Type"::Invoice);
        TempGenJnlLine.Validate("Document No.", DocNo);
        TempGenJnlLine.Validate("External Document No.", InvHdr."Vendor Invoice No.");
        TempGenJnlLine.Validate("Account Type", TempGenJnlLine."Account Type"::"G/L Account");
        TempGenJnlLine.Validate("Account No.", AccNo);
        TempGenJnlLine.Validate(Amount, Amt);
        // TempGenJnlLine.Validate("Bal. Account Type", TempGenJnlLine."Bal. Account Type"::"G/L Account");
        // TempGenJnlLine.Validate("Bal. Account No.", BalAccNo);
        tempGenJnlLine.Validate("Bal. Account Type", BalAccType);
        tempGenJnlLine.Validate("Bal. Account No.", BalAccNo);
        // Start from the invoice header's dimension set, then derive the two SHORTCUT codes back out
        // of it.
        //
        // Both parts are needed. G/L Entry.CopyFromGenJnlLine copies "Global Dimension 1/2 Code" from
        // the line's shortcut codes and "Dimension Set ID" from the set, independently. Assigning only
        // the set - which is all this did before - posts entries whose set is right but whose Global
        // Dimension 1/2 columns are BLANK, and those columns are what dimension analysis and most
        // reports actually read.   //AAV.SP
        TempGenJnlLine."Dimension Set ID" := InvHdr."Dimension Set ID";
        DimMgt.UpdateGlobalDimFromDimSetID(
            TempGenJnlLine."Dimension Set ID",
            TempGenJnlLine."Shortcut Dimension 1 Code",
            TempGenJnlLine."Shortcut Dimension 2 Code");
        // ...then let this line's own codes override the two globals, so the accrual reversal posts
        // under the dimensions the receipt accrued under. Validate (not assignment) rebuilds the set to
        // match - it applies a delta, so any NON-global dimensions on the invoice survive. Blank means
        // "keep the invoice's own", never "post without a dimension".   //AAV.SP
        if Dim1 <> '' then
            TempGenJnlLine.Validate("Shortcut Dimension 1 Code", Dim1);
        if Dim2 <> '' then
            TempGenJnlLine.Validate("Shortcut Dimension 2 Code", Dim2);
        TempGenJnlLine.Insert();
    end;

    local procedure CreatePostedInvoice(var InvHdr: Record "Purchase Header"; var InvLine: Record "Purchase Line"; PostInvNo: Code[20])
    var
        PostedInvHdr: Record "Purch. Inv. Header";
        PostedInvLine: Record "Purch. Inv. Line";
        LineNo: Integer;
    begin
        PostedInvHdr.Init();
        PostedInvHdr."No." := PostInvNo;
        PostedInvHdr."Buy-from Vendor No." := InvHdr."Buy-from Vendor No.";
        PostedInvHdr."Buy-from Vendor Name" := InvHdr."Buy-from Vendor Name";

        PostedInvHdr."Pay-to Vendor No." := InvHdr."Pay-to Vendor No.";
        postedInvHdr."Pay-to Name" := InvHdr."Pay-to Name";
        postedInvHdr."Pay-to Address" := InvHdr."Pay-to Address";
        postedInvHdr."Pay-to Address 2" := InvHdr."Pay-to Address 2";
        postedInvHdr."Pay-to City" := InvHdr."Pay-to City";
        postedInvHdr."Pay-to Post Code" := InvHdr."Pay-to Post Code";
        postedInvHdr."Pay-to County" := InvHdr."Pay-to County";
        postedInvHdr."Pay-to Country/Region Code" := InvHdr."Pay-to Country/Region Code";
        postedInvHdr."Pay-to Contact" := InvHdr."Pay-to Contact";
        postedInvHdr."Buy-from Address" := InvHdr."Buy-from Address";
        postedInvHdr."Buy-from Address 2" := InvHdr."Buy-from Address 2";
        postedInvHdr."Buy-from City" := InvHdr."Buy-from City";
        postedInvHdr."Buy-from Post Code" := InvHdr."Buy-from Post Code";
        postedInvHdr."Buy-from County" := InvHdr."Buy-from County";
        postedInvHdr."Buy-from Country/Region Code" := InvHdr."Buy-from Country/Region Code";
        postedInvHdr."Buy-from Contact" := InvHdr."Buy-from Contact";
        postedInvHdr."Order Date" := InvHdr."Order Date";
        postedInvHdr."Posting Description" := InvHdr."Posting Description";
        postedInvHdr."Your Reference" := InvHdr."Your Reference";
        postedInvHdr."Currency Code" := InvHdr."Currency Code";
        postedInvHdr."Currency Factor" := InvHdr."Currency Factor";
        postedInvHdr."Prices Including VAT" := InvHdr."Prices Including VAT";
        postedInvHdr."VAT Bus. Posting Group" := InvHdr."VAT Bus. Posting Group";
        postedInvHdr."VAT Registration No." := InvHdr."VAT Registration No.";
        PostedInvHdr."Posting Date" := InvHdr."Posting Date";
        PostedInvHdr."Document Date" := InvHdr."Document Date";
        PostedInvHdr."Vendor Invoice No." := InvHdr."Vendor Invoice No.";
        PostedInvHdr."Payment Terms Code" := InvHdr."Payment Terms Code";
        PostedInvHdr."Due Date" := InvHdr."Due Date";
        PostedInvHdr."Location Code" := InvHdr."Location Code";
        PostedInvHdr."Shipment Method Code" := InvHdr."Shipment Method Code";
        PostedInvHdr."Shortcut Dimension 1 Code" := InvHdr."Shortcut Dimension 1 Code";
        PostedInvHdr."Shortcut Dimension 2 Code" := InvHdr."Shortcut Dimension 2 Code";
        PostedInvHdr."Dimension Set ID" := InvHdr."Dimension Set ID";
        PostedInvHdr.Insert(true);

        InvLine.Reset();
        InvLine.SetRange("Document Type", InvHdr."Document Type");
        InvLine.SetRange("Document No.", InvHdr."No.");
        if InvLine.FindSet() then
            repeat
                LineNo += 10000;
                PostedInvLine.Init();
                PostedInvLine."Document No." := PostedInvHdr."No.";
                PostedInvLine."Line No." := LineNo;
                PostedInvLine.Type := InvLine.Type;
                PostedInvLine."No." := InvLine."No.";
                PostedInvLine.Description := InvLine.Description;
                PostedInvLine.Quantity := InvLine.Quantity;
                PostedInvLine."Direct Unit Cost" := InvLine."Direct Unit Cost";
                postedInvLine.Amount := InvLine.Amount;
                postedInvLine."Unit of Measure Code" := InvLine."Unit of Measure Code";
                postedInvLine."VAT %" := InvLine."VAT %";
                postedInvLine."VAT Bus. Posting Group" := InvLine."VAT Bus. Posting Group";
                postedInvLine."VAT Prod. Posting Group" := InvLine."VAT Prod. Posting Group";
                postedInvLine."Allow Invoice Disc." := InvLine."Allow Invoice Disc.";
                postedInvLine."Inv. Discount Amount" := InvLine."Inv. Discount Amount";
                postedInvLine."Amount Including VAT" := InvLine."Amount Including VAT";
                PostedInvLine."Line Amount" := InvLine."Line Amount";
                PostedInvLine."Location Code" := InvLine."Location Code";
                postedInvLine."Shortcut Dimension 1 Code" := InvLine."Shortcut Dimension 1 Code";
                postedInvLine."Shortcut Dimension 2 Code" := InvLine."Shortcut Dimension 2 Code";

                PostedInvLine."Dimension Set ID" := InvLine."Dimension Set ID";
                PostedInvLine.Insert(true);
            until InvLine.Next() = 0;
    end;

    local procedure UpdateReceiptInvoicedQty(var InvHdr: Record "Purchase Header"; var InvLine: Record "Purchase Line"; var RcptLine: Record "Purch. Rcpt. Line")
    begin
        InvLine.Reset();
        InvLine.SetRange("Document Type", InvHdr."Document Type");
        InvLine.SetRange("Document No.", InvHdr."No.");
        InvLine.SetRange("BVR From Custom Receipt", true);
        if InvLine.FindSet() then
            repeat
                if (InvLine."BVR Source Rcpt No." <> '') and (InvLine."BVR Source Rcpt Line No." <> 0) then
                    if RcptLine.Get(InvLine."BVR Source Rcpt No.", InvLine."BVR Source Rcpt Line No.") then begin
                        RcptLine."BVR Invoiced Qty" := RcptLine."BVR Invoiced Qty" + InvLine.Quantity;
                        RcptLine.Modify(true);
                    end;
            until InvLine.Next() = 0;
    end;
}
