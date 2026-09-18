codeunit 50180 "BVR GL Dim Correction Mgt"
{
    // Bulk dimension correction on posted G/L entries, driven from table "BVR GL Dim Correction".
    //
    // The G/L update is deliberately the same one BC's own dimension correction performs - see
    // codeunit "Dim Correction Run".UpdateGLEntry:
    //
    //   1. build the target dimension SET from the entry's existing set, changing only the global
    //      dimensions the staged row asks about and leaving every other dimension on the entry alone;
    //   2. write the new set on the entry;
    //   3. derive "Global Dimension 1/2 Code" back out of that set.
    //
    // Step 3 is not optional. The G/L Entry carries the two global dimensions in their OWN columns as
    // well as in the set, and those columns are what dimension analysis, the entry list and most
    // reports actually read. Writing the set alone leaves an entry that looks corrected in the
    // Dimensions factbox and unchanged everywhere else - the same trap this codebase hit once already
    // in "BVR Custom Inv Post V2".   //AAV.SP
    //
    // What this does NOT do, and deliberately: it does not touch VAT entries, customer or vendor
    // ledger entries, analysis views or the documents the entries came from. Neither does BC's own
    // dimension correction. Analysis views must be updated afterwards the usual way.
    Permissions = tabledata "G/L Entry" = rimd,
                  tabledata "Dim Correction Blocked Setup" = r;

    // ---------------------------------------------------------------- who gets in

    /// <summary>
    /// Asks for the access code and stops the caller unless it is right. Called from the worksheet's
    /// OnOpenPage, where an error keeps the page shut.
    /// </summary>
    procedure CheckAccessCode()
    var
        BVRCodePage: Page "BVR GL Dim Corr Code";
    begin
        // Nothing to ask, and nobody to ask, when there is no client - a job queue or a web service
        // call is authorised by its permissions, which is the real control here anyway.   //AAV.SP
        if not GuiAllowed() then
            exit;

        // Cancel closes the page with no complaint. An empty Error is the AL way of stopping quietly:
        // someone who changed their mind has not done anything wrong.   //AAV.SP
        if BVRCodePage.RunModal() <> Action::OK then
            Error('');

        if BVRCodePage.GetAccessCode() <> AccessCodeTok then
            Error(WrongAccessCodeErr);
    end;

    // ---------------------------------------------------------------- the check, as a first pass

    // Checks every staged line that has not been processed and records the verdict on the line, without
    // writing anything to the G/L. Kept as a pass of its own rather than folded into the write loop:
    // the team wants to hear about all 40 bad rows at once, before a single entry has moved, not to
    // find the 40th after 9,000 entries have already been corrected.   //AAV.SP
    local procedure ValidatePhase(var BVRGLDimCorrection: Record "BVR GL Dim Correction"; var OkCount: Integer; var FailedCount: Integer)
    var
        BVRLine: Record "BVR GL Dim Correction";
        GLEntry: Record "G/L Entry";
        ProgressWindow: Dialog;
        NewDimSetID: Integer;
        ErrorText: Text[250];
        LineCount: Integer;
        DoneCount: Integer;
    begin
        OkCount := 0;
        FailedCount := 0;

        BVRLine.CopyFilters(BVRGLDimCorrection);
        BVRLine.SetFilter(Status, '%1|%2|%3', BVRLine.Status::Pending, BVRLine.Status::Validated, BVRLine.Status::Failed);
        LineCount := BVRLine.Count();
        if LineCount = 0 then
            Error(NothingToProcessErr);

        if GuiAllowed() then
            ProgressWindow.Open(ValidateProgressMsg);

        BVRLine.FindSet();
        repeat
            if CheckLine(BVRLine, GLEntry, NewDimSetID, ErrorText) then begin
                BVRLine.Status := BVRLine.Status::Validated;
                BVRLine."Error Message" := '';
                OkCount += 1;
            end else begin
                BVRLine.Status := BVRLine.Status::Failed;
                BVRLine."Error Message" := ErrorText;
                FailedCount += 1;
            end;
            BVRLine.Modify();

            DoneCount += 1;
            if GuiAllowed() and ShouldRefresh(DoneCount, LineCount) then begin
                ProgressWindow.Update(1, StrSubstNo(ProgressCountMsg, DoneCount, LineCount));
                ProgressWindow.Update(2, BVRLine."G/L Entry No.");
                ProgressWindow.Update(3, OkCount);
                ProgressWindow.Update(4, FailedCount);
            end;
        until BVRLine.Next() = 0;

        if GuiAllowed() then
            ProgressWindow.Close();
    end;

    // ---------------------------------------------------------------- process (the real thing)

    /// <summary>
    /// Checks every staged line that has not been processed, then applies the ones that passed to
    /// their G/L entries.
    /// </summary>
    procedure ProcessLines(var BVRGLDimCorrection: Record "BVR GL Dim Correction")
    var
        BVRLine: Record "BVR GL Dim Correction";
        GLEntry: Record "G/L Entry";
        ProgressWindow: Dialog;
        NewDimSetID: Integer;
        ErrorText: Text[250];
        LineCount: Integer;
        DoneCount: Integer;
        ReadyCount: Integer;
        UpdatedCount: Integer;
        UnchangedCount: Integer;
        FailedCount: Integer;
        CommitCounter: Integer;
    begin
        ClearCaches();

        // One action, two passes. The check runs first over everything in view and marks each line
        // Validated or Error; only what passed is then written. The caches the check fills are still
        // warm for the write, so the second pass costs little more than the writing itself.   //AAV.SP
        ValidatePhase(BVRGLDimCorrection, ReadyCount, FailedCount);

        // Committed before the question is asked, so the verdicts survive whatever the answer is -
        // including No. Someone who cancels here still has the whole Error Message column to work
        // from, which is the point of checking first.   //AAV.SP
        Commit();

        if ReadyCount = 0 then
            Error(NothingReadyErr, FailedCount);

        if GuiAllowed() then
            if FailedCount > 0 then begin
                if not Confirm(ProcessSomeQst, false, ReadyCount, FailedCount) then
                    exit;
            end else
                if not Confirm(ProcessQst, false, ReadyCount) then
                    exit;

        BVRLine.CopyFilters(BVRGLDimCorrection);
        // Only the lines that just passed. A line the check rejected is left exactly as it is, with
        // its reason on it.   //AAV.SP
        BVRLine.SetRange(Status, BVRLine.Status::Validated);
        LineCount := BVRLine.Count();

        if GuiAllowed() then
            ProgressWindow.Open(ProcessProgressMsg);

        BVRLine.FindSet();
        repeat
            if CheckLine(BVRLine, GLEntry, NewDimSetID, ErrorText) then begin
                if NewDimSetID = GLEntry."Dimension Set ID" then
                    UnchangedCount += 1
                else
                    UpdatedCount += 1;
                ApplyLine(BVRLine, GLEntry, NewDimSetID);
            end else begin
                BVRLine.Status := BVRLine.Status::Failed;
                BVRLine."Error Message" := ErrorText;
                FailedCount += 1;
            end;
            BVRLine.Modify();

            DoneCount += 1;
            if GuiAllowed() and ShouldRefresh(DoneCount, LineCount) then begin
                ProgressWindow.Update(1, StrSubstNo(ProgressCountMsg, DoneCount, LineCount));
                ProgressWindow.Update(2, BVRLine."G/L Entry No.");
                ProgressWindow.Update(3, UpdatedCount);
                ProgressWindow.Update(4, UnchangedCount);
                ProgressWindow.Update(5, FailedCount);
            end;

            // Committed in blocks rather than at the end. A run of ten thousand entries that stops
            // half way - a lock timeout, a session recycle - then keeps the corrections it had already
            // made, and every staged row says whether it was one of them. Pressing Process again picks
            // up everything not yet marked Processed. One transaction over the whole run would throw
            // away an hour's work and leave nothing to show where it got to.   //AAV.SP
            CommitCounter += 1;
            if CommitCounter >= CommitBatchSize() then begin
                CommitCounter := 0;
                Commit();
            end;
        until BVRLine.Next() = 0;

        if GuiAllowed() then begin
            ProgressWindow.Close();
            Message(ProcessDoneMsg, UpdatedCount, UnchangedCount, FailedCount);
        end;
    end;

    // ---------------------------------------------------------------- revert

    /// <summary>
    /// Puts every processed line's G/L entry back to the dimensions it carried before Process ran.
    /// </summary>
    procedure RevertLines(var BVRGLDimCorrection: Record "BVR GL Dim Correction")
    var
        BVRLine: Record "BVR GL Dim Correction";
        GLEntry: Record "G/L Entry";
        ProgressWindow: Dialog;
        LineCount: Integer;
        DoneCount: Integer;
        RevertedCount: Integer;
        FailedCount: Integer;
        CommitCounter: Integer;
    begin
        BVRLine.CopyFilters(BVRGLDimCorrection);
        BVRLine.SetRange(Status, BVRLine.Status::Processed);
        LineCount := BVRLine.Count();
        if LineCount = 0 then
            Error(NothingToRevertErr);

        if GuiAllowed() then begin
            if not Confirm(RevertQst, false, LineCount) then
                exit;
            ProgressWindow.Open(RevertProgressMsg);
        end;

        BVRLine.FindSet();
        repeat
            if not GLEntry.Get(BVRLine."G/L Entry No.") then begin
                BVRLine.Status := BVRLine.Status::Failed;
                BVRLine."Error Message" := StrSubstNo(NoEntryErr, BVRLine."G/L Entry No.");
                FailedCount += 1;
            end else
                // Only revert an entry that still looks the way this row left it. If something else has
                // changed the dimensions since - a second correction, BC's own dimension correction -
                // then this row's "previous" values are no longer the state to go back to, and writing
                // them would quietly undo that later change as well.   //AAV.SP
                if GLEntry."Dimension Set ID" <> BVRLine."New Dimension Set ID" then begin
                    BVRLine.Status := BVRLine.Status::Failed;
                    BVRLine."Error Message" := StrSubstNo(ChangedSinceErr, BVRLine."G/L Entry No.");
                    FailedCount += 1;
                end else begin
                    // Written back literally rather than re-derived from the old set. An entry posted
                    // before dimension sets existed can carry global dimension codes with a set ID of
                    // 0, and deriving would blank them.   //AAV.SP
                    GLEntry."Dimension Set ID" := BVRLine."Previous Dimension Set ID";
                    GLEntry."Global Dimension 1 Code" := BVRLine."Previous Global Dim 1 Code";
                    GLEntry."Global Dimension 2 Code" := BVRLine."Previous Global Dim 2 Code";
                    GLEntry.Modify(true);

                    BVRLine.Status := BVRLine.Status::Reverted;
                    BVRLine."Error Message" := '';
                    BVRLine."Processed At" := CurrentDateTime();
                    BVRLine."Processed By" := CopyStr(UserId(), 1, MaxStrLen(BVRLine."Processed By"));
                    RevertedCount += 1;
                end;
            BVRLine.Modify();

            DoneCount += 1;
            if GuiAllowed() and ShouldRefresh(DoneCount, LineCount) then begin
                ProgressWindow.Update(1, StrSubstNo(ProgressCountMsg, DoneCount, LineCount));
                ProgressWindow.Update(2, BVRLine."G/L Entry No.");
                ProgressWindow.Update(3, RevertedCount);
                ProgressWindow.Update(4, FailedCount);
            end;

            CommitCounter += 1;
            if CommitCounter >= CommitBatchSize() then begin
                CommitCounter := 0;
                Commit();
            end;
        until BVRLine.Next() = 0;

        if GuiAllowed() then begin
            ProgressWindow.Close();
            Message(RevertDoneMsg, RevertedCount, FailedCount);
        end;
    end;

    // ---------------------------------------------------------------- load

    /// <summary>
    /// Loads staged lines from a comma-separated file: G/L Entry No., new global dimension 1, new
    /// global dimension 2. A header row, or any row whose first column is not a number, is skipped.
    /// </summary>
    procedure ImportFromFile()
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        BVRLine: Record "BVR GL Dim Correction";
        ProgressWindow: Dialog;
        FileInStream: InStream;
        FileName: Text;
        LineNo: Integer;
        RowCount: Integer;
        EntryNo: Integer;
        ImportedCount: Integer;
        SkippedCount: Integer;
    begin
        if not UploadIntoStream(ImportTitleLbl, '', ImportFilterLbl, FileName, FileInStream) then
            exit;

        TempCSVBuffer.LoadDataFromStream(FileInStream, ',', '"');
        RowCount := TempCSVBuffer.GetNumberOfLines();

        if GuiAllowed() then
            ProgressWindow.Open(ImportProgressMsg);

        for LineNo := 1 to RowCount do begin
            if TryGetEntryNo(TempCSVBuffer.GetValue(LineNo, 1), EntryNo) then begin
                if not BVRLine.Get(EntryNo) then begin
                    BVRLine.Init();
                    BVRLine."G/L Entry No." := EntryNo;
                    BVRLine.Insert();
                end;
                // Assigned rather than validated on purpose. A dimension value that does not exist is
                // reported per row by Validate, next to the entry it belongs to, instead of stopping
                // the whole import on line 4,127.   //AAV.SP
                BVRLine."New Global Dim 1 Code" := CleanCode(TempCSVBuffer.GetValue(LineNo, 2));
                BVRLine."New Global Dim 2 Code" := CleanCode(TempCSVBuffer.GetValue(LineNo, 3));
                BVRLine."Clear Global Dim 1" := false;
                BVRLine."Clear Global Dim 2" := false;
                BVRLine.Status := BVRLine.Status::Pending;
                BVRLine."Error Message" := '';
                BVRLine.Modify();
                ImportedCount += 1;
            end else
                SkippedCount += 1;

            if GuiAllowed() and ShouldRefresh(LineNo, RowCount) then begin
                ProgressWindow.Update(1, StrSubstNo(ProgressCountMsg, LineNo, RowCount));
                ProgressWindow.Update(2, ImportedCount);
                ProgressWindow.Update(3, SkippedCount);
            end;
        end;

        if GuiAllowed() then begin
            ProgressWindow.Close();
            Message(ImportDoneMsg, ImportedCount, SkippedCount);
        end;
    end;

    /// <summary>
    /// Removes lines that have already been applied or reverted, leaving the work still to do.
    /// </summary>
    procedure DeleteFinishedLines(var BVRGLDimCorrection: Record "BVR GL Dim Correction")
    var
        BVRLine: Record "BVR GL Dim Correction";
        ProgressWindow: Dialog;
        DeletedCount: Integer;
    begin
        BVRLine.CopyFilters(BVRGLDimCorrection);
        BVRLine.SetFilter(Status, '%1|%2', BVRLine.Status::Processed, BVRLine.Status::Reverted);
        DeletedCount := BVRLine.Count();
        if DeletedCount = 0 then
            Error(NothingToDeleteErr);

        if GuiAllowed() then
            if not Confirm(DeleteQst, false, DeletedCount) then
                exit;

        // One statement rather than a loop, so there is nothing to count through - but on tens of
        // thousands of rows it is long enough that the client needs to say something.   //AAV.SP
        if GuiAllowed() then
            ProgressWindow.Open(DeleteProgressMsg);

        // DeleteAll without triggers: the table's OnDelete guard exists to stop someone pressing
        // Delete on a processed row by hand and silently losing the way back. This action IS that
        // decision, taken deliberately and with the count shown.   //AAV.SP
        BVRLine.DeleteAll();

        if GuiAllowed() then begin
            ProgressWindow.Close();
            Message(DeleteDoneMsg, DeletedCount);
        end;
    end;

    // ---------------------------------------------------------------- one line

    // Everything that has to be true before an entry is touched, gathered in one place so Validate and
    // Process cannot drift apart: Process re-checks rather than trusting a Validated mark, because the
    // ledger and the dimension setup can both move between the two.   //AAV.SP
    local procedure CheckLine(var BVRLine: Record "BVR GL Dim Correction"; var GLEntry: Record "G/L Entry"; var NewDimSetID: Integer; var ErrorText: Text[250]): Boolean
    begin
        ErrorText := '';
        NewDimSetID := 0;

        if not GLEntry.Get(BVRLine."G/L Entry No.") then begin
            ErrorText := StrSubstNo(NoEntryErr, BVRLine."G/L Entry No.");
            exit(false);
        end;

        if not HasInstruction(BVRLine) then begin
            ErrorText := NothingAskedErr;
            exit(false);
        end;

        if not CheckDimension(1, BVRLine."New Global Dim 1 Code", BVRLine."Clear Global Dim 1", ErrorText) then
            exit(false);
        if not CheckDimension(2, BVRLine."New Global Dim 2 Code", BVRLine."Clear Global Dim 2", ErrorText) then
            exit(false);

        NewDimSetID := TargetDimSetID(GLEntry."Dimension Set ID", BVRLine);

        // An entry that already carries what the row asks for is not an error and not a failure - it
        // is simply nothing to do. It still has to pass the checks below, and it does, because the set
        // it would move to is the one it is already posted with.   //AAV.SP
        if NewDimSetID = GLEntry."Dimension Set ID" then
            exit(true);

        exit(CheckDimSetForAccount(GLEntry."G/L Account No.", NewDimSetID, ErrorText));
    end;

    // The same two checks BC's own correction makes per entry - dimension combinations, and whether
    // the account allows the value at all.
    //
    // Cached on account and target set for the same reason the set building is: both read default
    // dimensions and combination rules from the database, and a correction of this size asks the same
    // question over and over. An empty cached answer means the pair passed.   //AAV.SP
    local procedure CheckDimSetForAccount(GLAccNo: Code[20]; NewDimSetID: Integer; var ErrorText: Text[250]): Boolean
    var
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
        CacheKey: Text;
    begin
        CacheKey := StrSubstNo('%1|%2', NewDimSetID, GLAccNo);
        if DimCheckCache.ContainsKey(CacheKey) then begin
            ErrorText := CopyStr(DimCheckCache.Get(CacheKey), 1, MaxStrLen(ErrorText));
            exit(ErrorText = '');
        end;

        ErrorText := '';
        if not DimMgt.CheckDimIDComb(NewDimSetID) then
            ErrorText := CopyStr(DimMgt.GetDimCombErr(), 1, MaxStrLen(ErrorText))
        else begin
            TableID[1] := Database::"G/L Account";
            AccNo[1] := GLAccNo;
            if not DimMgt.CheckDimValuePosting(TableID, AccNo, NewDimSetID) then
                ErrorText := CopyStr(DimMgt.GetDimValuePostingErr(), 1, MaxStrLen(ErrorText));
        end;

        DimCheckCache.Add(CacheKey, ErrorText);
        exit(ErrorText = '');
    end;

    local procedure ApplyLine(var BVRLine: Record "BVR GL Dim Correction"; var GLEntry: Record "G/L Entry"; NewDimSetID: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        BVRLine."Previous Dimension Set ID" := GLEntry."Dimension Set ID";
        BVRLine."Previous Global Dim 1 Code" := GLEntry."Global Dimension 1 Code";
        BVRLine."Previous Global Dim 2 Code" := GLEntry."Global Dimension 2 Code";
        BVRLine."New Dimension Set ID" := NewDimSetID;

        if NewDimSetID <> GLEntry."Dimension Set ID" then begin
            GLEntry."Dimension Set ID" := NewDimSetID;
            // Both halves, every time - see the note at the top of this codeunit.   //AAV.SP
            DimMgt.UpdateGlobalDimFromDimSetID(
                GLEntry."Dimension Set ID", GLEntry."Global Dimension 1 Code", GLEntry."Global Dimension 2 Code");
            GLEntry.Modify(true);
        end;

        BVRLine.Status := BVRLine.Status::Processed;
        BVRLine."Error Message" := '';
        BVRLine."Processed At" := CurrentDateTime();
        BVRLine."Processed By" := CopyStr(UserId(), 1, MaxStrLen(BVRLine."Processed By"));
    end;

    local procedure HasInstruction(var BVRLine: Record "BVR GL Dim Correction"): Boolean
    begin
        exit(
            (BVRLine."New Global Dim 1 Code" <> '') or (BVRLine."New Global Dim 2 Code" <> '') or
            BVRLine."Clear Global Dim 1" or BVRLine."Clear Global Dim 2");
    end;

    local procedure CheckDimension(GlobalDimNo: Integer; NewValue: Code[20]; ClearValue: Boolean; var ErrorText: Text[250]): Boolean
    var
        DimValue: Record "Dimension Value";
        DimCorrectionBlockedSetup: Record "Dim Correction Blocked Setup";
        DimCode: Code[20];
    begin
        // Nothing asked of this dimension - the entry keeps whatever it has.   //AAV.SP
        if (NewValue = '') and (not ClearValue) then
            exit(true);

        DimCode := GlobalDimensionCode(GlobalDimNo);
        if DimCode = '' then begin
            ErrorText := StrSubstNo(NoGlobalDimErr, GlobalDimNo);
            exit(false);
        end;

        // An administrator who has blocked a dimension from BC's own correction meant it about the
        // dimension, not about which page the correction is driven from.   //AAV.SP
        if DimCorrectionBlockedSetup.Get(DimCode) then begin
            ErrorText := StrSubstNo(BlockedDimErr, DimCode);
            exit(false);
        end;

        if NewValue = '' then
            exit(true);

        if not DimValue.Get(DimCode, NewValue) then begin
            ErrorText := StrSubstNo(NoDimValueErr, NewValue, DimCode);
            exit(false);
        end;
        if DimValue.Blocked then begin
            ErrorText := StrSubstNo(BlockedDimValueErr, NewValue, DimCode);
            exit(false);
        end;
        if DimValue."Dimension Value Type" <> DimValue."Dimension Value Type"::Standard then begin
            ErrorText := StrSubstNo(NotStandardDimValueErr, NewValue, DimCode);
            exit(false);
        end;

        exit(true);
    end;

    // ---------------------------------------------------------------- dimension sets

    // Cached because a correction of this size is nearly always a handful of distinct moves repeated
    // thousands of times - the same source dimension set going to the same new value. Building a
    // dimension set means reading the source set, rebuilding it and looking the result up (or
    // inserting it), so doing it once per distinct move rather than once per entry is the difference
    // between a run that takes minutes and one that takes hours.   //AAV.SP
    local procedure TargetDimSetID(SourceDimSetID: Integer; var BVRLine: Record "BVR GL Dim Correction"): Integer
    var
        CacheKey: Text;
        NewDimSetID: Integer;
    begin
        CacheKey :=
            StrSubstNo('%1|%2|%3|%4|%5', SourceDimSetID, BVRLine."New Global Dim 1 Code", BVRLine."New Global Dim 2 Code",
                       BVRLine."Clear Global Dim 1", BVRLine."Clear Global Dim 2");
        if TargetDimSetCache.ContainsKey(CacheKey) then
            exit(TargetDimSetCache.Get(CacheKey));

        NewDimSetID := BuildTargetDimSetID(SourceDimSetID, BVRLine);
        TargetDimSetCache.Add(CacheKey, NewDimSetID);
        exit(NewDimSetID);
    end;

    // Mirrors "Dimension Correction Mgt".TransformDimensionSet: take the entry's set apart, change the
    // global dimensions this row asks about, put it back together. Every OTHER dimension on the entry
    // survives untouched - a correction of the cost centre must not throw away the project.   //AAV.SP
    local procedure BuildTargetDimSetID(SourceDimSetID: Integer; var BVRLine: Record "BVR GL Dim Correction"): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        TempNewDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.GetDimensionSet(TempDimSetEntry, SourceDimSetID);

        ApplyDimensionChange(
            TempDimSetEntry, SourceDimSetID, GlobalDimensionCode(1),
            BVRLine."New Global Dim 1 Code", BVRLine."Clear Global Dim 1");
        ApplyDimensionChange(
            TempDimSetEntry, SourceDimSetID, GlobalDimensionCode(2),
            BVRLine."New Global Dim 2 Code", BVRLine."Clear Global Dim 2");

        TempDimSetEntry.Reset();
        // Clearing the last dimension off an entry leaves it with no set at all, which is set 0 - the
        // blank set - not a new empty one.   //AAV.SP
        if not TempDimSetEntry.FindSet() then
            exit(0);

        repeat
            TempNewDimSetEntry.TransferFields(TempDimSetEntry, true);
            TempNewDimSetEntry."Dimension Set ID" := 0;
            TempNewDimSetEntry.Insert(true);
        until TempDimSetEntry.Next() = 0;

        exit(DimMgt.GetDimensionSetID(TempNewDimSetEntry));
    end;

    local procedure ApplyDimensionChange(var TempDimSetEntry: Record "Dimension Set Entry" temporary; SourceDimSetID: Integer; DimCode: Code[20]; NewValue: Code[20]; ClearValue: Boolean)
    var
        DimValue: Record "Dimension Value";
        EntryExists: Boolean;
    begin
        if DimCode = '' then
            exit;

        if ClearValue then begin
            if TempDimSetEntry.Get(SourceDimSetID, DimCode) then
                TempDimSetEntry.Delete();
            exit;
        end;

        if NewValue = '' then
            exit;

        DimValue.Get(DimCode, NewValue);
        EntryExists := TempDimSetEntry.Get(SourceDimSetID, DimCode);
        TempDimSetEntry."Dimension Set ID" := SourceDimSetID;
        TempDimSetEntry."Dimension Code" := DimCode;
        TempDimSetEntry."Dimension Value Code" := NewValue;
        TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
        if EntryExists then
            TempDimSetEntry.Modify()
        else
            TempDimSetEntry.Insert();
    end;

    // ---------------------------------------------------------------- setup and housekeeping

    local procedure GlobalDimensionCode(GlobalDimNo: Integer): Code[20]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;

        case GlobalDimNo of
            1:
                exit(GLSetup."Global Dimension 1 Code");
            2:
                exit(GLSetup."Global Dimension 2 Code");
        end;
        exit('');
    end;

    local procedure ClearCaches()
    begin
        Clear(TargetDimSetCache);
        Clear(DimCheckCache);
        GLSetupRead := false;
    end;

    // Repainting a dialog costs a round trip to the client, so a run of ten thousand lines must not do
    // it ten thousand times. Every hundredth line, plus the first and the last: a short run still shows
    // something rather than staying blank, and a long one still finishes on the true figures instead of
    // whatever the last multiple of a hundred happened to be.   //AAV.SP
    local procedure ShouldRefresh(DoneCount: Integer; LineCount: Integer): Boolean
    begin
        exit((DoneCount = 1) or (DoneCount = LineCount) or ((DoneCount mod 100) = 0));
    end;

    local procedure CommitBatchSize(): Integer
    begin
        exit(500);
    end;

    local procedure CleanCode(Value: Text): Code[20]
    begin
        exit(CopyStr(UpperCase(DelChr(Value, '<>', ' ')), 1, 20));
    end;

    // A file row whose first column is not a whole number is a header, a blank line or a total - not
    // something to fail the import over.   //AAV.SP
    local procedure TryGetEntryNo(Value: Text; var EntryNo: Integer): Boolean
    begin
        EntryNo := 0;
        Value := DelChr(Value, '<>', ' ');
        if Value = '' then
            exit(false);
        if not Evaluate(EntryNo, DelChr(Value, '=', ', ')) then
            exit(false);
        exit(EntryNo > 0);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        TargetDimSetCache: Dictionary of [Text, Integer];
        DimCheckCache: Dictionary of [Text, Text];
        GLSetupRead: Boolean;
        // The code that guards the worksheet. It is a speed bump against opening the page by accident,
        // NOT access control: it is compiled into the extension, so it can be read out of the source or
        // the symbols by anyone who cares to look, and it does nothing to stop the table being reached
        // another way. The permission set is what actually decides who may correct G/L entries.   //AAV.SP
        AccessCodeTok: Label '7445', Locked = true;
        WrongAccessCodeErr: Label 'That is not the right access code.';
        NothingToProcessErr: Label 'There is nothing to process. Every line in view has already been processed.';
        NothingReadyErr: Label 'None of the %1 lines can be processed. The Error Message column says why.', Comment = '%1 = number of lines checked';
        NothingToRevertErr: Label 'There is nothing to revert. No line in view has been processed.';
        NothingToDeleteErr: Label 'There is nothing to delete. No line in view has been processed or reverted.';
        NoEntryErr: Label 'G/L Entry %1 does not exist.', Comment = '%1 = G/L Entry No.';
        NothingAskedErr: Label 'Enter a new dimension value, or tick Clear, for at least one dimension.';
        NoGlobalDimErr: Label 'Global Dimension %1 is not set up in General Ledger Setup.', Comment = '%1 = 1 or 2';
        BlockedDimErr: Label 'Dimension %1 is blocked from correction in Dimension Correction Blocked Setup.', Comment = '%1 = Dimension Code';
        NoDimValueErr: Label 'Dimension value %1 does not exist for dimension %2.', Comment = '%1 = Dimension Value Code, %2 = Dimension Code';
        BlockedDimValueErr: Label 'Dimension value %1 for dimension %2 is blocked.', Comment = '%1 = Dimension Value Code, %2 = Dimension Code';
        NotStandardDimValueErr: Label 'Dimension value %1 for dimension %2 is not a standard value and cannot be posted to.', Comment = '%1 = Dimension Value Code, %2 = Dimension Code';
        ChangedSinceErr: Label 'The dimensions on G/L Entry %1 have been changed since this line was processed, so it cannot be reverted from here.', Comment = '%1 = G/L Entry No.';
        ProcessQst: Label '%1 lines passed the check.\\Correct the dimensions on %1 G/L entries?\\This changes posted entries and can only be undone with Revert.', Comment = '%1 = number of lines';
        ProcessSomeQst: Label '%1 lines passed the check and %2 have errors.\\Correct the dimensions on the %1 G/L entries and leave the rest?\\This changes posted entries and can only be undone with Revert.', Comment = '%1 = number ready, %2 = number failed';
        RevertQst: Label 'Put %1 G/L entries back to the dimensions they carried before?', Comment = '%1 = number of lines';
        DeleteQst: Label 'Delete %1 finished lines? The G/L entries keep their corrected dimensions, but the record of what they looked like before is lost.', Comment = '%1 = number of lines';
        ProcessDoneMsg: Label '%1 G/L entries were corrected.\%2 already carried the requested dimensions.\%3 lines were skipped because of errors.', Comment = '%1 = number updated, %2 = number unchanged, %3 = number failed';
        RevertDoneMsg: Label '%1 G/L entries were put back.\%2 lines could not be reverted.', Comment = '%1 = number reverted, %2 = number failed';
        DeleteDoneMsg: Label '%1 lines were deleted.', Comment = '%1 = number deleted';
        ImportDoneMsg: Label '%1 lines were loaded.\%2 file rows were skipped.', Comment = '%1 = number imported, %2 = number skipped';
        ImportTitleLbl: Label 'Import G/L Dimension Corrections';
        ImportFilterLbl: Label 'Comma-separated files (*.csv)|*.csv|All files (*.*)|*.*';
        ProcessProgressMsg: Label 'Correcting dimensions on G/L entries...\\Line              #1##################\G/L Entry No.     #2##################\Corrected         #3##################\Already correct   #4##################\Errors            #5##################';
        ValidateProgressMsg: Label 'Checking lines...\\Line              #1##################\G/L Entry No.     #2##################\Ready to process  #3##################\Errors            #4##################';
        RevertProgressMsg: Label 'Putting dimensions back...\\Line              #1##################\G/L Entry No.     #2##################\Reverted          #3##################\Errors            #4##################';
        ImportProgressMsg: Label 'Loading lines from file...\\File row          #1##################\Loaded            #2##################\Skipped           #3##################';
        DeleteProgressMsg: Label 'Deleting finished lines...';
        ProgressCountMsg: Label '%1 of %2', Comment = '%1 = lines done, %2 = lines in total';
}
