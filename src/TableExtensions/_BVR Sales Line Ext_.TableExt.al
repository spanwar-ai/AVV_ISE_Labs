tableextension 50128 "BVR Sales Line Ext" extends "Sales Line"
{
    fields
    {
        // The line type as the CALLER spells it, for page "BVR Sales Invoice Line API".
        //
        // It exists because the API field has to be backed by a TABLE field. It was backed by a page
        // variable, and on a POST that variable never received the caller's "lineType": it stayed at
        // its default - Comment, because that is value 0 - which translates to a Sales Line of type
        // blank. Validating "No." on a blank line makes Business Central look the value up as a
        // Standard Text, so an account number arrived as "The Standard Text does not exist. Code
        // ='4010'". A table field is written by the framework the same way every other field on the
        // request is.
        //
        // It is an input channel, not a second source of truth: the line's real type is Sales Line's
        // own Type, and the API page refreshes this field from it on every read, so a line created in
        // the client rather than through the API still reports its type correctly.   //AAV.SP
        field(50170; "BVR API Line Type"; Enum "BVR API Sales Line Type")
        {
            Caption = 'API Line Type';
            DataClassification = CustomerContent;
        }
    }
}
