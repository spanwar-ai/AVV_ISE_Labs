page 50149 "BVR Custom Posted Receipts"
{
    PageType = List;
    SourceTable = "Purch. Rcpt. Header";
    Caption = 'Custom Posted Purchase Receipts';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Gen)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = All;
                }
                //field("External Document No."; Rec."External Document No.") { ApplicationArea = All; }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        Rec.SetRange("BVR Custom Receipt", true);
    end;
}
