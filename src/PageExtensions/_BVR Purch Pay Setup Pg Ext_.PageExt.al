pageextension 50133 "BVR Purch Pay Setup Pg Ext" extends "Purchases & Payables Setup"
{
    layout
    {
        addlast(General)
        {
            field("BVR AP Team Email"; Rec."BVR AP Team Email")   //AAV.SP
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the email address(es) notified when a Custom Purchase Receipt is sent to the AP team to update the accrual accounts. Separate multiple addresses with a semicolon.';
            }
        }
    }

    actions
    {
        addlast(navigation)
        {
            // One-click: create and enable the Warehouse Receipt approval workflow, so admins
            // don't have to assemble it in the workflow editor.   //AAV.SP
            action("BVR Enable WR Approval Workflow")   //AAV.SP
            {
                ApplicationArea = All;
                Caption = 'Enable Warehouse Receipt Approval';
                Image = Approvals;
                ToolTip = 'Create and enable a ready-to-use approval workflow for Warehouse Receipts. Run this once before using Send for Approval on a Warehouse Receipt.';

                trigger OnAction()
                var
                    WFSetup: Codeunit "BVR Whse Rcpt Appr WF Setup";
                begin
                    WFSetup.CreateAndEnableWorkflow();
                end;
            }
        }
    }
}
