codeunit 50251 "BVR Batch Dist Mgt"
{
    // The G/L distribution a document WILL book, worked out before it is posted.
    //
    // Shared by every document batch edit list - purchase invoice, purchase credit memo, sales
    // invoice, sales credit memo - because the arithmetic is the same argument four times over and
    // four copies of it would drift. Those reports are thin: they lay the answer out, they do not
    // work it out. Only the Purchase Receipt report keeps its own logic, and rightly so - a receipt
    // books an accrual, not a distribution.
    //
    // Everything is DERIVED, not observed. Before posting there are no G/L entries to read, so the
    // account each line will hit is worked out by following the same rules the posting engine
    // follows, in the same order - see LineAccountPurch and LineAccountSales. Where an account cannot
    // be known without running the post itself, the amount is reported as unaccounted rather than
    // guessed at.
    //
    // SIGN CONVENTION: a positive amount in the buffer is a DEBIT, a negative one a CREDIT. Which way
    // round a document's lines fall is the only thing separating the four cases:
    //
    //   purchase invoice      lines DEBIT   (expense/inventory)   payables    CREDIT
    //   purchase credit memo  lines CREDIT                        payables    DEBIT
    //   sales invoice         lines CREDIT  (revenue)             receivables DEBIT
    //   sales credit memo     lines DEBIT                         receivables CREDIT
    //
    // so it reduces to one factor, LineSign, with the balancing account taking the opposite.   //AAV.SP

    // Returns how many distribution rows were built; 0 means nothing could be resolved at all.
    // Note comes back non-blank when the reader has to be told something: nothing resolved, an amount
    // left unaccounted, or a distribution that does not balance.
    procedure BuildForPurchase(var PurchaseHeader: Record "Purchase Header"; var Buffer: Record "BVR Posting Preview Line" temporary; var Note: Text[250]) RowCount: Integer
    var
        PurchLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VendPostingGroup: Record "Vendor Posting Group";
        AccountNo: Code[20];
        Dim1: Code[20];
        Dim2: Code[20];
        LineSign: Integer;
        VATAmount: Decimal;
        TotalInclVAT: Decimal;
        Unresolved: Decimal;
    begin
        InitBuffer(Buffer, Note);
        // A credit memo is an invoice run backwards, and that is the whole of the difference.
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
            LineSign := -1
        else
            LineSign := 1;

        PurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchLine.SetFilter(Type, '<>%1', PurchLine.Type::" ");
        if PurchLine.FindSet() then
            repeat
                LineDimensions(PurchLine."Dimension Set ID", PurchaseHeader."Dimension Set ID", Dim1, Dim2);
                if LineAccountPurch(PurchLine, AccountNo) then
                    AddRow(Buffer, RowCount, AccountNo, Dim1, Dim2, LineSign * PurchLine.Amount)
                else
                    Unresolved += PurchLine.Amount;
                VATAmount += PurchLine."Amount Including VAT" - PurchLine.Amount;
                TotalInclVAT += PurchLine."Amount Including VAT";
            until PurchLine.Next() = 0;

        if VATAmount <> 0 then
            AddRow(Buffer, RowCount, PurchaseVATAccount(PurchaseHeader), '', '', LineSign * VATAmount);

        // The balancing side: the vendor carries the whole document, tax included.
        if Vendor.Get(PurchaseHeader."Pay-to Vendor No.") then
            if VendPostingGroup.Get(Vendor."Vendor Posting Group") then begin
                HeaderDimensions(PurchaseHeader."Dimension Set ID", Dim1, Dim2);
                AddRow(Buffer, RowCount, VendPostingGroup."Payables Account", Dim1, Dim2, -LineSign * TotalInclVAT);
            end;

        Note := BuildNote(Buffer, RowCount, Unresolved);
        exit(RowCount);
    end;

    procedure BuildForSales(var SalesHeader: Record "Sales Header"; var Buffer: Record "BVR Posting Preview Line" temporary; var Note: Text[250]) RowCount: Integer
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        CustPostingGroup: Record "Customer Posting Group";
        AccountNo: Code[20];
        Dim1: Code[20];
        Dim2: Code[20];
        LineSign: Integer;
        VATAmount: Decimal;
        TotalInclVAT: Decimal;
        Unresolved: Decimal;
    begin
        InitBuffer(Buffer, Note);
        // The mirror of the purchase side: a sales invoice CREDITS its lines and debits the customer.
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
            LineSign := 1
        else
            LineSign := -1;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        if SalesLine.FindSet() then
            repeat
                LineDimensions(SalesLine."Dimension Set ID", SalesHeader."Dimension Set ID", Dim1, Dim2);
                if LineAccountSales(SalesLine, AccountNo) then
                    AddRow(Buffer, RowCount, AccountNo, Dim1, Dim2, LineSign * SalesLine.Amount)
                else
                    Unresolved += SalesLine.Amount;
                VATAmount += SalesLine."Amount Including VAT" - SalesLine.Amount;
                TotalInclVAT += SalesLine."Amount Including VAT";
            until SalesLine.Next() = 0;

        if VATAmount <> 0 then
            AddRow(Buffer, RowCount, SalesVATAccount(SalesHeader), '', '', LineSign * VATAmount);

        if Customer.Get(SalesHeader."Bill-to Customer No.") then
            if CustPostingGroup.Get(Customer."Customer Posting Group") then begin
                HeaderDimensions(SalesHeader."Dimension Set ID", Dim1, Dim2);
                AddRow(Buffer, RowCount, CustPostingGroup."Receivables Account", Dim1, Dim2, -LineSign * TotalInclVAT);
            end;

        Note := BuildNote(Buffer, RowCount, Unresolved);
        exit(RowCount);
    end;

    // Reads one built row back out, split into the two money columns the layout prints.
    procedure ReadRow(var Buffer: Record "BVR Posting Preview Line" temporary; RowNo: Integer; var AccountNo: Code[20]; var AccountName2: Text[100]; var AccountType2: Text[50]; var Dim1: Code[20]; var Dim2: Code[20]; var Debit: Decimal; var Credit: Decimal): Boolean
    begin
        Clear(AccountNo);
        Clear(AccountName2);
        Clear(AccountType2);
        Clear(Dim1);
        Clear(Dim2);
        Clear(Debit);
        Clear(Credit);

        Buffer.Reset();
        if not Buffer.Get('', RowNo) then
            exit(false);

        AccountNo := Buffer."Account/Doc";
        AccountName2 := Buffer.Description;
        AccountType2 := CopyStr(Buffer."Line Description", 1, 50);
        Dim1 := Buffer."Source Dimension 1";
        Dim2 := Buffer."Source Dimension 2";
        if Buffer.Amount > 0 then
            Debit := Buffer.Amount
        else
            Credit := -Buffer.Amount;
        exit(true);
    end;

    // The account a PURCHASE line will post to, by the same rules the posting engine uses and in the
    // same order. False where the account cannot be known without running the post - fixed assets,
    // charges and resources all resolve through setup this does not read.   //AAV.SP
    local procedure LineAccountPurch(var PurchaseLine: Record "Purchase Line"; var AccountNo: Code[20]): Boolean
    var
        Item: Record Item;
        GenPostingSetup: Record "General Posting Setup";
        InvtPostingSetup: Record "Inventory Posting Setup";
    begin
        Clear(AccountNo);

        // The accrual redirect wins. "BVR Std Get Receipt Lines" stamps this account onto every line
        // it pulls from a receipt, and its OnPrepareLineOnBeforeSetAccount subscriber forces the
        // debit there whatever the line's own posting setup says.
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

    // The account a SALES line will post to. The REVENUE side only: an item line also books cost of
    // goods sold against inventory, but that pair is computed from the item's COST at posting time -
    // average cost, adjustments and all - which is not knowable from an unposted document. Printing a
    // guess at it would be the report inventing a number, so it is left out and said so in the report
    // rather than shown wrong.   //AAV.SP
    local procedure LineAccountSales(var SalesLine: Record "Sales Line"; var AccountNo: Code[20]): Boolean
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        Clear(AccountNo);

        case SalesLine.Type of
            SalesLine.Type::"G/L Account":
                begin
                    AccountNo := SalesLine."No.";
                    exit(AccountNo <> '');
                end;
            SalesLine.Type::Item,
            SalesLine.Type::Resource:
                begin
                    if not GenPostingSetup.Get(
                        SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group")
                    then
                        exit(false);
                    AccountNo := GenPostingSetup."Sales Account";
                    exit(AccountNo <> '');
                end;
        end;
        exit(false);
    end;

    local procedure PurchaseVATAccount(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        PurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchLine.FindSet() then
            repeat
                if PurchLine."Amount Including VAT" <> PurchLine.Amount then
                    if VATPostingSetup.Get(PurchLine."VAT Bus. Posting Group", PurchLine."VAT Prod. Posting Group") then
                        exit(VATPostingSetup."Purchase VAT Account");
            until PurchLine.Next() = 0;
    end;

    local procedure SalesVATAccount(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                if SalesLine."Amount Including VAT" <> SalesLine.Amount then
                    if VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then
                        exit(VATPostingSetup."Sales VAT Account");
            until SalesLine.Next() = 0;
    end;

    // A line's two global dimensions, falling back to the header's where the line has no set of its
    // own - which is what posting does.
    local procedure LineDimensions(LineDimSetID: Integer; HeaderDimSetID: Integer; var Dim1: Code[20]; var Dim2: Code[20])
    begin
        if LineDimSetID <> 0 then begin
            HeaderDimensions(LineDimSetID, Dim1, Dim2);
            exit;
        end;
        HeaderDimensions(HeaderDimSetID, Dim1, Dim2);
    end;

    local procedure HeaderDimensions(DimSetID: Integer; var Dim1: Code[20]; var Dim2: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        Clear(Dim1);
        Clear(Dim2);
        DimMgt.UpdateGlobalDimFromDimSetID(DimSetID, Dim1, Dim2);
    end;

    local procedure InitBuffer(var Buffer: Record "BVR Posting Preview Line" temporary; var Note: Text[250])
    begin
        Buffer.Reset();
        Buffer.DeleteAll();
        Clear(Note);
    end;

    // Merges into the existing row for the same account AND dimension pair, so what prints is the
    // entries the G/L will hold rather than the document's lines.
    local procedure AddRow(var Buffer: Record "BVR Posting Preview Line" temporary; var RowCount: Integer; AccountNo: Code[20]; Dim1: Code[20]; Dim2: Code[20]; Amount: Decimal)
    begin
        if (AccountNo = '') or (Amount = 0) then
            exit;

        Buffer.Reset();
        Buffer.SetRange("Account/Doc", AccountNo);
        Buffer.SetRange("Source Dimension 1", Dim1);
        Buffer.SetRange("Source Dimension 2", Dim2);
        if Buffer.FindFirst() then begin
            Buffer.Amount += Amount;
            Buffer.Modify();
            exit;
        end;

        RowCount += 1;
        Buffer.Init();
        Buffer."Document No." := '';
        Buffer."Line No." := RowCount;
        Buffer."Account/Doc" := AccountNo;
        Buffer."Source Dimension 1" := Dim1;
        Buffer."Source Dimension 2" := Dim2;
        Buffer.Amount := Amount;
        Buffer.Description := AccountName(AccountNo);
        Buffer."Line Description" := AccountType(AccountNo);
        Buffer.Insert();
    end;

    // Anything the report could not account for is said out loud. A silent omission on an edit list
    // is worse than no edit list, because it reads as "checked and fine".   //AAV.SP
    local procedure BuildNote(var Buffer: Record "BVR Posting Preview Line" temporary; RowCount: Integer; Unresolved: Decimal): Text[250]
    var
        OutOfBalance: Decimal;
    begin
        if RowCount = 0 then
            exit(NoDistributionTxt);

        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                OutOfBalance += Buffer.Amount;
            until Buffer.Next() = 0;

        if Unresolved <> 0 then
            exit(CopyStr(StrSubstNo(UnresolvedTxt, Unresolved), 1, 250));
        if OutOfBalance <> 0 then
            exit(CopyStr(StrSubstNo(OutOfBalanceTxt, OutOfBalance), 1, 250));
    end;

    local procedure AccountName(AccountNo: Code[20]): Text[100]
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(AccountNo) then
            exit(GLAccount.Name);
    end;

    local procedure AccountType(AccountNo: Code[20]): Text[100]
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(AccountNo) then
            exit(CopyStr(Format(GLAccount."Income/Balance"), 1, 100));
    end;

    var
        NoDistributionTxt: Label 'Nothing will be distributed - this document has no line whose account can be determined.';
        UnresolvedTxt: Label '%1 of this document posts to accounts that are resolved during posting and are not shown above.', Comment = '%1 = the unaccounted amount';
        OutOfBalanceTxt: Label 'The distribution above is out of balance by %1. Check the document before posting the batch.', Comment = '%1 = the difference between debits and credits';
}
