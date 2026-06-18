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
    }
}
