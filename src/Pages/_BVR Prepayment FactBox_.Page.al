page 50282 "BVR Prepayment FactBox"
{
    PageType = ListPart;
    SourceTable = "Purchase Line";
    Caption = 'Prepayment Details';
    Editable = false;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Prepayment %"; rec."Prepayment %")
                {
                }
                field("Prepayment Amount"; rec."Prepayment Amount")
                {
                }
                field("Prepmt. Amt. Inv."; rec."Prepmt. Amt. Inv.")
                {
                    Caption = 'Invoiced Prepayment';
                }
                field("Prepmt Amt Deducted"; rec."Prepmt Amt Deducted")
                {
                    Caption = 'Prepayment Deducted';
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        Rec.SetRange("Prepayment Line", true);
    end;
}
