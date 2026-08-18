enum 50170 "BVR API Sales Line Type"
{
    // The line type as the CALLER spells it, which is not how Business Central spells it. The
    // integration sends "Account" and "Charge"; the Sales Line enum says "G/L Account" and
    // "Charge (Item)". Rather than make the caller learn our vocabulary, the API speaks theirs and
    // translates on the way in - see BVRToSalesLineType in page "BVR Sales Invoice Line API".
    //
    // The wording here is Microsoft's own API vocabulary, the same values their salesInvoiceLines
    // endpoint accepts, so a client written against the standard API needs no changes.   //AAV.SP
    Extensible = false;
    Caption = 'API Sales Line Type';

    value(0; Comment)
    {
        Caption = 'Comment';
    }
    value(1; Account)
    {
        Caption = 'Account';
    }
    value(2; Item)
    {
        Caption = 'Item';
    }
    value(3; Resource)
    {
        Caption = 'Resource';
    }
    value(4; "Fixed Asset")
    {
        Caption = 'Fixed Asset';
    }
    value(5; Charge)
    {
        Caption = 'Charge';
    }
}
