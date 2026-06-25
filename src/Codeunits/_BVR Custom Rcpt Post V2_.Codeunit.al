codeunit 50123 "BVR Custom Rcpt Post V2"
{
    // SAFE V2:
    // Posts ONLY lines where Qty. to Receive > 0 (no fallback to remaining)
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

    procedure Post(var PurchHdr: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        SrcLine: Record "Purchase Line";
        Setup: Record "Purchases & Payables Setup";
        NoSeries: Codeunit "No. Series";
        RcptHdr: Record "Purch. Rcpt. Header";
        RcptLine: Record "Purch. Rcpt. Line";
        QtyToReceive: Decimal;
        RemQty: Decimal;
        LineNo: Integer;
        AmountLCY: Decimal;
        LinesPosted: Integer;
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        PurchPaySetup: Record "Purchases & Payables Setup";
        NoSeriesMgt: Codeunit "No. Series";
        ItemRec: Record Item;
        TotalAccrualAmt: Decimal;
        PostedRcptNo: Code[20];
        DimSetId: Integer;
        ExpAcc: Code[20];
        VendAccrAcc: Code[20];
        ApprMgt: Codeunit "BVR Cust Rcpt Appr Mgt";
    begin
        PurchHdr.TestField("Document Type", PurchHdr."Document Type"::Order);
        PurchHdr.TestField("BVR Receive PO", true);
        if PurchHdr."BVR Custom Rcpt Posted" then Error('Already posted. Posted Receipt No.: %1', PurchHdr."BVR Posted Rcpt No.");
        // Block posting while a native approval request is still open
        if PurchHdr."BVR Requires Approval" then
            if ApprMgt.HasOpenApprovalEntries(PurchHdr.RecordId) then
                Error('Cannot post: Custom Receipt %1 is pending approval.', PurchHdr."No.");
        Setup.Get();
        Setup.TestField("Posted Receipt Nos.");
        ExpAcc:=PurchHdr."BVR Expense Accrual Acc No.";
        VendAccrAcc:=PurchHdr."BVR Vendor Accrual Acc No.";
        RcptHdr.Init();
        RcptHdr."No.":=NoSeries.GetNextNo(Setup."Posted Receipt Nos.", PurchHdr."Posting Date", true);
        RcptHdr.TransferFields(PurchHdr);
        RcptHdr."Order No.":=PurchHdr."No.";
        RcptHdr."Buy-from Vendor No.":=PurchHdr."Buy-from Vendor No.";
        RcptHdr."Posting Date":=PurchHdr."Posting Date";
        RcptHdr."BVR Custom Receipt":=true;
        RcptHdr."BVR Vendor Accrual Acc No.":=PurchHdr."BVR Vendor Accrual Acc No.";
        RcptHdr."BVR Expense Accrual Acc No.":=PurchHdr."BVR Expense Accrual Acc No.";
        RcptHdr.Insert(true);
        PurchLine.SetRange("Document Type", PurchHdr."Document Type");
        PurchLine.SetRange("Document No.", PurchHdr."No.");
        LineNo:=0;
        LinesPosted:=0;
        TotalAccrualAmt:=0;
        if PurchLine.FindSet(true)then repeat QtyToReceive:=PurchLine."Qty. to Receive";
                if QtyToReceive <= 0 then continue;
                PurchLine.TestField("BVR Source PO No.");
                PurchLine.TestField("BVR Source PO Line No.");
                PurchLine.TestField("Direct Unit Cost");
                SrcLine.Get(SrcLine."Document Type"::Order, PurchLine."BVR Source PO No.", PurchLine."BVR Source PO Line No.");
                RemQty:=SrcLine.Quantity - SrcLine."Quantity Received";
                if RemQty <= 0 then Error('Nothing remaining to receive for PO %1 line %2.', PurchLine."BVR Source PO No.", PurchLine."BVR Source PO Line No.");
                if QtyToReceive > RemQty then Error('Qty. to Receive (%1) exceeds remaining (%2) for PO %3 line %4.', QtyToReceive, RemQty, PurchLine."BVR Source PO No.", PurchLine."BVR Source PO Line No.");
                DimSetId:=PurchLine."Dimension Set ID";
                if DimSetId = 0 then DimSetId:=PurchHdr."Dimension Set ID";
                AmountLCY:=Round(PurchLine."Direct Unit Cost" * QtyToReceive, 0.01);
                TotalAccrualAmt+=AmountLCY;
                if QtyToReceive <> 0 then If TotalAccrualAmt = 0 then error('Check amount for the lines');
                // Assign the receipt line no. up front so the item entry can be linked to it.   //AAV.SP
                LineNo += 10000;
                if PurchLine.Type = PurchLine.Type::Item then begin
                    ItemRec.Get(PurchLine."No.");
                    if ItemRec.Type = ItemRec.Type::Inventory then begin
                        Clear(ItemJnlLine);
                        ItemJnlLine.Init();
                        ItemJnlLine.Validate("Journal Template Name", 'ITEM');
                        ItemJnlLine.Validate("Journal Batch Name", 'DEFAULT');
                        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Purchase);
                        // Link the item entry to the POSTED RECEIPT so the standard
                        // Undo Receipt can find and reverse it.   //AAV.SP
                        ItemJnlLine.Validate("Document No.", RcptHdr."No.");
                        ItemJnlLine."Document Type" := ItemJnlLine."Document Type"::"Purchase Receipt";
                        ItemJnlLine."Document Line No." := LineNo;
                        ItemJnlLine.Validate("Posting Date", PurchHdr."Posting Date");
                        ItemJnlLine.Validate("Item No.", ItemRec."No.");
                        ItemJnlLine.Validate(Quantity, QtyToReceive);
                        ItemJnlLine.Validate("Location Code", PurchLine."Location Code");
                        ItemJnlLine.Validate("Unit Amount", 0);
                        ItemJnlLine."Dimension Set ID":=DimSetId;
                        ItemJnlLine.Validate("Source Type", ItemJnlLine."Source Type"::Vendor);
                        ItemJnlLine.Validate("Source No.", PurchHdr."Buy-from Vendor No.");
                        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
                    end;
                end;
                RcptLine.Init();
                RcptLine."Document No.":=RcptHdr."No.";
                RcptLine."Line No.":=LineNo;
                RcptLine.Type:=PurchLine.Type;
                RcptLine."No.":=PurchLine."No.";
                RcptLine.Description:=PurchLine.Description;
                RcptLine."Location Code":=PurchLine."Location Code";
                RcptLine.Quantity:=QtyToReceive;
                RcptLine."BVR Custom Receipt":=true;
                RcptLine."BVR Source PO No.":=PurchLine."BVR Source PO No.";
                RcptLine."BVR Source PO Line No.":=PurchLine."BVR Source PO Line No.";
                RcptLine."Unit Cost":=PurchLine."Direct Unit Cost";
                RcptLine."BVR Accrued Unit Cost":=PurchLine."Direct Unit Cost";
                RcptLine."BVR Accrued Amount":=AmountLCY;
                RcptLine.Insert(true);
                // update source PO
                SrcLine."Quantity Received":=SrcLine."Quantity Received" + QtyToReceive;
                SrcLine."Qty. to Receive":=0;
                SrcLine."Outstanding Quantity":=(SrcLine.Quantity - SrcLine."Quantity Received");
                SrcLine.Modify(true);
                // update custom receipt line
                PurchLine."Quantity Received":=PurchLine."Quantity Received" + QtyToReceive;
                PurchLine."Qty. to Receive":=0;
                PurchLine."BVR Remaining Qty":=(SrcLine.Quantity - SrcLine."Quantity Received");
                PurchLine.Modify(true);
                LinesPosted+=1;
            until PurchLine.Next() = 0;
        if TotalAccrualAmt <> 0 then begin
            Clear(GenJnlLine);
            GenJnlLine.Init();
            GenJnlLine.Validate("Journal Template Name", 'GENERAL');
            GenJnlLine.Validate("Journal Batch Name", 'DEFAULT');
            GenJnlLine.Validate("Posting Date", PurchHdr."Posting Date");
            GenJnlLine.Validate("Document Date", PurchHdr."Document Date");
            GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Invoice);
            GenJnlLine.Validate("Document No.", RcptHdr."No.");
            GenJnlLine.Validate("External Document No.", PurchHdr."Vendor Invoice No.");
            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
            GenJnlLine.Validate("Account No.", ExpAcc);
            GenJnlLine.Validate(Amount, TotalAccrualAmt);
            GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
            GenJnlLine.Validate("Bal. Account No.", VendAccrAcc);
            // Since lines are clubbed, use header dimensions for the accrual entry
            GenJnlLine."Dimension Set ID":=PurchHdr."Dimension Set ID";
            GenJnlPostLine.RunWithCheck(GenJnlLine);
        end;
        if LinesPosted = 0 then Error('Nothing to post. Enter Qty. to Receive and check Cost on at least one line.');
        PurchHdr."BVR Custom Rcpt Posted":=true;
        PurchHdr."BVR Posted Rcpt No.":=RcptHdr."No.";
        PurchHdr."BVR Receipt Status":=PurchHdr."BVR Receipt Status"::Posted;   //AAV.SP
        PurchHdr.Modify(true);
        Message('Custom Receipt posted (SAFE V2). Posted Receipt No.: %1', RcptHdr."No.");
    end;
}
