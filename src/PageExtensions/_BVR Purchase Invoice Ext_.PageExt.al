pageextension 50112 "BVR Purchase Invoice Ext" extends "Purchase Invoice"
{
    // Invoicing side of the standard-PO accrual flow. "Get Receipt Lines (Accrual)" pulls a
    // standard posted accrual receipt onto the invoice as G/L lines posting to the Vendor
    // Accrual account, so standard posting books Dr Vendor Accrual / Cr Vendor.   //AAV
    layout
    {
        addlast(General)
        {
            field("BVR Vendor Accrual Acc No."; Rec."BVR Vendor Accrual Acc No.")   //AAV
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Vendor Accrual (GRNI) account this invoice reverses. Copied from the source receipt by Get Receipt Lines (Accrual).';
            }
            field("BVR Expense Accrual Acc No."; Rec."BVR Expense Accrual Acc No.")   //AAV
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Expense Accrual account booked at receipt. Copied from the source receipt for reference.';
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action("BVR Get Receipt Lines Accrual")                                               //AAV
            {                                                                                    //AAV
                ApplicationArea = All;                                                           //AAV
                Caption = 'Get Receipt Lines (Accrual)';                                         //AAV
                Image = GetLines;                                                                //AAV
                ToolTip = 'Pull the lines of a posted accrual receipt onto this invoice as Vendor Accrual G/L lines. Posting then books Dr Vendor Accrual / Cr Vendor.'; //AAV

                trigger OnAction()                                                               //AAV
                var                                                                              //AAV
                    GetRcpt: Codeunit "BVR Std Get Receipt Lines";                               //AAV
                begin                                                                            //AAV
                    GetRcpt.GetLinesInteractive(Rec);                                            //AAV
                    CurrPage.Update(false);                                                      //AAV
                end;                                                                             //AAV
            }                                                                                    //AAV
        }
        addlast(Category_Process)
        {
            actionref("BVR Get Receipt Lines Accrual_Promoted"; "BVR Get Receipt Lines Accrual") { }   //AAV
        }
    }
}
