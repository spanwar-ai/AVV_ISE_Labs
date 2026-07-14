tableextension 50210 "BVR Purch Header Approval Ext" extends "Purchase Header"
{
    fields
    {
        field(50201; "BVR AP Updated"; Boolean)
        {
            Caption = 'AP Updated';
            DataClassification = CustomerContent;
        }
        field(50202; "BVR Sent For Approval"; Boolean)
        {
            Caption = 'Sent For Approval';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50203; "BVR Approved"; Boolean)
        {
            Caption = 'Approved';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50204; "BVR Requires Approval"; Boolean)
        {
            Caption = 'Requires Approval';
            DataClassification = CustomerContent;
        }
        // Single user-facing status for the custom receipt approval flow. Kept in
        // sync with the booleans above by codeunit "BVR Cust Rcpt Appr Mgt".   //AAV.SP
        field(50205; "BVR Receipt Status"; Enum "BVR Receipt Status")   //AAV.SP
        {
            Caption = 'Receipt Status';
            DataClassification = CustomerContent;
            Editable = false;
        }
        // Standard-PO accrual flow: set when the PO is sent to the AP team to update the
        // accrual accounts, cleared on Reopen. Gates the standard Send Approval Request so
        // it can only be raised after the AP team has been notified.   //AAV
        field(50206; "BVR Sent To AP Team"; Boolean)   //AAV
        {
            Caption = 'Sent To AP Team';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
