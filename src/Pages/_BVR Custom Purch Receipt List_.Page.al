// page 50123 "BVR Custom Purch Receipt List"
// {
//     PageType = List;
//     SourceTable = "Purchase Header";
//     Caption = 'Custom Purchase Receipts (POs)';
//     ApplicationArea = All;
//     UsageCategory = Lists;
//     SourceTableView = where("Document Type" = const(Order), "BVR Receive PO" = const(true));
//     CardPageId = "BVR Custom Purch Receipt";
//     Editable = false;
//     InsertAllowed = false;
//     ModifyAllowed = false;
//     DeleteAllowed = false;

//     layout
//     {
//         area(content)
//         {
//             repeater(Gen)
//             {
//                 field("No."; Rec."No.")
//                 {
//                     ApplicationArea = All;
//                 }
//                 field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
//                 {
//                     ApplicationArea = All;
//                 }
//                 field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
//                 {
//                     ApplicationArea = All;
//                 }
//                 field("Posting Date"; Rec."Posting Date")
//                 {
//                     ApplicationArea = All;
//                 }
//                 field("BVR Custom Rcpt Posted"; Rec."BVR Custom Rcpt Posted")
//                 {
//                     ApplicationArea = All;
//                 }
//                 field("BVR Posted Rcpt No."; Rec."BVR Posted Rcpt No.")
//                 {
//                     ApplicationArea = All;
//                 }
//                 field("BVR Receipt Status"; Rec."BVR Receipt Status")
//                 {
//                     ApplicationArea = All;
//                 }
//                 field("Posting No."; Rec."Posting No.")
//                 {
//                     ApplicationArea = All;
//                 }
//             }
//         }
//     }
//     actions
//     {
//         area(processing)
//         {
//             action(Open)
//             {
//                 ApplicationArea = All;
//                 Caption = 'Open';
//                 Image = EditLines;

//                 trigger OnAction()
//                 var
//                     H: Record "Purchase Header";
//                 begin
//                     H.Get(Rec."Document Type", Rec."No.");
//                     Page.Run(Page::"BVR Custom Purch Receipt", H);
//                 end;
//             }
//         }
//     }
// }
