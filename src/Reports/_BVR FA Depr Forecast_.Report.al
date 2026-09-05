// Forward-looking depreciation listing: one row per fixed asset per forecast month, in the column
// order of the Dynamics GP "FA Depreciation Forecast" the finance team printed before the move to
// Business Central, so the two can be read side by side during the changeover.
//
// The monthly charge is a FLAT straight-line amount - the same figure in every period, as asked for.
// It is NOT what codeunit "Calculate Depreciation" would post: BC's straight-line runs on days, so a
// 31-day month is charged more than a 30-day one and the amounts wobble from period to period. This
// report divides the depreciable basis by the asset's life in months and repeats that one number,
// which is what the GP report did and what makes the columns comparable.
//
// Three columns have no Business Central equivalent and are mapped by agreement rather than by any
// standard: Asst ID Suffix reads "Component of Main Asset", Asst Type reads "FA Subclass Code" and
// Structure ID reads "FA Location Code". They are here for GP parity - nothing in BC posts by them.
//
// "YTD Depr Amt" keeps the GP heading, but like the GP report it carries the PERIOD amount and does
// not accumulate. The heading is wrong and was wrong in GP; it is kept so the two reports line up.
//   //AAV.SP
report 50172 "BVR FA Depr Forecast"
{
    Caption = 'FA Depreciation Forecast';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = "BVRFADeprForecastLayout";

    dataset
    {
        dataitem(FixedAsset; "Fixed Asset")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "FA Location Code";

            // Page furniture and column headings. They hang off the asset dataitem because that is
            // the only place with rows - an empty result prints no table, which is the honest
            // outcome for a filter that matched nothing.   //AAV.SP
            column(BVRReportCaption; BVRReportCaptionLbl)
            {
            }
            column(BVRHeaderText; BVRHeaderText)
            {
            }
            column(BVRCompanyName; BVRCompanyName)
            {
            }
            column(BVRPrintedOn; BVRPrintedOnText)
            {
            }
            column(BVRAssetIdCaption; BVRAssetIdCaptionLbl)
            {
            }
            column(BVRAssetIdSuffixCaption; BVRAssetIdSuffixCaptionLbl)
            {
            }
            column(BVRAssetClassIdCaption; BVRAssetClassIdCaptionLbl)
            {
            }
            column(BVRAssetDescCaption; BVRAssetDescCaptionLbl)
            {
            }
            column(BVRAssetTypeCaption; BVRAssetTypeCaptionLbl)
            {
            }
            column(BVRStructureIdCaption; BVRStructureIdCaptionLbl)
            {
            }
            column(BVRAcqDateCaption; BVRAcqDateCaptionLbl)
            {
            }
            column(BVRFAPrdCaption; BVRFAPrdCaptionLbl)
            {
            }
            column(BVRFAYrCaption; BVRFAYrCaptionLbl)
            {
            }
            column(BVRAcqCostCaption; BVRAcqCostCaptionLbl)
            {
            }
            column(BVRDeprAmtCaption; BVRDeprAmtCaptionLbl)
            {
            }
            column(BVRAssetId; "No.")
            {
            }
            column(BVRAssetIdSuffix; "Component of Main Asset")
            {
            }
            column(BVRAssetClassId; "FA Class Code")
            {
            }
            column(BVRAssetDesc; Description)
            {
            }
            column(BVRAssetType; "FA Subclass Code")
            {
            }
            column(BVRStructureId; "FA Location Code")
            {
            }
            column(BVRAcqDate; BVRAcqDateText)
            {
            }
            column(BVRAcqCost; BVRAcqCost)
            {
                AutoFormatType = 0;
            }

            // One row per forecast month. The count is fixed for the whole run, so every asset covers
            // the same span and the report reads down a column as well as across a row.   //AAV.SP
            dataitem(BVRPeriodLoop; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));

                column(BVRFAPrd; BVRFAPrd)
                {
                }
                column(BVRFAYr; BVRFAYr)
                {
                }
                column(BVRDeprAmt; BVRDeprAmt)
                {
                    AutoFormatType = 0;
                }

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, BVRNoOfMonths);
                end;

                trigger OnAfterGetRecord()
                var
                    BVRPeriodDate: Date;
                begin
                    BVRPeriodDate := CalcDate(StrSubstNo(BVRAddMonthsTok, Number - 1), BVRFirstPeriod);
                    BVRFAPrd := Date2DMY(BVRPeriodDate, 2);
                    BVRFAYr := Date2DMY(BVRPeriodDate, 3);

                    // Flat for the asset's whole life, then nothing. Charging on past the ending date
                    // would make the report add up to more than the asset is worth, which is the one
                    // way a forecast can be actively misleading rather than merely approximate.
                    if (BVRDeprEndingDate <> 0D) and (BVRPeriodDate > BVRDeprEndingDate) then
                        BVRDeprAmt := 0
                    else
                        BVRDeprAmt := BVRMonthlyAmount;
                end;
            }

            trigger OnPreDataItem()
            begin
                SetRange(Inactive, false);
            end;

            trigger OnAfterGetRecord()
            var
                BVRFADeprBook: Record "FA Depreciation Book";
            begin
                // No book for this asset, or already sold: nothing to forecast, and a row of zeroes
                // would only have to be explained.
                if not BVRFADeprBook.Get("No.", BVRDeprBookCode) then
                    CurrReport.Skip();
                if BVRFADeprBook."Disposal Date" <> 0D then
                    CurrReport.Skip();

                BVRFADeprBook.CalcFields("Acquisition Cost", "Salvage Value");
                BVRAcqCost := BVRFADeprBook."Acquisition Cost";
                BVRAcqDateText := Format(BVRFADeprBook."Acquisition Date", 0, BVRDateFormatTok);
                BVRDeprEndingDate := BVRFADeprBook."Depreciation Ending Date";
                BVRMonthlyAmount := BVRMonthlyDepreciation(BVRFADeprBook);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About FA Depreciation Forecast';
        AboutText = 'Lists a flat monthly straight-line depreciation charge for each fixed asset over a chosen number of months. The amount is the depreciable basis divided by the asset''s life in months, repeated in every period - it is a planning figure, not what posting would calculate day by day.';

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(BVRDeprBookCode; BVRDeprBookCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Depreciation Book';
                        ToolTip = 'Specifies the depreciation book the forecast is built from. Assets with no card in this book are left out.';
                        TableRelation = "Depreciation Book";
                        ShowMandatory = true;
                    }
                    field(BVRStartingDate; BVRStartingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first month of the forecast. Any date inside the month will do - the forecast always starts on the first of it.';
                    }
                    field(BVRNoOfMonths; BVRNoOfMonths)
                    {
                        ApplicationArea = All;
                        Caption = 'No. of Months';
                        ToolTip = 'Specifies how many months to forecast, starting with the month of the starting date.';
                        MinValue = 1;
                        MaxValue = 600;
                    }
                }
            }
        }

        trigger OnOpenPage()
        var
            BVRFASetup: Record "FA Setup";
        begin
            if BVRDeprBookCode = '' then
                if BVRFASetup.Get() then
                    BVRDeprBookCode := BVRFASetup."Default Depr. Book";
            if BVRStartingDate = 0D then
                BVRStartingDate := WorkDate();
            if BVRNoOfMonths = 0 then
                BVRNoOfMonths := 12;
        end;
    }

    rendering
    {
        layout("BVRFADeprForecastLayout")
        {
            Type = RDLC;
            LayoutFile = './ReportLayouts/BVRFADeprForecast.rdl';
            Caption = 'FA Depreciation Forecast';
            Summary = 'Fixed assets listed one row per forecast month, with a flat straight-line depreciation amount, in the Dynamics GP column order.';
        }
    }

    trigger OnPreReport()
    var
        BVRCompanyInformation: Record "Company Information";
    begin
        if BVRDeprBookCode = '' then
            Error(BVRNoBookErr);
        if BVRNoOfMonths <= 0 then
            BVRNoOfMonths := 12;
        if BVRStartingDate = 0D then
            BVRStartingDate := WorkDate();

        BVRFirstPeriod := CalcDate(BVRStartOfMonthTok, BVRStartingDate);
        BVRHeaderText :=
          StrSubstNo(
            BVRHeaderTok, BVRDeprBookCode,
            Format(BVRFirstPeriod, 0, BVRDateFormatTok),
            Format(CalcDate(StrSubstNo(BVRAddMonthsTok, BVRNoOfMonths - 1), BVRFirstPeriod), 0, BVRDateFormatTok));

        if BVRCompanyInformation.Get() then
            BVRCompanyName := BVRCompanyInformation.Name;
        BVRPrintedOnText := CopyStr(Format(CurrentDateTime()), 1, MaxStrLen(BVRPrintedOnText));
    end;

    // The flat monthly charge. Straight-line by definition: the depreciable basis spread evenly over
    // the asset's life, so every period carries the same figure.
    //
    // Basis is acquisition cost less salvage. BC stores Salvage Value as a NEGATIVE amount, so it is
    // added, not subtracted - subtracting it would inflate the basis by twice the salvage.
    //
    // The life comes from whichever of the book's three ways of stating it is filled in, in the order
    // BC itself prefers: an explicit number of years/months, then a straight-line percentage, then a
    // fixed annual amount. A book that states none of them cannot be forecast and returns zero rather
    // than a guess - the row still prints, so the asset is visibly present and visibly unforecastable
    // instead of silently missing.   //AAV.SP
    local procedure BVRMonthlyDepreciation(var BVRFADeprBook: Record "FA Depreciation Book"): Decimal
    var
        BVRBasis: Decimal;
        BVRMonths: Decimal;
    begin
        BVRBasis := BVRFADeprBook."Acquisition Cost" + BVRFADeprBook."Salvage Value";
        if BVRBasis = 0 then
            exit(0);

        BVRMonths := BVRFADeprBook."No. of Depreciation Years" * 12 + BVRFADeprBook."No. of Depreciation Months";

        // Nothing stated on the card, but both ends of the life are known - count the months between
        // them. Inclusive of the first month, so a 1 Jan - 31 Dec life is twelve months, not eleven.
        if (BVRMonths = 0) and
           (BVRFADeprBook."Depreciation Starting Date" <> 0D) and
           (BVRFADeprBook."Depreciation Ending Date" <> 0D)
        then
            BVRMonths :=
              (Date2DMY(BVRFADeprBook."Depreciation Ending Date", 3) - Date2DMY(BVRFADeprBook."Depreciation Starting Date", 3)) * 12 +
              (Date2DMY(BVRFADeprBook."Depreciation Ending Date", 2) - Date2DMY(BVRFADeprBook."Depreciation Starting Date", 2)) + 1;

        if BVRMonths > 0 then
            exit(Round(BVRBasis / BVRMonths));

        if BVRFADeprBook."Straight-Line %" <> 0 then
            exit(Round(BVRBasis * BVRFADeprBook."Straight-Line %" / 100 / 12));

        if BVRFADeprBook."Fixed Depr. Amount" <> 0 then
            exit(Round(BVRFADeprBook."Fixed Depr. Amount" / 12));

        exit(0);
    end;

    var
        BVRDeprBookCode: Code[10];
        BVRStartingDate: Date;
        BVRNoOfMonths: Integer;
        BVRFirstPeriod: Date;
        BVRAcqCost: Decimal;
        BVRAcqDateText: Text[30];
        BVRDeprEndingDate: Date;
        BVRMonthlyAmount: Decimal;
        BVRFAPrd: Integer;
        BVRFAYr: Integer;
        BVRDeprAmt: Decimal;
        BVRHeaderText: Text;
        BVRCompanyName: Text[100];
        BVRPrintedOnText: Text[50];
        BVRReportCaptionLbl: Label 'FA Depreciation Forecast';
        BVRAssetIdCaptionLbl: Label 'Asst ID';
        BVRAssetIdSuffixCaptionLbl: Label 'Asst ID Suffix';
        BVRAssetClassIdCaptionLbl: Label 'Asst Class ID';
        BVRAssetDescCaptionLbl: Label 'Asst Desc';
        BVRAssetTypeCaptionLbl: Label 'Asst Type';
        BVRStructureIdCaptionLbl: Label 'Structure ID';
        BVRAcqDateCaptionLbl: Label 'Acq Date';
        BVRFAPrdCaptionLbl: Label 'FA Prd';
        BVRFAYrCaptionLbl: Label 'FA Yr';
        BVRAcqCostCaptionLbl: Label 'Acq Cost';
        BVRDeprAmtCaptionLbl: Label 'YTD Depr Amt';
        BVRDateFormatTok: Label '<Day,2>-<Month,2>-<Year4>', Locked = true;
        BVRStartOfMonthTok: Label '<-CM>', Locked = true;
        BVRAddMonthsTok: Label '<+%1M>', Locked = true, Comment = '%1 = number of months to add';
        BVRHeaderTok: Label 'Book %1  -  %2 to %3', Comment = '%1 = depreciation book code, %2 = first period, %3 = last period';
        BVRNoBookErr: Label 'Choose a depreciation book before running the forecast.';
}
