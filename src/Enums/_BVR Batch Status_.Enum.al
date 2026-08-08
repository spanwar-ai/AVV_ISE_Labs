enum 50159 "BVR Batch Status"
{
    // Open is 0 so batches created before this field existed stay usable without a data fix.
    // A batch closes automatically once the last document in it has been posted; closed batches are
    // filtered out of the Batch No. lookups on the Warehouse Receipt and the Purchase Invoice, but
    // stay visible on the batch lists as history.   //AAV.SP
    Extensible = true;

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; Closed)
    {
        Caption = 'Closed';
    }
}
