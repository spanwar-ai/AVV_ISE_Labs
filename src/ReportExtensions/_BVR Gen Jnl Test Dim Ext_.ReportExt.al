// Adds Shortcut Dimension 1 / 2 columns to the standard "General Journal - Test" report (ID 2).
//
// A report extension cannot change the base RDLC, so the two columns are only visible through the
// layout added below - ReportLayouts/BVRGeneralJournalTest.rdlc, a copy of the base layout with the
// extra columns. Users must select it on the Report Layouts page (or it can be made the default
// there) for the columns to print.
//
// Caption columns sit on "Integer" and value columns on "Gen. Journal Line", mirroring how the base
// report separates its own captions from its data.   //AAV.SP
reportextension 50146 "BVR Gen Jnl Test Dim Ext" extends "General Journal - Test"
{
    dataset
    {
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
    }

    rendering
    {
        layout("BVRGeneralJournalTestDim")
        {
            Type = RDLC;
            LayoutFile = './ReportLayouts/BVRGeneralJournalTest.rdl';
            Caption = 'General Journal - Test (with Dimensions)';
            Summary = 'General Journal - Test including Shortcut Dimension 1 and 2 columns.';
        }
    }
}
