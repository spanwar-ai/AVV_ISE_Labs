enum 50180 "BVR GL Dim Corr Status"
{
    // Where one staged G/L entry has got to. Pending is 0 so a row that is pasted or imported - and
    // therefore never has this field written - starts in the right state on its own.
    //
    // Validated and Pending are treated alike by Process; validating is a dry run the team can take
    // before committing, not a gate. Only Processed means a G/L entry was actually changed, and only
    // Processed rows can be reverted.   //AAV.SP
    Extensible = true;

    value(0; Pending)
    {
        Caption = 'Pending';
    }
    value(1; Validated)
    {
        Caption = 'Validated';
    }
    value(2; Processed)
    {
        Caption = 'Processed';
    }
    value(3; Failed)
    {
        Caption = 'Error';
    }
    value(4; Reverted)
    {
        Caption = 'Reverted';
    }
}
