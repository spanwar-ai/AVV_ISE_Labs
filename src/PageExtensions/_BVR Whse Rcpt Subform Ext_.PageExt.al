pageextension 50138 "BVR Whse Rcpt Subform Ext" extends "Whse. Receipt Subform"
{

    actions
    {
        addafter("Source &Document Line")
        {
            action("BVR Show Source Document")   //AAV.SP
            {
                ApplicationArea = Warehouse;
                Caption = 'Show Source Document';
                Image = Document;
                ToolTip = 'Open the source document (Purchase Order, Transfer Order or Sales Return Order) that this Warehouse Receipt line was created from.';

                trigger OnAction()
                begin
                    ShowSourceDocumentCard();
                end;
            }

        }
        modify("&Bin Contents List")
        {
            ApplicationArea = Warehouse;
            visible = false;
        }
        modify("Source Document Attached Lines")
        {
            ApplicationArea = Warehouse;
            visible = false;
        }
        modify("Item Availability by")
        {
            visible = false;
        }

    }

    local procedure ShowSourceDocumentCard()
    var
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        SalesHeader: Record "Sales Header";
        WMSMgt: Codeunit "WMS Management";
    begin
        if Rec."Source No." = '' then
            exit;
        case Rec."Source Document" of
            Rec."Source Document"::"Purchase Order":
                begin
                    PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Rec."Source No.");
                    Page.Run(Page::"Purchase Order", PurchaseHeader);
                end;
            Rec."Source Document"::"Inbound Transfer":
                begin
                    TransferHeader.Get(Rec."Source No.");
                    Page.Run(Page::"Transfer Order", TransferHeader);
                end;
            Rec."Source Document"::"Sales Return Order":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::"Return Order", Rec."Source No.");
                    Page.Run(Page::"Sales Return Order", SalesHeader);
                end;
            else
                WMSMgt.ShowSourceDocLine(
                    Rec."Source Type", Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.", 0);
        end;
    end;
}
