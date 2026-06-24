enum 50101 "BVR Receipt Status"
{
    // Single, user-facing status for the Custom Purchase Receipt approval flow.   //AAV.SP
    // Drives (and is kept in sync with) the legacy booleans on Purchase Header so
    // existing posting/preview logic keeps working.
    //
    // Lifecycle: Open -> Sent to AP Team -> Pending Approval -> Released -> Posted
    Extensible = true;

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; "Sent to AP Team")
    {
        Caption = 'Sent to AP Team';
    }
    value(2; "Pending Approval")
    {
        Caption = 'Pending Approval';
    }
    value(3; Released)
    {
        Caption = 'Released';
    }
    value(4; Posted)
    {
        Caption = 'Posted';
    }
}
