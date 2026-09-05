/// <summary>
/// Converts a decimal amount into words, spelling out the minor unit (cents)
/// instead of the standard Business Central "nn/100" fraction notation.
///
/// Example:  1234.56 USD ->  ONE THOUSAND TWO HUNDRED THIRTY-FOUR DOLLARS AND FIFTY-SIX CENTS
///           1234.00 USD ->  ONE THOUSAND TWO HUNDRED THIRTY-FOUR DOLLARS AND NO CENTS
/// </summary>
codeunit 50135 "Amount To Words Mgt."
{

    var
        OnesTxt: array[19] of Text[20];
        TensTxt: array[9] of Text[20];
        ScaleTxt: array[4] of Text[20];
        TextsInitialized: Boolean;
        ZeroTxt: Label 'ZERO';
        HundredTxt: Label 'HUNDRED';
        AndTxt: Label 'AND';
        MinusTxt: Label 'MINUS';
        NoCentsTxt: Label 'AND NO CENTS', Comment = 'Printed when the amount has no decimals.';
        DefaultMinorSingularTxt: Label 'CENT';
        DefaultMinorPluralTxt: Label 'CENTS';
        AmountTooLargeErr: Label 'The amount %1 is too large to be written in words on a check.', Comment = '%1 = the amount';
        TextTooLongErr: Label 'The amount in words does not fit into %1 lines of %2 characters. Use the single-line (unlimited text) column on the check layout instead.', Comment = '%1 = number of lines, %2 = characters per line';
        AmountTextSingular: label 'DOLLAR', Comment = 'Default singular text for the major unit of currency (used when no currency setup is found).';
        AmountTextPlural: label 'DOLLARS', Comment = 'Default plural text for the major unit of currency (used when no currency setup is found).';
        FractionTextSingular: label 'CENT', Comment = 'Default singular text for the minor unit of currency (used when no currency setup is found).';
        FractionTextPlural: label 'CENTS', Comment = 'Default plural text for the minor unit of currency (used when no currency setup is found).';
    // =====================================================================
    //  Public API
    // =====================================================================

    /// <summary>
    /// Returns the full amount in words as a single unlimited Text.
    /// Preferred for new layouts - let RDLC / Word wrap the text.
    /// </summary>
    procedure AmountToWords(Amount: Decimal; CurrencyCode: Code[10]) Result: Text
    var
        MajorSingular: Text[30];
        MajorPlural: Text[30];
        MinorSingular: Text[30];
        MinorPlural: Text[30];
        WholeNumber: BigInteger;
        Cents: Integer;
        AbsAmount: Decimal;
    begin
        InitTexts();
        GetCurrencyTexts(CurrencyCode, MajorSingular, MajorPlural, MinorSingular, MinorPlural);

        AbsAmount := Round(Abs(Amount), 0.01);
        WholeNumber := Round(AbsAmount, 1, '<');           // truncate towards zero
        Cents := Round((AbsAmount - WholeNumber) * 100, 1);
        if Cents = 100 then begin                          // safety net for rounding drift
            WholeNumber += 1;
            Cents := 0;
        end;

        if Amount < 0 then
            Result := MinusTxt;

        Result := AppendWord(Result, NumberToWords(WholeNumber));
        Result := AppendWord(Result, Pluralize(WholeNumber, MajorSingular, MajorPlural));

        if Cents > 0 then begin
            Result := AppendWord(Result, AndTxt);
            Result := AppendWord(Result, NumberToWords(Cents));
            Result := AppendWord(Result, Pluralize(Cents, MinorSingular, MinorPlural));
        end else
            Result := AppendWord(Result, NoCentsTxt);

        OnAfterAmountToWords(Amount, CurrencyCode, Result);
    end;

    /// <summary>
    /// Drop-in replacement for the standard Check report FormatNoText.
    /// Wraps the words over 2 lines of 80 characters and keeps the leading /
    /// trailing asterisk fill used for check security.
    /// </summary>
    procedure FormatNoText(var NoText: array[2] of Text[80]; Amount: Decimal; CurrencyCode: Code[10])
    var
        Words: List of [Text];
        Word: Text;
        LineNo: Integer;
        MaxLen: Integer;
    begin
        Clear(NoText);
        LineNo := 1;
        MaxLen := MaxStrLen(NoText[1]);
        NoText[1] := '****';

        Words := AmountToWords(Amount, CurrencyCode).Split(' ');
        foreach Word in Words do
            if Word <> '' then
                if StrLen(NoText[LineNo]) + 1 + StrLen(Word) > MaxLen - 5 then begin
                    LineNo += 1;
                    if LineNo > ArrayLen(NoText) then
                        Error(TextTooLongErr, ArrayLen(NoText), MaxLen);
                    NoText[LineNo] := CopyStr(Word, 1, MaxLen);
                end else
                    NoText[LineNo] := CopyStr(DelChr(NoText[LineNo] + ' ' + Word, '<'), 1, MaxLen);

        NoText[LineNo] := CopyStr(NoText[LineNo] + ' ****', 1, MaxLen);
    end;

    // =====================================================================
    //  Number conversion
    // =====================================================================

    local procedure NumberToWords(Number: BigInteger) Result: Text
    var
        Groups: array[5] of Integer;
        Remaining: BigInteger;
        GroupCount: Integer;
        i: Integer;
    begin
        if Number = 0 then
            exit(ZeroTxt);

        Remaining := Number;
        while Remaining > 0 do begin
            GroupCount += 1;
            if GroupCount > ArrayLen(Groups) then
                Error(AmountTooLargeErr, Number);
            Groups[GroupCount] := Remaining mod 1000;
            Remaining := Remaining div 1000;
        end;

        for i := GroupCount downto 1 do
            if Groups[i] <> 0 then begin
                Result := AppendWord(Result, ThreeDigitsToWords(Groups[i]));
                if i > 1 then
                    Result := AppendWord(Result, ScaleTxt[i - 1]);
            end;
    end;

    local procedure ThreeDigitsToWords(Number: Integer) Result: Text
    var
        Remainder: Integer;
    begin
        Remainder := Number;

        if Remainder >= 100 then begin
            Result := AppendWord(Result, OnesTxt[Remainder div 100]);
            Result := AppendWord(Result, HundredTxt);
            Remainder := Remainder mod 100;
        end;

        if Remainder = 0 then
            exit(Result);

        if Remainder < 20 then
            exit(AppendWord(Result, OnesTxt[Remainder]));

        Result := AppendWord(Result, TensTxt[Remainder div 10]);
        if (Remainder mod 10) > 0 then
            Result += '-' + OnesTxt[Remainder mod 10];
    end;

    local procedure AppendWord(BaseText: Text; NewWord: Text): Text
    begin
        if NewWord = '' then
            exit(BaseText);
        if BaseText = '' then
            exit(NewWord);
        exit(BaseText + ' ' + NewWord);
    end;

    local procedure Pluralize(Number: BigInteger; Singular: Text; Plural: Text): Text
    begin
        if Number = 1 then
            exit(Singular);
        exit(Plural);
    end;

    // =====================================================================
    //  Currency wording (setup driven - no hard-coded DOLLARS/CENTS)
    // =====================================================================

    local procedure GetCurrencyTexts(CurrencyCode: Code[10]; var MajorSingular: Text[30]; var MajorPlural: Text[30]; var MinorSingular: Text[30]; var MinorPlural: Text[30])
    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();

        if (CurrencyCode = '') or (CurrencyCode = GLSetup."LCY Code") then begin
            MajorSingular := AmountTextSingular;
            MajorPlural := AmountTextPlural;
            MinorSingular := FractionTextSingular;
            MinorPlural := FractionTextPlural;
            if MajorSingular = '' then
                MajorSingular := CopyStr(GLSetup."LCY Code", 1, MaxStrLen(MajorSingular));
        end else
            if Currency.Get(CurrencyCode) then begin
                MajorSingular := AmountTextSingular;
                MajorPlural := AmountTextPlural;
                MinorSingular := FractionTextSingular;
                MinorPlural := FractionTextPlural;
                if MajorSingular = '' then
                    MajorSingular := CopyStr(CurrencyCode, 1, MaxStrLen(MajorSingular));
            end else
                MajorSingular := CopyStr(CurrencyCode, 1, MaxStrLen(MajorSingular));

        if MajorPlural = '' then
            MajorPlural := MajorSingular;
        if MinorSingular = '' then
            MinorSingular := CopyStr(DefaultMinorSingularTxt, 1, MaxStrLen(MinorSingular));
        if MinorPlural = '' then
            MinorPlural := CopyStr(DefaultMinorPluralTxt, 1, MaxStrLen(MinorPlural));
    end;

    // =====================================================================
    //  Word tables (comma separated labels -> translatable)
    // =====================================================================

    local procedure InitTexts()
    var
        OnesLbl: Label 'ONE,TWO,THREE,FOUR,FIVE,SIX,SEVEN,EIGHT,NINE,TEN,ELEVEN,TWELVE,THIRTEEN,FOURTEEN,FIFTEEN,SIXTEEN,SEVENTEEN,EIGHTEEN,NINETEEN', Comment = 'Comma separated list of the numbers 1 to 19 in words. Keep 19 entries.';
        TensLbl: Label 'TEN,TWENTY,THIRTY,FORTY,FIFTY,SIXTY,SEVENTY,EIGHTY,NINETY', Comment = 'Comma separated list of the tens 10 to 90 in words. Keep 9 entries.';
        ScaleLbl: Label 'THOUSAND,MILLION,BILLION,TRILLION', Comment = 'Comma separated list of the 10^3 scale words. Keep 4 entries.';
        Parts: List of [Text];
        i: Integer;
    begin
        if TextsInitialized then
            exit;

        Parts := OnesLbl.Split(',');
        for i := 1 to Parts.Count() do
            if i <= ArrayLen(OnesTxt) then
                OnesTxt[i] := CopyStr(DelChr(Parts.Get(i), '<>'), 1, MaxStrLen(OnesTxt[i]));

        Parts := TensLbl.Split(',');
        for i := 1 to Parts.Count() do
            if i <= ArrayLen(TensTxt) then
                TensTxt[i] := CopyStr(DelChr(Parts.Get(i), '<>'), 1, MaxStrLen(TensTxt[i]));

        Parts := ScaleLbl.Split(',');
        for i := 1 to Parts.Count() do
            if i <= ArrayLen(ScaleTxt) then
                ScaleTxt[i] := CopyStr(DelChr(Parts.Get(i), '<>'), 1, MaxStrLen(ScaleTxt[i]));

        TextsInitialized := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAmountToWords(Amount: Decimal; CurrencyCode: Code[10]; var Result: Text)
    begin
    end;
}
