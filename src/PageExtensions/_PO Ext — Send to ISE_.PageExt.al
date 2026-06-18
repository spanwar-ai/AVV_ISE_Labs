// pageextension 70461 "PO Ext — Send to ISE" extends "Purchase Order"
// {
//     actions
//     {
//         addlast(Processing)
//         {
//             action(SendToISEReceiving)
//             {
//                 ApplicationArea = All;
//                 Caption = 'Send to ISE Receiving';
//                 Image = SendTo;
//                 Promoted = true;
//                 PromotedCategory = Process;

//                 trigger OnAction()
//                 var
//                     Orchestrator: Codeunit "PO→ISE Orchestrator";
//                 begin
//                     Orchestrator.RunFromPO(Rec);
//                 end;
//             }
//         }
//     }
// }
