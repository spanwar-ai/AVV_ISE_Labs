// pageextension 50335 "BVR Approval Queue Batch" extends "BVR Receipt Approval Queue"
// {
//     actions
//     {
//         addlast(processing)
//         {
//             action("Batch Approve")
//             {
//                 ApplicationArea = All;
//                 Caption = 'Batch Approve';
//                 Image = Approve;
//                 Promoted = true;
//                 PromotedCategory = Process;

//                 trigger OnAction()
//                 var
//                     Sel: Record "Purchase Header";
//                     Mgt: Codeunit "BVR Receipt Approval Mgt";
//                 begin
//                     CurrPage.SetSelectionFilter(Sel);
//                     if Sel.FindSet()then repeat if Sel."BVR Sent For Approval" and (not Sel."BVR Approved") and (not Sel."BVR Custom Rcpt Posted")then Mgt.Approve(Sel);
//                         until Sel.Next() = 0;
//                     CurrPage.Update(false);
//                 end;
//             }
//             action("Batch Post")
//             {
//                 ApplicationArea = All;
//                 Caption = 'Batch Post';
//                 Image = PostBatch;
//                 Promoted = true;
//                 PromotedCategory = Process;

//                 trigger OnAction()
//                 var
//                     Sel: Record "Purchase Header";
//                     PostV2: Codeunit "BVR Custom Rcpt Post V2";
//                 begin
//                     CurrPage.SetSelectionFilter(Sel);
//                     if Sel.FindSet()then repeat if Sel."BVR Approved" and (not Sel."BVR Custom Rcpt Posted")then PostV2.Post(Sel);
//                         until Sel.Next() = 0;
//                     CurrPage.Update(false);
//                 end;
//             }
//         }
//     }
// }
