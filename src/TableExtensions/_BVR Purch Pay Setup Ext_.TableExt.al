tableextension 50119 "BVR Purch Pay Setup Ext" extends "Purchases & Payables Setup"
{
    fields
    {
        // Recipient(s) notified when a Custom Purchase Receipt is sent to the AP team
        // to update the accrual accounts. Separate multiple addresses with ';'.   //AAV.SP
        field(50130; "BVR AP Team Email"; Text[250])   //AAV.SP
        {
            Caption = 'AP Team Email';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;
        }
    }
}
