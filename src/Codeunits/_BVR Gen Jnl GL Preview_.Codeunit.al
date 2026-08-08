codeunit 50151 "BVR Gen Jnl GL Preview"
{
    // Returns the G/L entries a general journal WOULD post, for the "General Journal - Test" report.
    //
    // These are not derived or recalculated here - they come from BC's own posting preview, so VAT,
    // customer/vendor posting groups, fixed assets, allocations and rounding are all exactly what
    // real posting would produce.
    //
    // How the preview engine is driven (see codeunit 19 "Gen. Jnl.-Post Preview"):
    //   * SetContext stores the posting codeunit and the journal lines to simulate. The posting
    //     codeunit must be "Gen. Jnl.-Post" (232), NOT "Gen. Jnl.-Post Batch" (13). Codeunit 19 does
    //     not call the posting codeunit itself - it raises OnRunPreview and lets a subscriber do it,
    //     and for general journals the only such subscriber lives in codeunit 232. Pass codeunit 13
    //     and nothing runs at all.
    //   * Codeunit 232 is EventSubscriberInstance = Manual, so that subscriber is dormant until an
    //     instance is bound - and it must be the SAME instance that is passed as the subscriber,
    //     because the subscriber sets PreviewMode on it before running it. Without the bind, the
    //     event has no subscribers, nothing posts, and codeunit 19 fails with "The posting preview
    //     has stopped because of a state that is not valid." This is exactly how codeunit 232's own
    //     Preview() does it.
    //   * Run() enters OnRun, which sets HideDialogs so the preview PAGE is not shown, performs the
    //     simulated post, and finishes with Error('') to roll everything back. Run() therefore
    //     always returns FALSE - that is by design, not a failure, which is why its result is
    //     discarded.
    //   * The captured entries live in temporary tables owned by "Posting Preview Event Handler".
    //     They are in memory, so the rollback does not take them with it.
    //   * That handler MASKS "Document No." as '***' unless told otherwise, so codeunit
    //     "BVR Preview Show Doc No" is bound around the run to switch the masking off. Without it
    //     every captured entry comes back as '***' and cannot be matched to a journal line.
    //   * IsSuccess() tells us whether the simulated post actually completed. It is false when the
    //     journal has errors that stop posting - in that case there is nothing to show, and the
    //     report says so rather than printing a misleading empty list.   //AAV.SP

    // StatusText comes back non-blank whenever there is nothing to list, so the report can print the
    // reason instead of quietly showing no block at all - a silent omission is indistinguishable
    // from "I forgot to tick the option".   //AAV.SP
    // Takes the template and batch by name rather than a pre-filtered record. Two reasons: the
    // report's line filters arrive through a DataItemLink, and CopyFilters does not reliably carry
    // those across; and posting is a whole-batch operation anyway - BC's own Preview Posting ignores
    // any line-level filter and simulates the entire batch, so this matches what really happens.
    procedure BuildEntries(JournalTemplateName: Code[10]; JournalBatchName: Code[10]; var TempGLEntry: Record "G/L Entry" temporary; var StatusText: Text) Succeeded: Boolean
    var
        GenJnlLine: Record "Gen. Journal Line";
        PreviewGLEntry: Record "G/L Entry";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
        PreviewShowDocNo: Codeunit "BVR Preview Show Doc No";
        GLEntryRecRef: RecordRef;
        FailureReason: Text;
    begin
        TempGLEntry.Reset();
        TempGLEntry.DeleteAll();
        StatusText := '';

        GenJnlLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJnlLine.SetRange("Journal Batch Name", JournalBatchName);

        // FindFirst, not IsEmpty - the record has to be POSITIONED, not merely filtered.
        //
        // Codeunit 13 reads the template and batch off the record's FIELD VALUES, not off its
        // filters, and then rebuilds the filters from those values:
        //     GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        //     GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        //     GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
        // A record that has only had SetRange applied still has blank fields, so this discards the
        // filters and then fails on Get(''). Codeunit 13 also calls Find('=><'), which needs a
        // current position. Posting from the journal page works because Rec is a real, current line.
        if not GenJnlLine.FindFirst() then begin
            StatusText := NoLinesMsg;
            exit(false);
        end;

        // Nothing to do if we are already inside someone else's preview - a nested simulation would
        // report entries that are themselves hypothetical.
        if GenJnlPostPreview.IsActive() then begin
            StatusText := AlreadyPreviewingMsg;
            exit(false);
        end;

        GenJnlPostPreview.SetContext(GenJnlPost, GenJnlLine);

        // A report runs inside a write transaction (Report.TransactionType defaults to Update), and
        // AL forbids USING the return value of Codeunit.Run there. We need exactly that form: only
        // the trapped call swallows the Error('') the preview deliberately ends with, and if that
        // error escaped it would abort the report.
        //
        // Commit() clears the transaction so the trapped form is allowed. It is safe because this
        // report only reads - there is nothing pending to commit.
        //
        // Do NOT "fix" this by wrapping the call in a [TryFunction] instead. A try function inside a
        // write transaction does not roll back database writes, so the simulated posting would
        // survive and the journal would effectively be posted for real. Codeunit.Run after a Commit
        // opens its own transaction scope, so the preview's error rolls the simulation back.
        Commit();

        // Wakes up codeunit 232's OnRunPreview subscriber - without this nothing posts at all.
        BindSubscription(GenJnlPost);
        // Keeps the real Document No. on the captured entries instead of '***', and captures why the
        // simulation stopped if it does. Both are unbound on every path out, failure included.
        BindSubscription(PreviewShowDocNo);

        // Always FALSE - OnRun ends in Error('') to roll the simulated post back.
        if GenJnlPostPreview.Run() then;
        Succeeded := GenJnlPostPreview.IsSuccess();
        FailureReason := PreviewShowDocNo.GetFailureReason();

        UnbindSubscription(PreviewShowDocNo);
        UnbindSubscription(GenJnlPost);

        if not Succeeded then begin
            // The reason comes from the simulation itself. Printing it beats "correct the warnings
            // above" when the warnings above say nothing about it.
            if FailureReason <> '' then
                StatusText := StrSubstNo(PostingFailedWithReasonMsg, FailureReason)
            else
                StatusText := PostingFailedMsg;
            exit(false);
        end;

        GenJnlPostPreview.GetPreviewHandler(PostingPreviewEventHandler);
        PostingPreviewEventHandler.GetEntries(Database::"G/L Entry", GLEntryRecRef);

        if GLEntryRecRef.FindSet() then
            repeat
                GLEntryRecRef.SetTable(PreviewGLEntry);
                TempGLEntry := PreviewGLEntry;
                if TempGLEntry.Insert() then;
            until GLEntryRecRef.Next() = 0;
        GLEntryRecRef.Close();

        if TempGLEntry.IsEmpty() then begin
            StatusText := NoEntriesMsg;
            exit(false);
        end;

        // If the mask ever comes back - a future platform change, or another extension re-enabling it
        // after us - say so plainly. Otherwise the caller would filter on Document No., match
        // nothing, and report "no entries for this document" for every document in the journal,
        // which points at the wrong problem entirely.
        TempGLEntry.SetRange("Document No.", DocumentMaskTok);
        if not TempGLEntry.IsEmpty() then begin
            TempGLEntry.Reset();
            StatusText := DocNoMaskedMsg;
            exit(false);
        end;
        TempGLEntry.Reset();

        exit(true);
    end;

    var
        NoLinesMsg: Label 'No journal lines matched the filters, so there was nothing to simulate.';
        AlreadyPreviewingMsg: Label 'A posting preview is already running, so the entries were not simulated.';
        PostingFailedMsg: Label 'The simulated posting did not complete, so no entries can be listed. Correct the warnings above, or use Preview Posting on the journal to see the exact reason.';
        PostingFailedWithReasonMsg: Label 'The simulated posting did not complete, so no entries can be listed: %1', Comment = '%1 = the error the simulated posting stopped with';
        NoEntriesMsg: Label 'The simulated posting completed but produced no G/L entries.';
        DocNoMaskedMsg: Label 'The posting preview returned its entries with the document number masked, so they cannot be listed per document.';
        DocumentMaskTok: Label '***', Locked = true;

    procedure GetAccountName(GLAccountNo: Code[20]): Text[100]
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccountNo = '' then
            exit('');
        if not GLAccount.Get(GLAccountNo) then
            exit('');
        exit(GLAccount.Name);
    end;
}
