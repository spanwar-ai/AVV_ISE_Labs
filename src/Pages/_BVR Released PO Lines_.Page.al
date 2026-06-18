page 50151 "BVR Released PO Lines"
{
    PageType = List;
    SourceTable = "BVR PO Line Buffer";
    Caption = 'Released Purchase Order Lines';
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(Gen)
            {
                field("Select"; Rec."Select")
                {
                    ApplicationArea = All;
                }
                field("PO No."; Rec."PO No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("PO Line No."; Rec."PO Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Quantity Received"; Rec."Quantity Received")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(OK)
            {
                Caption = 'OK';
                Image = Approve;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }
}
