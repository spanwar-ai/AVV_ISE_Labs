page 50132 "BVR Custom Purch Invoice List"
{
    PageType = List;
    SourceTable = "Purchase Header";
    Caption = 'Custom Purchase Invoices';
    // ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "BVR Custom Purch Invoice";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    // Show only invoices (and typically only those created for this custom flow)
    // Filter: Document Type = Invoice AND Vendor Accrual Account not blank
    SourceTableView = where("Document Type" = const(Invoice));

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
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = All;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field(Status; GetPostedStatusTxt())
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    StyleExpr = StatusStyle;
                }
                field("BVR Posted Inv No."; Rec."BVR Posted Inv No.")
                {
                    ApplicationArea = All;
                }
                field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    var
        StatusStyle: Text;

    trigger OnOpenPage()
    begin
        // Keep list scoped to the custom flow: invoices with accrual accounts filled.
        Rec.SetRange("Document Type", Rec."Document Type"::Invoice);
        //Rec.SetFilter("BVR Vendor Accrual Acc No.", '<>%1', '');
    end;

    local procedure GetPostedStatusTxt(): Text
    begin
        if Rec."BVR Custom Inv Posted" then begin
            StatusStyle := 'Success';
            exit('Posted');
        end;
        StatusStyle := 'Attention';
        exit('Not Posted');
    end;
}
