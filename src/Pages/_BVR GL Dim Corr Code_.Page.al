page 50181 "BVR GL Dim Corr Code"
{
    // Asks for the access code that guards "BVR GL Dim Corrections".
    //
    // A page rather than a plain dialog because AL has no masked input outside one: ExtendedDatatype =
    // Masked is a field property, and a field needs a page to live on.   //AAV.SP
    PageType = StandardDialog;
    Caption = 'Access Code';
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            group(Access)
            {
                Caption = 'Access Code';
                InstructionalText = 'Enter the access code to open G/L Dimension Corrections.';

                field(AccessCode; AccessCode)
                {
                    ApplicationArea = All;
                    Caption = 'Access Code';
                    ExtendedDatatype = Masked;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the access code for the G/L dimension correction worksheet.';
                }
            }
        }
    }

    procedure GetAccessCode(): Text[30]
    begin
        exit(AccessCode);
    end;

    var
        AccessCode: Text[30];
}
