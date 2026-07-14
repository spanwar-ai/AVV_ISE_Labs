pageextension 50111 "BVR Purchase Order Ext" extends "Purchase Order"
{
    // Standard purchase order accrual flow. BC's STANDARD status and STANDARD approval
    // process drive the document; we only add:   //AAV
    //   * a "Send to AP Team" step (notifies AP, marks BVR Sent To AP Team),
    //   * "Send Approval Request" enabled only for AP-team users, after Send to AP Team,
    //     and only once both accrual accounts are filled,
    //   * accrual accounts editable only while Status = Open.
    // Reopen clears the marker so the PO must be sent to AP again (handled in the codeunit).
    layout
    {
        addlast(General)
        {
            field("BVR Sent To AP Team"; Rec."BVR Sent To AP Team")   //AAV
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies that this Purchase Order has been sent to the AP team to update the accrual accounts. Cleared when the order is reopened.';
            }
            field("BVR Expense Accrual Acc No."; Rec."BVR Expense Accrual Acc No.")   //AAV
            {
                ApplicationArea = All;
                Editable = Rec.Status = Rec.Status::Open;   //AAV - editable only while Open (locked once sent for approval)
                ToolTip = 'G/L account debited (Expense Accrual) when this Purchase Order''s receipt is posted.';
            }
            field("BVR Vendor Accrual Acc No."; Rec."BVR Vendor Accrual Acc No.")   //AAV
            {
                ApplicationArea = All;
                Editable = Rec.Status = Rec.Status::Open;   //AAV - editable only while Open
                ToolTip = 'G/L account credited (Vendor Accrual / GRNI liability) when this Purchase Order''s receipt is posted.';
            }
        }
    }

    actions
    {
        // Promote "Send to AP Team" onto the Home tab, right after Release.   //AAV
        addafter(Category_Category5)
        {
            actionref("BVR Send to AP Team_Promoted"; "BVR Send to AP Team") { }   //AAV
        }
        addlast(processing)
        {
            action("BVR Send to AP Team")                                                        //AAV
            {                                                                                    //AAV
                ApplicationArea = All;                                                           //AAV
                Caption = 'Send to AP Team';                                                     //AAV
                Image = SendTo;                                       //AAV
                Enabled = (Rec.Status = Rec.Status::Open);   //AAV
                ToolTip = 'Send this Purchase Order to the AP team to update the accrual accounts. The AP team is notified by email and can then send it for approval.'; //AAV

                trigger OnAction()                                                               //AAV
                var                                                                              //AAV
                    StdApprMgt: Codeunit "BVR Std PO Appr Mgt";                                  //AAV
                begin                                                                            //AAV
                    StdApprMgt.SendToAPTeam(Rec);                                                //AAV
                    CurrPage.Update(false);                                                      //AAV
                end;                                                                             //AAV
            }                                                                                    //AAV
        }
        // Standard Send Approval Request: AP-team users only, after Send to AP Team, and only
        // once both accrual accounts are filled. Everything else (approve/reject/delegate/
        // cancel, and the posting restriction while pending) is standard BC.   //AAV
        modify(SendApprovalRequest)
        {
            Enabled = IsAPTeamUser and (Rec.Status = Rec.Status::Open) and Rec."BVR Sent To AP Team"   //AAV
                      and (Rec."BVR Expense Accrual Acc No." <> '') and (Rec."BVR Vendor Accrual Acc No." <> '');   //AAV
        }
        modify("Send Intercompany Purchase Order")
        {
            visible = false;
        }
        modify("Create Inventor&y Put-away/Pick")
        {
            visible = false;
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CustApprMgt: Codeunit "BVR Cust Rcpt Appr Mgt";   //AAV
    begin
        IsAPTeamUser := CustApprMgt.IsAPTeam();   //AAV
    end;

    var
        IsAPTeamUser: Boolean;   //AAV
}
