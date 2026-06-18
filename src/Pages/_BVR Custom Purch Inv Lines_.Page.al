page 50131 "BVR Custom Purch Inv Lines"
{
    PageType = ListPart;
    SourceTable = "Purchase Line";
    Caption = 'Lines';
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        if not(Rec.Type in[Rec.Type::Item, Rec.Type::"G/L Account"])then Error('Only Item and G/L Account lines are allowed.');
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = All;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = All;
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = All;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = All;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = All;
                }
                field("Prepayment %"; Rec."Prepayment %")
                {
                    ApplicationArea = All;
                }
                field("Prepayment Amount"; Rec."Prepayment Amount")
                {
                    ApplicationArea = All;
                }
                field("BVR Source Rcpt No."; Rec."BVR Source Rcpt No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("BVR Source Rcpt Line No."; Rec."BVR Source Rcpt Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }
}
