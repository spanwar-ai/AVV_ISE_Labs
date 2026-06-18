pageextension 50111 "BVR Purchase Order Ext" extends "Purchase Order"
{
    layout
    {
        addlast(General)
        {
            field("BVR Receive PO"; Rec."BVR Receive PO")
            {
                ApplicationArea = All;
                ToolTip = 'Mark this Purchase Order to be processed through the Custom Purchase Receipt page.';
            }
        //field("BVR Vendor Accrual Acc No."; Rec."BVR Vendor Accrual Acc No.")
        //{
        //  ApplicationArea = All;
        //ToolTip = 'G/L account used as Vendor Accrual (liability) during custom receipt and invoice reversal.';
        //}
        //field("BVR Expense Accrual Acc No."; Rec."BVR Expense Accrual Acc No.")
        //{
        //  ApplicationArea = All;
        //ToolTip = 'G/L account used as Expense (accrual/expense) during custom receipt and invoice variance.';
        //}
        }
    }
/* actions
    {
        addlast(Processing)
        {
            action("Send to Custom Receipt")
            {
                ApplicationArea = All;
                Caption = 'Send to Custom Receipt';
                Image = SendTo;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PurchHdr: Record "Purchase Header";
                begin
                    Rec.TestField("Document Type", Rec."Document Type"::Order);
                    Rec.TestField("Buy-from Vendor No.");
                    //Rec.TestField("BVR Vendor Accrual Acc No.");
                    //Rec.TestField("BVR Expense Accrual Acc No.");
                    rec.TestField(Status, rec.Status::Released);
                    Rec."BVR Receive PO" := true;
                    Rec.Modify(true);

                    PurchHdr.Get(Rec."Document Type", Rec."No.");
                    Page.Run(Page::"BVR Custom Purch Receipt", PurchHdr);
                end;
            }
        }
    } */
}
