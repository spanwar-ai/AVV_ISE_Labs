// codeunit 50122 "BVR Custom Rcpt Post"
// {
// Permissions = TableData "Sales Header"=rm,
//     TableData "Sales Line"=rm,
//     TableData "Purchase Line"=rimd,
//     TableData "Vendor Posting Group"=rimd,
//     TableData "Inventory Posting Group"=rimd,
//     TableData "Sales Shipment Header"=rimd,
//     TableData "Sales Shipment Line"=rimd,
//     TableData "Purch. Rcpt. Header"=rimd,
//     TableData "Purch. Rcpt. Line"=rimd,
//     TableData "Purch. Inv. Header"=rimd,
//     TableData "Purch. Inv. Line"=rimd,
//     TableData "Purch. Cr. Memo Hdr."=rimd,
//     TableData "Purch. Cr. Memo Line"=rimd,
//     TableData "Drop Shpt. Post. Buffer"=rimd,
//     TableData "Item Entry Relation"=ri,
//     TableData "Value Entry Relation"=rid,
//     TableData "Return Shipment Header"=rimd,
//     TableData "Return Shipment Line"=rimd,
//     tabledata "G/L Entry"=r;

// procedure Post(var PurchHdr: Record "Purchase Header")
// var
//     PurchLine: Record "Purchase Line";
//     GenJnlLine: Record "Gen. Journal Line";
//     GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
//     ItemJnlLine: Record "Item Journal Line";
//     ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
//     PurchPaySetup: Record "Purchases & Payables Setup";
//     NoSeriesMgt: Codeunit "No. Series";
//     RcptHdr: Record "Purch. Rcpt. Header";
//     RcptLine: Record "Purch. Rcpt. Line";
//     ItemRec: Record Item;
//     QtyToReceive: Decimal;
//     AmountLCY: Decimal;
//     TotalAccrualAmt: Decimal;
//     PostedRcptNo: Code[20];
//     LineNo: Integer;
//     DimSetId: Integer;
//     ExpAcc: Code[20];
//     VendAccrAcc: Code[20];
//     ApprMgt: Codeunit "BVR Cust Rcpt Appr Mgt";
// begin
//     PurchHdr.TestField("Document Type", PurchHdr."Document Type"::Order);
//     PurchHdr.TestField("BVR Receive PO", true);
//     PurchHdr.TestField("Posting Date");
//     PurchHdr.TestField("BVR Vendor Accrual Acc No.");
//     PurchHdr.TestField("BVR Expense Accrual Acc No.");
//     if PurchHdr."BVR Custom Rcpt Posted" then Error('Already posted. Posted Receipt No.: %1', PurchHdr."BVR Posted Rcpt No.");
//     // Block posting while a native approval request is still open
//     if PurchHdr."BVR Requires Approval" then
//         if ApprMgt.HasOpenApprovalEntries(PurchHdr.RecordId) then
//             Error('Cannot post: Custom Receipt %1 is pending approval.', PurchHdr."No.");
//     ExpAcc:=PurchHdr."BVR Expense Accrual Acc No.";
//     VendAccrAcc:=PurchHdr."BVR Vendor Accrual Acc No.";
//     PurchPaySetup.Get();
//     PurchPaySetup.TestField("Posted Receipt Nos.");
//     PostedRcptNo:=NoSeriesMgt.GetNextNo(PurchPaySetup."Posted Receipt Nos.", PurchHdr."Posting Date", true);
//     // Create standard Posted Receipt Header
//     RcptHdr.Init();
//     RcptHdr."No.":=PostedRcptNo;
//     RcptHdr."Order No.":=PurchHdr."No.";
//     RcptHdr."Buy-from Vendor No.":=PurchHdr."Buy-from Vendor No.";
//     RcptHdr."Pay-to Vendor No.":=PurchHdr."Pay-to Vendor No.";
//     RcptHdr."Posting Date":=PurchHdr."Posting Date";
//     RcptHdr."Document Date":=PurchHdr."Document Date";
//     //RcptHdr."External Document No." := PurchHdr."External Document No.";
//     RcptHdr."Dimension Set ID":=PurchHdr."Dimension Set ID";
//     RcptHdr."BVR Custom Receipt":=true;
//     RcptHdr."BVR Vendor Accrual Acc No.":=PurchHdr."BVR Vendor Accrual Acc No.";
//     RcptHdr."BVR Expense Accrual Acc No.":=PurchHdr."BVR Expense Accrual Acc No.";
//     RcptHdr.Insert(true);
//     PurchLine.SetRange("Document Type", PurchHdr."Document Type");
//     PurchLine.SetRange("Document No.", PurchHdr."No.");
//     PurchLine.SetFilter(Type, '%1|%2', PurchLine.Type::Item, PurchLine.Type::"G/L Account");
//     if not PurchLine.FindSet(true)then Error('No lines to post.');
//     LineNo:=0;
//     TotalAccrualAmt:=0;
//     repeat QtyToReceive:=PurchLine."Qty. to Receive";
//         if QtyToReceive = 0 then QtyToReceive:=PurchLine.Quantity - PurchLine."Quantity Received";
//         if QtyToReceive = 0 then continue;
//         DimSetId:=PurchLine."Dimension Set ID";
//         if DimSetId = 0 then DimSetId:=PurchHdr."Dimension Set ID";
//         AmountLCY:=Round(PurchLine."Direct Unit Cost" * QtyToReceive, 0.01);
//         // Accumulate accrual posting amount (clubbed for the whole receipt)
//         TotalAccrualAmt+=AmountLCY;
//         // Create Item Ledger Entry for inventory items (quantity-only)
//         if PurchLine.Type = PurchLine.Type::Item then begin
//             ItemRec.Get(PurchLine."No.");
//             if ItemRec.Type = ItemRec.Type::Inventory then begin
//                 Clear(ItemJnlLine);
//                 ItemJnlLine.Init();
//                 ItemJnlLine.Validate("Journal Template Name", 'ITEM');
//                 ItemJnlLine.Validate("Journal Batch Name", 'DEFAULT');
//                 ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Purchase);
//                 ItemJnlLine.Validate("Document No.", PurchHdr."No.");
//                 ItemJnlLine.Validate("Posting Date", PurchHdr."Posting Date");
//                 ItemJnlLine.Validate("Item No.", ItemRec."No.");
//                 ItemJnlLine.Validate(Quantity, QtyToReceive);
//                 ItemJnlLine.Validate("Location Code", PurchLine."Location Code");
//                 ItemJnlLine.Validate("Unit Amount", 0);
//                 ItemJnlLine."Dimension Set ID":=DimSetId;
//                 ItemJnlLine.Validate("Source Type", ItemJnlLine."Source Type"::Vendor);
//                 ItemJnlLine.Validate("Source No.", PurchHdr."Buy-from Vendor No.");
//                 ItemJnlPostLine.RunWithCheck(ItemJnlLine);
//             end;
//         end;
//         // Insert Posted Receipt Line with custom markers + accrued values (line level kept)
//         LineNo+=10000;
//         RcptLine.Init();
//         RcptLine."Document No.":=RcptHdr."No.";
//         RcptLine."Line No.":=LineNo;
//         RcptLine.Type:=PurchLine.Type;
//         RcptLine."No.":=PurchLine."No.";
//         RcptLine.Description:=PurchLine.Description;
//         RcptLine."Location Code":=PurchLine."Location Code";
//         RcptLine.Quantity:=QtyToReceive;
//         RcptLine."Order No.":=PurchHdr."No.";
//         RcptLine."Order Line No.":=PurchLine."Line No.";
//         RcptLine."Posting Date":=PurchHdr."Posting Date";
//         RcptLine."Dimension Set ID":=DimSetId;
//         RcptLine."BVR Custom Receipt":=true;
//         RcptLine."BVR Accrued Unit Cost":=PurchLine."Direct Unit Cost";
//         RcptLine."BVR Accrued Amount":=AmountLCY;
//         RcptLine.Insert(true);
//         // Update PO line received quantities
//         PurchLine."Quantity Received":=PurchLine."Quantity Received" + QtyToReceive;
//         PurchLine."Qty. to Receive":=0;
//         PurchLine.Modify(true);
//     until PurchLine.Next() = 0;
//     // Post single clubbed accrual entry for the whole receipt:
//     //   Debit: Expense Accrual Account
//     //   Credit: Vendor Accrual Account
//     if TotalAccrualAmt <> 0 then begin
//         Clear(GenJnlLine);
//         GenJnlLine.Init();
//         GenJnlLine.Validate("Journal Template Name", 'GENERAL');
//         GenJnlLine.Validate("Journal Batch Name", 'DEFAULT');
//         GenJnlLine.Validate("Posting Date", PurchHdr."Posting Date");
//         GenJnlLine.Validate("Document Date", PurchHdr."Document Date");
//         GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Invoice);
//         GenJnlLine.Validate("Document No.", RcptHdr."No.");
//         GenJnlLine.Validate("External Document No.", PurchHdr."Vendor Invoice No.");
//         GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
//         GenJnlLine.Validate("Account No.", ExpAcc);
//         GenJnlLine.Validate(Amount, TotalAccrualAmt);
//         GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
//         GenJnlLine.Validate("Bal. Account No.", VendAccrAcc);
//         // Since lines are clubbed, use header dimensions for the accrual entry
//         GenJnlLine."Dimension Set ID":=PurchHdr."Dimension Set ID";
//         GenJnlPostLine.RunWithCheck(GenJnlLine);
//     end;
//     PurchHdr."BVR Custom Rcpt Posted":=true;
//     PurchHdr."BVR Posted Rcpt No.":=RcptHdr."No.";
//     PurchHdr.Modify(true);
//     Message('Custom Receipt posted. PO: %1, Posted Receipt: %2', PurchHdr."No.", RcptHdr."No.");
// end;
// }
