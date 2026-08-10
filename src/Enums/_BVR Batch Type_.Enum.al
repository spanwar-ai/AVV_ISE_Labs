enum 50148 "BVR Batch Type"
{
    // Scopes a "BVR Doc Batch" to one kind of document, so a Receipt batch cannot be picked on an
    // invoice and vice versa. Receipt is 0 so batches created before this field existed - which were
    // all warehouse-receipt batches - keep the right meaning without a data fix.   //AAV.SP
    Extensible = true;

    value(0; Receipt)
    {
        Caption = 'Receipt';
    }
    value(1; "Purchase Invoice")
    {
        Caption = 'Purchase Invoice';
    }
    value(2; "Purch. Credit Memo")
    {
        Caption = 'Purchase Credit Memo';
    }
    value(3; "Sales Order")
    {
        Caption = 'Sales Order';
    }
    value(4; "Sales Credit Memo")
    {
        Caption = 'Sales Credit Memo';
    }
}
