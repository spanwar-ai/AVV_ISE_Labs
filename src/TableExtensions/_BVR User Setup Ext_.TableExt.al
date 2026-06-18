tableextension 50117 "BVR User Setup Ext" extends "User Setup"
{
    fields
    {
        // Identifies AP-team users who may still edit the accrual accounts on a
        // Custom Purchase Receipt after it has been marked "AP Updated".  //AAV.SP
        field(50130; "BVR AP Team"; Boolean)   //AAV.SP
        {
            Caption = 'AP Team';
            DataClassification = CustomerContent;
        }
    }
}
