page 50230 "BVR Receipt Approval Queue"
{
    PageType = List;
    SourceTable = "Purchase Header";
    Caption = 'Custom Receipt Approval Queue';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "BVR Receipt Approval Card";
    SourceTableView = where("Document Type"=const(Order), "BVR Receive PO"=const(true));

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
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("BVR Receipt Status"; Rec."BVR Receipt Status")   //AAV.SP
                {
                    ApplicationArea = All;
                }
                field("BVR AP Updated"; Rec."BVR AP Updated")
                {
                    ApplicationArea = All;
                }
                field("BVR Sent For Approval"; Rec."BVR Sent For Approval")
                {
                    ApplicationArea = All;
                }
                field("BVR Approved"; Rec."BVR Approved")
                {
                    ApplicationArea = All;
                }
                field("BVR Custom Rcpt Posted"; Rec."BVR Custom Rcpt Posted")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        Rec.SetRange("BVR Sent For Approval", true);
        //Rec.SetRange("BVR Approved", false);
        Rec.SetRange("BVR Custom Rcpt Posted", false);
    end;
}
