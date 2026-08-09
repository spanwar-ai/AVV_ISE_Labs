pageextension 50112 "BVR Purchase Invoice Ext" extends "Purchase Invoice"
{
    // Invoicing side of the standard-PO accrual flow. "Get Receipt Lines (Accrual)" pulls a
    // standard posted accrual receipt onto the invoice as G/L lines posting to the Vendor
    // Accrual account, so standard posting books Dr Vendor Accrual / Cr Vendor.   //AAV
    layout
    {
        // Already on the page, just hidden by Microsoft. What is typed here ends up as the
        // description on the vendor ledger entry and the G/L entries the invoice posts, so AP wants
        // it in front of them while they enter the invoice, not buried behind Show More.   //AAV.SP
        modify("Posting Description")
        {
            Visible = true;
        }
        addlast(General)
        {
            field("BVR Doc Batch No."; Rec."BVR Doc Batch No.")   //AAV.SP
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the batch this invoice belongs to. Choose an existing Invoice batch or create a new one from the lookup. The batch is posted from the Purchase Invoice Batches page.';
            }
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
        // An invoice that has been put into a batch is posted from the batch, together with the rest
        // of it - so the posting buttons on this page are switched off while a Batch No. is filled
        // in. Clearing the Batch No. brings them back.
        //
        // Preview Posting is deliberately left alone: it posts nothing, and it is the most useful way
        // to check an invoice before its batch goes.   //AAV.SP
        modify(Post)
        {
            Enabled = BVRPostAllowed;
        }
        modify(PostAndPrint)
        {
            Enabled = BVRPostAllowed;
        }
        modify(PostAndNew)
        {
            Enabled = BVRPostAllowed;
        }
        modify(PostBatch)
        {
            Enabled = BVRPostAllowed;
        }
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

    trigger OnAfterGetCurrRecord()
    begin
        BVRPostAllowed := Rec."BVR Doc Batch No." = '';   //AAV.SP
    end;

    var
        BVRPostAllowed: Boolean;   //AAV.SP
}
