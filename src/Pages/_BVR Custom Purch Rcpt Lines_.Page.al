page 50121 "BVR Custom Purch Rcpt Lines"
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
                        if not(Rec.Type in[Rec.Type::Item, Rec.Type::"G/L Account"])then Error('Only Item and G/L Account lines are allowed in Custom Purchase Receipt.');
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        ItemRec: Record Item;
                    begin
                        if Rec.Type = Rec.Type::Item then begin
                            ItemRec.Get(Rec."No.");
                            if not(ItemRec.Type in[ItemRec.Type::Inventory, ItemRec.Type::"Non-Inventory"])then Error('Only Inventory and Non-Inventory items are allowed.');
                        end;
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field("BVR Source PO No."; Rec."BVR Source PO No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("BVR Source PO Line No."; Rec."BVR Source PO Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Quantity';
                }
                field("BVR Remaining Qty"; Rec."BVR Remaining Qty")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Remaining Quantity';
                }
                //field("Qty. to Receive"; Rec."Qty. to Receive") { ApplicationArea = All; }
                field("Qty. to Receive"; Rec."Qty. to Receive")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        SrcLine: Record "Purchase Line";
                        RemQty: Decimal;
                    begin
                        if Rec."Qty. to Receive" < 0 then Error('Qty. to Receive cannot be negative.');
                        if Rec."Qty. to Receive" = 0 then exit;
                        if(Rec."BVR Source PO No." = '') or (Rec."BVR Source PO Line No." = 0)then Error('Source PO link is missing. Use Get PO Lines to populate lines.');
                        SrcLine.Get(SrcLine."Document Type"::Order, Rec."BVR Source PO No.", Rec."BVR Source PO Line No.");
                        RemQty:=SrcLine.Quantity - SrcLine."Quantity Received";
                        if RemQty <= 0 then Error('Nothing remaining to receive for PO %1 line %2.', Rec."BVR Source PO No.", Rec."BVR Source PO Line No.");
                        //message('%1', rec."Qty. to Receive");
                        if Rec."Qty. to Receive" > RemQty then Error('Qty. to Receive (%1) cannot exceed remaining (%2) for PO %3 line %4.', Rec."Qty. to Receive", RemQty, Rec."BVR Source PO No.", Rec."BVR Source PO Line No.");
                        Rec."BVR Remaining Qty":=RemQty;
                    end;
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
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
