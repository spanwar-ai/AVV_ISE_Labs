page 50180 "BVR GL Dim Corrections"
{
    // The worksheet for a bulk dimension correction on posted G/L entries.
    //
    // Load it, look at it, process it. The three input columns sit next to what the entry says today,
    // so a wrong entry number shows itself as an account and an amount nobody recognises before
    // anything is written.
    //
    // Editable and insertable so a list of corrections can be pasted straight in from Excel - entry
    // number, new dimension 1, new dimension 2 - which is the way ten thousand of them arrive. The
    // Import from File action does the same job for a .csv.   //AAV.SP
    PageType = List;
    SourceTable = "BVR GL Dim Correction";
    Caption = 'G/L Dimension Corrections';
    ApplicationArea = All;
    UsageCategory = Tasks;
    Editable = true;
    InsertAllowed = true;
    DeleteAllowed = true;
    SourceTableView = sorting("G/L Entry No.");
    Permissions = tabledata "G/L Entry" = rimd;

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                field("G/L Entry No."; Rec."G/L Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posted G/L entry to correct. One line per entry - an entry cannot be staged twice.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyleTxt;
                    ToolTip = 'Specifies how far this line has got. Pending and Validated lines are the ones Process will act on; only Processed lines can be reverted.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyleTxt;
                    ToolTip = 'Specifies why this line could not be validated or processed.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the G/L entry being corrected.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document the G/L entry was posted from.';
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the account the G/L entry was posted to.';
                }
                field("Entry Description"; Rec."Entry Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description on the G/L entry.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the G/L entry.';
                }
                field("Current Global Dim 1 Code"; Rec."Current Global Dim 1 Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the global dimension 1 value the entry carries today.';
                }
                field("New Global Dim 1 Code"; Rec."New Global Dim 1 Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the global dimension 1 value the entry should carry. Leave it blank to leave that dimension alone.';
                }
                field("Clear Global Dim 1"; Rec."Clear Global Dim 1")
                {
                    ApplicationArea = All;
                    visible = false;
                    ToolTip = 'Specifies that global dimension 1 should be removed from the entry altogether. Only tick this to remove a value - a blank New Global Dimension 1 Code on its own leaves the dimension as it is.';
                }
                field("Current Global Dim 2 Code"; Rec."Current Global Dim 2 Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the global dimension 2 value the entry carries today.';
                }
                field("New Global Dim 2 Code"; Rec."New Global Dim 2 Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the global dimension 2 value the entry should carry. Leave it blank to leave that dimension alone.';
                }
                field("Clear Global Dim 2"; Rec."Clear Global Dim 2")
                {
                    ApplicationArea = All;
                    visible = false;
                    ToolTip = 'Specifies that global dimension 2 should be removed from the entry altogether.';
                }
                field("Processed At"; Rec."Processed At")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies when this line was processed or reverted.';
                }
                field("Processed By"; Rec."Processed By")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies who processed or reverted this line.';
                }
                field("Previous Dimension Set ID"; Rec."Previous Dimension Set ID")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the dimension set the entry carried before it was corrected. This is what Revert puts back.';
                }
                field("New Dimension Set ID"; Rec."New Dimension Set ID")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the dimension set the entry was moved to.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("BVR Prepare")
            {
                Caption = 'Prepare';
                Image = Journal;

                action("BVR Import From File")
                {
                    ApplicationArea = All;
                    Caption = 'Import from File';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Loads lines from a comma-separated file with three columns: G/L Entry No., new global dimension 1 value, new global dimension 2 value. A header row is skipped. Lines for entries already in the list are overwritten.';

                    trigger OnAction()
                    var
                        BVRGLDimCorrectionMgt: Codeunit "BVR GL Dim Correction Mgt";
                    begin
                        BVRGLDimCorrectionMgt.ImportFromFile();
                        CurrPage.Update(false);
                    end;
                }
            }
            group("BVR Run")
            {
                Caption = 'Correct';
                Image = ChangeDimensions;

                action("BVR Process")
                {
                    ApplicationArea = All;
                    Caption = 'Process';
                    Image = Apply;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Checks every line in the list that has not been processed, then writes the new dimensions onto the G/L entries of the lines that passed. Lines that fail the check are left alone with the reason in the Error Message column, and you are told how many before anything is written. Filter the list first to process only part of it.';

                    trigger OnAction()
                    var
                        BVRGLDimCorrectionMgt: Codeunit "BVR GL Dim Correction Mgt";
                    begin
                        BVRGLDimCorrectionMgt.ProcessLines(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action("BVR Revert")
                {
                    ApplicationArea = All;
                    Caption = 'Revert';
                    Image = Undo;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Puts the G/L entries of every processed line in the list back to the dimensions they carried before. A line whose entry has been changed by something else since is left alone and says so.';

                    trigger OnAction()
                    var
                        BVRGLDimCorrectionMgt: Codeunit "BVR GL Dim Correction Mgt";
                    begin
                        BVRGLDimCorrectionMgt.RevertLines(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action("BVR Delete Finished")
                {
                    ApplicationArea = All;
                    Caption = 'Delete Finished Lines';
                    Image = ClearLog;
                    ToolTip = 'Removes the lines in the list that have been processed or reverted, leaving the work still to do. The G/L entries keep their corrected dimensions.';

                    trigger OnAction()
                    var
                        BVRGLDimCorrectionMgt: Codeunit "BVR GL Dim Correction Mgt";
                    begin
                        BVRGLDimCorrectionMgt.DeleteFinishedLines(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            group("BVR Show")
            {
                Caption = 'Entry';
                Image = Entries;

                action("BVR Show GL Entry")
                {
                    ApplicationArea = All;
                    Caption = 'Show G/L Entry';
                    Image = GLRegisters;
                    ToolTip = 'Opens the posted G/L entry this line corrects.';

                    trigger OnAction()
                    var
                        GLEntry: Record "G/L Entry";
                    begin
                        GLEntry.SetRange("Entry No.", Rec."G/L Entry No.");
                        Page.Run(Page::"General Ledger Entries", GLEntry);
                    end;
                }
            }
        }
    }

    // Asked for every time the worksheet is opened, not once a session. Opening this page is a
    // deliberate act - it is the one place in the app that rewrites posted entries - and the prompt is
    // there to make sure it was meant.   //AAV.SP
    trigger OnOpenPage()
    var
        BVRGLDimCorrectionMgt: Codeunit "BVR GL Dim Correction Mgt";
    begin
        BVRGLDimCorrectionMgt.CheckAccessCode();
    end;

    trigger OnAfterGetRecord()
    begin
        SetStatusStyle();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetStatusStyle();
    end;

    local procedure SetStatusStyle()
    begin
        case Rec.Status of
            Rec.Status::Failed:
                StatusStyleTxt := 'Unfavorable';
            Rec.Status::Processed:
                StatusStyleTxt := 'Favorable';
            Rec.Status::Reverted:
                StatusStyleTxt := 'Ambiguous';
            else
                StatusStyleTxt := 'Standard';
        end;
    end;

    var
        StatusStyleTxt: Text;
}
