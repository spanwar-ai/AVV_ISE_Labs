pageextension 50118 "BVR User Setup Pg Ext" extends "User Setup"
{
    layout
    {
        addlast(Control1)
        {
            field("BVR AP Team"; Rec."BVR AP Team")   //AAV.SP
            {
                ApplicationArea = All;
                ToolTip = 'Specifies that this user belongs to the AP team and may edit the accrual accounts on a Custom Purchase Receipt after it has been marked AP Updated.';
            }
            field("BVR GL Posting Allowed"; Rec."BVR GL Posting Allowed")   //AAV.SP
            {
                ApplicationArea = All;
                ToolTip = 'Specifies that this user may post general journal batches of any type - General, Sales, Purchases, Cash Receipts, Payments and so on. Users without it can still open and edit journals, and can still preview a posting, but cannot post one.';
            }
        }
    }
}
