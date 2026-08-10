// Extends the standard "General Journal - Test" report (ID 2) with:
//   * Shortcut Dimension 1 / 2 columns on the journal lines,
//   * an "Applied Entries" block printed per LINE, right after that line's dimensions - the open
//     customer, vendor or employee entries the line would settle. Written for the Cash Receipt
//     Journal, but driven by the line's own Applies-to fields, so any journal that applies gets it.
//   * an "Expected G/L Entries" block printed per DOCUMENT, after the last of that document's
//     journal lines - the entries the journal would actually post, taken from BC's own posting
//     preview rather than recalculated (see codeunit "BVR Gen Jnl GL Preview"). Account No.,
//     Account Name, Debit and Credit only: the dimensions already print on the journal lines above,
//     and repeating them on every entry was noise.
//
// Why per document and not per line: a G/L entry carries a Document No., never a journal line no.,
// so a document's entries cannot be split across the lines that produced them. The block is
// therefore printed once, after ALL of the document's lines - it summarises the document, so it has
// to follow the document rather than interrupt it.
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
                var
                    GeneralJnlTemplate: Record "Gen. Journal Template";
                begin
                    //if bvrshowGLEntries then
                    if generalJnlTemplate.Get("Gen. Journal Batch"."Journal Template Name") then
                        BVRShowGLEntries := generalJnlTemplate.Recurring
                    else
                        BVRShowGLEntries := false;

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
        // The entries this line will apply to - the open customer, vendor or employee entries it
        // settles. Written for the Cash Receipt Journal, where the question a reviewer actually has is
        // "which invoices does this receipt pay off", but it is driven entirely by the line's own
        // Applies-to fields, so a Payment Journal or any other journal that applies gets it too.
        //
        // Directly after DimensionLoop, so it reads line -> its dimensions -> what it applies to.
        //
        // SILENT when the line applies to nothing. On a long journal most lines do not apply, and a
        // "no applied entries" note against every one of them would bury the lines that do. The one
        // case that DOES print without entries is a line whose Applies-to reference matches no open
        // entry - a dangling application is exactly the kind of thing a test report exists to catch,
        // and it would otherwise fail silently at posting time.   //AAV.SP
        addafter(DimensionLoop)
        {
            dataitem(BVRAppliedEntryLoop; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));

                column(BVRAppliedNumber; Number)
                {
                }
                column(BVRAppliedDocType; BVRAppliedDocType)
                {
                }
                column(BVRAppliedDocNo; BVRAppliedDocNo)
                {
                }
                column(BVRAppliedPostingDate; BVRAppliedPostingDate)
                {
                }
                column(BVRAppliedDueDate; BVRAppliedDueDate)
                {
                }
                column(BVRAppliedDescription; BVRAppliedDescription)
                {
                }
                column(BVRAppliedCurrency; BVRAppliedCurrency)
                {
                }
                column(BVRAppliedRemaining; BVRAppliedRemaining)
                {
                }
                column(BVRAppliedToApply; BVRAppliedToApply)
                {
                }
                // Not an entry column - carries the dangling-application warning.
                column(BVRAppliedStatus; BVRAppliedStatus)
                {
                }
                column(BVRAppliedCaption; BVRAppliedCaptionLbl)
                {
                }
                column(BVRAppliedDocTypeCaption; BVRAppliedDocTypeCaptionLbl)
                {
                }
                column(BVRAppliedDocNoCaption; BVRAppliedDocNoCaptionLbl)
                {
                }
                column(BVRAppliedPostDateCaption; BVRAppliedPostDateCaptionLbl)
                {
                }
                column(BVRAppliedDueDateCaption; BVRAppliedDueDateCaptionLbl)
                {
                }
                column(BVRAppliedDescCaption; BVRAppliedDescCaptionLbl)
                {
                }
                column(BVRAppliedCurrencyCaption; BVRAppliedCurrencyCaptionLbl)
                {
                }
                column(BVRAppliedRemainingCaption; BVRAppliedRemainingCaptionLbl)
                {
                }
                column(BVRAppliedToApplyCaption; BVRAppliedToApplyCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                var
                    BVRRowCount: Integer;
                begin
                    BVRRowCount := BVRPrepareAppliedEntries("Gen. Journal Line");
                    if BVRRowCount = 0 then
                        CurrReport.Break();
                    SetRange(Number, 1, BVRRowCount);
                end;

                trigger OnAfterGetRecord()
                begin
                    Clear(BVRAppliedDocType);
                    Clear(BVRAppliedDocNo);
                    Clear(BVRAppliedPostingDate);
                    Clear(BVRAppliedDueDate);
                    Clear(BVRAppliedDescription);
                    Clear(BVRAppliedCurrency);
                    Clear(BVRAppliedRemaining);
                    Clear(BVRAppliedToApply);
                    Clear(BVRAppliedStatus);

                    if BVRAppliedStatusOnly then begin
                        BVRAppliedStatus := CopyStr(BVRAppliedStatusText, 1, MaxStrLen(BVRAppliedStatus));
                        exit;
                    end;

                    case BVRAppliedSource of
                        BVRAppliedSource::Customer:
                            begin
                                if Number = 1 then begin
                                    if not BVRCustLedgEntry.FindSet() then
                                        CurrReport.Break();
                                end else
                                    if BVRCustLedgEntry.Next() = 0 then
                                        CurrReport.Break();

                                // Remaining Amount is a FlowField on all three ledgers - without this
                                // every entry would print a remaining balance of zero.
                                BVRCustLedgEntry.CalcFields("Remaining Amount");
                                BVRAppliedDocType := Format(BVRCustLedgEntry."Document Type");
                                BVRAppliedDocNo := BVRCustLedgEntry."Document No.";
                                BVRAppliedPostingDate := Format(BVRCustLedgEntry."Posting Date");
                                BVRAppliedDueDate := Format(BVRCustLedgEntry."Due Date");
                                BVRAppliedDescription := BVRCustLedgEntry.Description;
                                BVRAppliedCurrency := BVRCustLedgEntry."Currency Code";
                                BVRAppliedRemaining := BVRCustLedgEntry."Remaining Amount";
                                BVRAppliedToApply := BVRCustLedgEntry."Amount to Apply";
                            end;
                        BVRAppliedSource::Vendor:
                            begin
                                if Number = 1 then begin
                                    if not BVRVendLedgEntry.FindSet() then
                                        CurrReport.Break();
                                end else
                                    if BVRVendLedgEntry.Next() = 0 then
                                        CurrReport.Break();

                                BVRVendLedgEntry.CalcFields("Remaining Amount");
                                BVRAppliedDocType := Format(BVRVendLedgEntry."Document Type");
                                BVRAppliedDocNo := BVRVendLedgEntry."Document No.";
                                BVRAppliedPostingDate := Format(BVRVendLedgEntry."Posting Date");
                                BVRAppliedDueDate := Format(BVRVendLedgEntry."Due Date");
                                BVRAppliedDescription := BVRVendLedgEntry.Description;
                                BVRAppliedCurrency := BVRVendLedgEntry."Currency Code";
                                BVRAppliedRemaining := BVRVendLedgEntry."Remaining Amount";
                                BVRAppliedToApply := BVRVendLedgEntry."Amount to Apply";
                            end;
                        BVRAppliedSource::Employee:
                            begin
                                if Number = 1 then begin
                                    if not BVREmplLedgEntry.FindSet() then
                                        CurrReport.Break();
                                end else
                                    if BVREmplLedgEntry.Next() = 0 then
                                        CurrReport.Break();

                                BVREmplLedgEntry.CalcFields("Remaining Amount");
                                BVRAppliedDocType := Format(BVREmplLedgEntry."Document Type");
                                BVRAppliedDocNo := BVREmplLedgEntry."Document No.";
                                BVRAppliedPostingDate := Format(BVREmplLedgEntry."Posting Date");
                                // Employee entries carry no due date - the column stays blank rather
                                // than borrowing the posting date and implying one.
                                BVRAppliedDescription := BVREmplLedgEntry.Description;
                                BVRAppliedCurrency := BVREmplLedgEntry."Currency Code";
                                BVRAppliedRemaining := BVREmplLedgEntry."Remaining Amount";
                                BVRAppliedToApply := BVREmplLedgEntry."Amount to Apply";
                            end;
                    end;
                end;
            }
        }
        // Last child of Gen. Journal Line, after ErrorLoop, so the block closes out a document:
        // every journal line of the document prints first, with its dimensions, allocations and
        // errors, and the expected entries follow as a summary of the whole document.
        //
        // Print ORDER comes from the order rows enter the dataset, not from where these rows sit in
        // the tablix - each dataset row makes exactly one tablix row visible. So moving the dataitem
        // moves the block; the layout needs no rework.
        addafter(ErrorLoop)
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
                column(BVRGLPostDate; BVRGLPostDate)
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
                column(BVRGLPostDateCaption; BVRGLPostDateCaptionLbl)
                {
                }
                trigger OnPreDataItem()
                var
                    BVRLaterLine: Record "Gen. Journal Line";
                begin
                    if not BVRShowGLEntries then
                        CurrReport.Break();

                    // Normally a no-op: BVRPreviewPrep already simulated this batch. Kept as a safety
                    // net so the block still works if the loop is ever reached without it.
                    BVRPrepareBatch("Gen. Journal Line"."Journal Template Name", "Gen. Journal Line"."Journal Batch Name");

                    // Wait for the document's LAST line. Anything earlier and the entries would cut
                    // into the document's own lines instead of summarising them.
                    BVRLaterLine.SetRange("Journal Template Name", "Gen. Journal Line"."Journal Template Name");
                    BVRLaterLine.SetRange("Journal Batch Name", "Gen. Journal Line"."Journal Batch Name");
                    BVRLaterLine.SetRange("Document No.", "Gen. Journal Line"."Document No.");
                    BVRLaterLine.SetFilter("Line No.", '>%1', "Gen. Journal Line"."Line No.");
                    // Honour any request-page date filter, so "last line" means the last line the
                    // report actually printed - not the last one in the table.
                    BVRLaterLine.SetFilter("Posting Date", "Gen. Journal Line".GetFilter("Posting Date"));
                    if not BVRLaterLine.IsEmpty() then
                        CurrReport.Break();

                    // Safety net for a document whose lines are not contiguous.
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
                    clear(BVRGLPostDate);
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
                    BVRGLPostDate := Format(BVRTempGLEntry."Posting Date");
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
                    Visible = false;
                    Caption = 'Show G/L Entries For Recurring';
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
            Summary = 'General Journal - Test including Shortcut Dimension 1 and 2 columns, the entries each line applies to, and the expected G/L entries per document.';
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

    // Sets up the applied-entry rows for one journal line and returns how many rows to print.
    //
    // Returns 0 for the ordinary case - a line that applies to nothing. Returns 1 with the status text
    // set when the line names an application that cannot be found, so the report says so instead of
    // printing an empty block.
    //
    // The real ledger records are filtered and walked directly rather than copied into a buffer: the
    // three ledgers have different shapes, and a buffer would mean flattening them into one and losing
    // the fields that differ.   //AAV.SP
    local procedure BVRPrepareAppliedEntries(var BVRGenJnlLine: Record "Gen. Journal Line") RowCount: Integer
    var
        BVRAccType: Enum "Gen. Journal Account Type";
        BVRAccNo: Code[20];
    begin
        BVRAppliedSource := BVRAppliedSource::" ";
        BVRAppliedStatusOnly := false;
        BVRAppliedStatusText := '';

        if (BVRGenJnlLine."Applies-to ID" = '') and (BVRGenJnlLine."Applies-to Doc. No." = '') then
            exit(0);
        if not BVRAppliedAccount(BVRGenJnlLine, BVRAccType, BVRAccNo) then
            exit(0);

        case BVRAccType of
            BVRAccType::Customer:
                begin
                    BVRAppliedSource := BVRAppliedSource::Customer;
                    BVRCustLedgEntry.Reset();
                    BVRCustLedgEntry.SetRange("Customer No.", BVRAccNo);
                    // Only open entries can be applied to. An Applies-to Doc. No. pointing at a closed
                    // entry is a genuine fault, and falls through to the warning below.
                    BVRCustLedgEntry.SetRange(Open, true);
                    if BVRGenJnlLine."Applies-to ID" <> '' then
                        BVRCustLedgEntry.SetRange("Applies-to ID", BVRGenJnlLine."Applies-to ID")
                    else begin
                        BVRCustLedgEntry.SetRange("Document No.", BVRGenJnlLine."Applies-to Doc. No.");
                        if BVRGenJnlLine."Applies-to Doc. Type" <> BVRGenJnlLine."Applies-to Doc. Type"::" " then
                            BVRCustLedgEntry.SetRange("Document Type", BVRGenJnlLine."Applies-to Doc. Type");
                    end;
                    RowCount := BVRCustLedgEntry.Count();
                end;
            BVRAccType::Vendor:
                begin
                    BVRAppliedSource := BVRAppliedSource::Vendor;
                    BVRVendLedgEntry.Reset();
                    BVRVendLedgEntry.SetRange("Vendor No.", BVRAccNo);
                    BVRVendLedgEntry.SetRange(Open, true);
                    if BVRGenJnlLine."Applies-to ID" <> '' then
                        BVRVendLedgEntry.SetRange("Applies-to ID", BVRGenJnlLine."Applies-to ID")
                    else begin
                        BVRVendLedgEntry.SetRange("Document No.", BVRGenJnlLine."Applies-to Doc. No.");
                        if BVRGenJnlLine."Applies-to Doc. Type" <> BVRGenJnlLine."Applies-to Doc. Type"::" " then
                            BVRVendLedgEntry.SetRange("Document Type", BVRGenJnlLine."Applies-to Doc. Type");
                    end;
                    RowCount := BVRVendLedgEntry.Count();
                end;
            BVRAccType::Employee:
                begin
                    BVRAppliedSource := BVRAppliedSource::Employee;
                    BVREmplLedgEntry.Reset();
                    BVREmplLedgEntry.SetRange("Employee No.", BVRAccNo);
                    BVREmplLedgEntry.SetRange(Open, true);
                    if BVRGenJnlLine."Applies-to ID" <> '' then
                        BVREmplLedgEntry.SetRange("Applies-to ID", BVRGenJnlLine."Applies-to ID")
                    else begin
                        BVREmplLedgEntry.SetRange("Document No.", BVRGenJnlLine."Applies-to Doc. No.");
                        if BVRGenJnlLine."Applies-to Doc. Type" <> BVRGenJnlLine."Applies-to Doc. Type"::" " then
                            BVREmplLedgEntry.SetRange("Document Type", BVRGenJnlLine."Applies-to Doc. Type");
                    end;
                    RowCount := BVREmplLedgEntry.Count();
                end;
            else
                exit(0);
        end;

        if RowCount = 0 then begin
            BVRAppliedStatusOnly := true;
            if BVRGenJnlLine."Applies-to ID" <> '' then
                BVRAppliedStatusText := StrSubstNo(BVRNoAppliedIDMsg, BVRGenJnlLine."Applies-to ID", BVRAccNo)
            else
                BVRAppliedStatusText := StrSubstNo(BVRNoAppliedDocMsg, BVRGenJnlLine."Applies-to Doc. No.", BVRAccNo);
            exit(1);
        end;
    end;

    // Which side of the line carries the application. A Cash Receipt Journal line usually puts the
    // customer on the Account and the bank on the Bal. Account, but the reverse is just as valid and
    // BC applies from whichever side is the customer, vendor or employee - so both are checked, the
    // Account side first.   //AAV.SP
    local procedure BVRAppliedAccount(var BVRGenJnlLine: Record "Gen. Journal Line"; var BVRAccType: Enum "Gen. Journal Account Type"; var BVRAccNo: Code[20]): Boolean
    begin
        if BVRIsApplicableAccount(BVRGenJnlLine."Account Type") and (BVRGenJnlLine."Account No." <> '') then begin
            BVRAccType := BVRGenJnlLine."Account Type";
            BVRAccNo := BVRGenJnlLine."Account No.";
            exit(true);
        end;
        if BVRIsApplicableAccount(BVRGenJnlLine."Bal. Account Type") and (BVRGenJnlLine."Bal. Account No." <> '') then begin
            BVRAccType := BVRGenJnlLine."Bal. Account Type";
            BVRAccNo := BVRGenJnlLine."Bal. Account No.";
            exit(true);
        end;
        exit(false);
    end;

    local procedure BVRIsApplicableAccount(BVRAccType: Enum "Gen. Journal Account Type"): Boolean
    begin
        exit(BVRAccType in [BVRAccType::Customer, BVRAccType::Vendor, BVRAccType::Employee]);
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
        BVRGLPostDate: text[50];
        BVRShowGLEntries: Boolean;
        BVRPreviewOk: Boolean;
        BVRStatusOnly: Boolean;
        BVRStatusShown: Boolean;
        BVRGLEntriesCaptionLbl: Label 'Expected G/L Entries';
        BVRGLAccNoCaptionLbl: Label 'G/L Account No.';
        BVRGLAccNameCaptionLbl: Label 'Account Name';
        BVRGLDebitCaptionLbl: Label 'Debit Amount';
        BVRGLCreditCaptionLbl: Label 'Credit Amount';
        BVRGLPostDateCaptionLbl: Label 'Posting Date';
        BVRNoDocEntriesMsg: Label 'The simulated posting produced no G/L entries for this document.';
        BVRCustLedgEntry: Record "Cust. Ledger Entry";
        BVRVendLedgEntry: Record "Vendor Ledger Entry";
        BVREmplLedgEntry: Record "Employee Ledger Entry";
        BVRAppliedSource: Option " ",Customer,Vendor,Employee;
        BVRAppliedStatusOnly: Boolean;
        BVRAppliedStatusText: Text;
        BVRAppliedDocType: Text[30];
        BVRAppliedDocNo: Code[20];
        BVRAppliedPostingDate: Text[30];
        BVRAppliedDueDate: Text[30];
        BVRAppliedDescription: Text[100];
        BVRAppliedCurrency: Code[10];
        BVRAppliedRemaining: Decimal;
        BVRAppliedToApply: Decimal;
        BVRAppliedStatus: Text[250];
        BVRAppliedCaptionLbl: Label 'Applied Entries';
        BVRAppliedDocTypeCaptionLbl: Label 'Document Type';
        BVRAppliedDocNoCaptionLbl: Label 'Document No.';
        BVRAppliedPostDateCaptionLbl: Label 'Posting Date';
        BVRAppliedDueDateCaptionLbl: Label 'Due Date';
        BVRAppliedDescCaptionLbl: Label 'Description';
        BVRAppliedCurrencyCaptionLbl: Label 'Currency';
        BVRAppliedRemainingCaptionLbl: Label 'Remaining Amount';
        BVRAppliedToApplyCaptionLbl: Label 'Amount to Apply';
        BVRNoAppliedIDMsg: Label 'This line applies by ID %1, but no open entry for %2 is marked with it. Nothing would be applied.', Comment = '%1 = Applies-to ID, %2 = account no.';
        BVRNoAppliedDocMsg: Label 'This line applies to document %1, but %2 has no open entry with that number. Nothing would be applied.', Comment = '%1 = Applies-to Doc. No., %2 = account no.';
}
