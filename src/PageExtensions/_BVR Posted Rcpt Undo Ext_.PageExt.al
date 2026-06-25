pageextension 50135 "BVR Posted Rcpt Undo Ext" extends "Posted Purchase Rcpt. Subform"
{
    // For CUSTOM receipts the standard Undo Receipt cannot work (item-journal entries
    // post as fully invoiced), so it is hidden and replaced by "Undo Custom Receipt",
    // which reverses inventory, the accrual G/L, the source PO qty and the status.
    // Standard (non-custom) receipts keep the native Undo Receipt unchanged.   //AAV.SP

    layout
    {
        addafter(Quantity)
        {
            field("BVR Accrual Reversed"; Rec."BVR Accrual Reversed")   //AAV.SP
            {
                ApplicationArea = All;
                Caption = 'Undone';
                ToolTip = 'Specifies that this custom receipt line has been undone.';
                Visible = IsCustomReceiptPage;
            }
        }
    }

    actions
    {
        // Hide the native Undo for custom receipts (it would only error).
        modify("&Undo Receipt")
        {
            Visible = not IsCustomReceiptPage;   //AAV.SP
        }

        addlast(processing)
        {
            action("BVR Undo Custom Receipt")   //AAV.SP
            {
                ApplicationArea = All;
                Caption = 'Undo Custom Receipt';
                Image = Undo;
                Visible = IsCustomReceiptPage;
                ToolTip = 'Reverse the selected custom receipt line(s): inventory, the accrual G/L entry, the source PO quantity and the order status.';

                trigger OnAction()
                var
                    RcptLine: Record "Purch. Rcpt. Line";
                    UndoMgt: Codeunit "BVR Undo Receipt Accrual";
                    UndoneCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(RcptLine);
                    RcptLine.SetRange("BVR Custom Receipt", true);
                    RcptLine.SetRange(Correction, false);
                    RcptLine.SetRange("BVR Accrual Reversed", false);
                    RcptLine.SetFilter(Quantity, '>0');
                    if RcptLine.IsEmpty() then begin
                        Message(NothingToUndoMsg);
                        exit;
                    end;
                    if not Confirm(ConfirmUndoQst, false) then
                        exit;

                    if RcptLine.FindSet() then
                        repeat
                            UndoMgt.UndoCustomReceiptLine(RcptLine);
                            UndoneCount += 1;
                        until RcptLine.Next() = 0;

                    Message(UndoneMsg, UndoneCount);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsCustomReceiptPage := Rec."BVR Custom Receipt";   //AAV.SP
    end;

    var
        IsCustomReceiptPage: Boolean;   //AAV.SP
        ConfirmUndoQst: Label 'Undo the selected custom receipt line(s)? This reverses the inventory and the accrual postings.';   //AAV.SP
        NothingToUndoMsg: Label 'There are no custom receipt lines to undo in the selection.';   //AAV.SP
        UndoneMsg: Label '%1 custom receipt line(s) undone.', Comment = '%1 = number of undone lines';   //AAV.SP
}
