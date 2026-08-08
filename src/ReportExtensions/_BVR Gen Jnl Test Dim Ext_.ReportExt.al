// Extends the standard "General Journal - Test" report (ID 2) with:
//   * Shortcut Dimension 1 / 2 columns on the journal lines,
//   * an "Expected G/L Entries" block printed per DOCUMENT, directly after that line's Dimensions
//     rows - the entries the journal would actually post, taken from BC's own posting preview
//     rather than recalculated (see codeunit "BVR Gen Jnl GL Preview"). Account No., Account Name,
//     Debit and Credit only: the dimensions already print on the journal line above, and repeating
//     them on every entry was noise.
//
// Why per document and not per line: a G/L entry carries a Document No., never a journal line no.,
// so a document's entries cannot be split across the lines that produced them. The block is
// therefore printed once, under the FIRST line of each document.
//
// Why the preview runs once per batch and not once per line: it simulates posting the whole
// journal. Running it per line would be slow, and would fail outright for documents whose lines
// only balance together.
//
// A report extension cannot change the base RDLC, so none of this shows on Microsoft's layout. It
// prints through the layout added below - a copy of the base layout with the extra columns and
// rows. Users must select it on the Report Layouts page (or make it the default there).   //AAV.SP
reportextension 50146 "BVR Gen Jnl Test Dim Ext" extends "General Journal - Test"
{
    dataset
    {
        // Runs the simulation for the batch BEFORE the Gen. Journal Line loop opens.
        //
        // It used to run from inside that loop, which meant committing and then locking and posting
        // Gen. Journal Line while the report was holding an open cursor on those very rows. Doing it
        // here, between batches, removes that overlap entirely - by the time the lines are read the
        // answer is already in memory.   //AAV.SP
        addbefore("Integer")
        {
            dataitem(BVRPreviewPrep; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                trigger OnPreDataItem()
                begin
                    if BVRShowGLEntries then
                        BVRPrepareBatch("Gen. Journal Batch"."Journal Template Name", "Gen. Journal Batch".Name);
                    // Prints nothing - it exists only for the timing.
                    CurrReport.Break();
                end;
            }
        }
        add("Integer")
        {
            column(BVRShortcutDim1Caption; "Gen. Journal Line".FieldCaption("Shortcut Dimension 1 Code"))
            {
            }
            column(BVRShortcutDim2Caption; "Gen. Journal Line".FieldCaption("Shortcut Dimension 2 Code"))
            {
            }
        }
        add("Gen. Journal Line")
        {
            column(BVRShortcutDim1Code; "Shortcut Dimension 1 Code")
            {
            }
            column(BVRShortcutDim2Code; "Shortcut Dimension 2 Code")
            {
            }
        }
        // Sibling of DimensionLoop, so the block renders immediately after the line's Dimensions
        // rows and inside the same tablix details group - the construction this report already uses
        // for its Dimensions and Allocation rows, where each row decides its own visibility from
        // fields on the current dataset row.
        addafter(DimensionLoop)
        {
            dataitem(BVRGLEntryLoop; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));

                column(BVRGLNumber; Number)
                {
                }
                column(BVRGLAccNo; BVRGLAccNo)
                {
                }
                column(BVRGLAccName; BVRGLAccName)
                {
                }
                column(BVRGLDebit; BVRGLDebit)
                {
                }
                column(BVRGLCredit; BVRGLCredit)
                {
                }
                // Not an entry column - carries the explanation when there is nothing to list, so a
                // blank block can never be mistaken for "the option was not ticked".
                column(BVRGLStatus; BVRGLStatus)
                {
                }
                column(BVRGLEntriesCaption; BVRGLEntriesCaptionLbl)
                {
                }
                column(BVRGLAccNoCaption; BVRGLAccNoCaptionLbl)
                {
                }
                column(BVRGLAccNameCaption; BVRGLAccNameCaptionLbl)
                {
                }
                column(BVRGLDebitCaption; BVRGLDebitCaptionLbl)
                {
                }
                column(BVRGLCreditCaption; BVRGLCreditCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if not BVRShowGLEntries then
                        CurrReport.Break();

                    // Normally a no-op: BVRPreviewPrep already simulated this batch. Kept as a safety
                    // net so the block still works if the loop is ever reached without it.
                    BVRPrepareBatch("Gen. Journal Line"."Journal Template Name", "Gen. Journal Line"."Journal Batch Name");

                    // Once per document, under its first line.
                    if BVRShownDocNos.Contains("Gen. Journal Line"."Document No.") then
                        CurrReport.Break();
                    BVRShownDocNos.Add("Gen. Journal Line"."Document No.");

                    if not BVRPreviewOk then begin
                        // The reason is worth printing once per journal, not once per document.
                        if BVRStatusShown then
                            CurrReport.Break();
                        BVRStatusShown := true;
                        BVRStatusOnly := true;
                        SetRange(Number, 1, 1);
                        exit;
                    end;

                    BVRStatusOnly := false;
                    BVRTempGLEntry.Reset();
                    BVRTempGLEntry.SetRange("Document No.", "Gen. Journal Line"."Document No.");
                    if BVRTempGLEntry.IsEmpty() then begin
                        BVRStatusOnly := true;
                        BVRStatusText := BVRNoDocEntriesMsg;
                        SetRange(Number, 1, 1);
                        exit;
                    end;

                    SetRange(Number, 1, BVRTempGLEntry.Count());
                end;

                trigger OnAfterGetRecord()
                begin
                    Clear(BVRGLAccNo);
                    Clear(BVRGLAccName);
                    Clear(BVRGLDebit);
                    Clear(BVRGLCredit);
                    Clear(BVRGLStatus);

                    if BVRStatusOnly then begin
                        BVRGLStatus := CopyStr(BVRStatusText, 1, MaxStrLen(BVRGLStatus));
                        exit;
                    end;

                    if Number = 1 then begin
                        if not BVRTempGLEntry.FindSet() then
                            CurrReport.Break();
                    end else
                        if BVRTempGLEntry.Next() = 0 then
                            CurrReport.Break();

                    BVRGLAccNo := BVRTempGLEntry."G/L Account No.";
                    BVRGLAccName := BVRGLPreview.GetAccountName(BVRTempGLEntry."G/L Account No.");
                    BVRGLDebit := BVRTempGLEntry."Debit Amount";
                    BVRGLCredit := BVRTempGLEntry."Credit Amount";
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            addlast(Options)
            {
                field(BVRShowGLEntries; BVRShowGLEntries)
                {
                    ApplicationArea = All;
                    Caption = 'Show Expected G/L Entries';
                    ToolTip = 'Specifies if the G/L entries the journal would post are simulated and listed under each document. The simulation is a full posting preview, so it takes about as long as posting the journal would.';
                }
            }
        }
    }

    rendering
    {
        layout("BVRGeneralJournalTestDim")
        {
            Type = RDLC;
            LayoutFile = './ReportLayouts/BVRGeneralJournalTest.rdl';
            Caption = 'General Journal - Test (with Dimensions)';
            Summary = 'General Journal - Test including Shortcut Dimension 1 and 2 columns and the expected G/L entries per document.';
        }
    }

    // Simulates the batch once, the first time a line of it asks for entries. Re-runs when the
    // report moves on to another batch.   //AAV.SP
    local procedure BVRPrepareBatch(JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        BatchKey: Text;
    begin
        BatchKey := JournalTemplateName + '|' + JournalBatchName;
        if BatchKey = BVRPreparedBatchKey then
            exit;

        BVRPreparedBatchKey := BatchKey;
        Clear(BVRShownDocNos);
        BVRStatusShown := false;

        BVRPreviewOk := BVRGLPreview.BuildEntries(JournalTemplateName, JournalBatchName, BVRTempGLEntry, BVRStatusText);
    end;

    var
        BVRTempGLEntry: Record "G/L Entry" temporary;
        BVRGLPreview: Codeunit "BVR Gen Jnl GL Preview";
        BVRShownDocNos: List of [Code[20]];
        BVRPreparedBatchKey: Text;
        BVRStatusText: Text;
        BVRGLAccNo: Code[20];
        BVRGLAccName: Text[100];
        BVRGLStatus: Text[250];
        BVRGLDebit: Decimal;
        BVRGLCredit: Decimal;
        BVRShowGLEntries: Boolean;
        BVRPreviewOk: Boolean;
        BVRStatusOnly: Boolean;
        BVRStatusShown: Boolean;
        BVRGLEntriesCaptionLbl: Label 'Expected G/L Entries';
        BVRGLAccNoCaptionLbl: Label 'G/L Account No.';
        BVRGLAccNameCaptionLbl: Label 'Account Name';
        BVRGLDebitCaptionLbl: Label 'Debit Amount';
        BVRGLCreditCaptionLbl: Label 'Credit Amount';
        BVRNoDocEntriesMsg: Label 'The simulated posting produced no G/L entries for this document.';
}
