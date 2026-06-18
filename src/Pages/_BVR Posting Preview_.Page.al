page 50251 "BVR Posting Preview"
{
    PageType = List;
    SourceTable = "BVR Posting Preview Line";
    Caption = 'Posting Preview';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Gen)
            {
                field("Is Summary"; Rec."Is Summary")
                {
                    ApplicationArea = All;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                }
                field("Debit/Credit"; Rec."Debit/Credit")
                {
                    ApplicationArea = All;
                }
                field("Is Item Ledger"; Rec."Is Item Ledger")
                {
                    ApplicationArea = All;
                }
                field("Account/Doc"; Rec."Account/Doc")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                }
                field("Bal. Account"; Rec."Bal. Account")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Account';
                }
            }
        }
    }
}
