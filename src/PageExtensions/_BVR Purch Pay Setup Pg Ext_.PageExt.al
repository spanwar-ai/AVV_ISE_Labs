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
}
