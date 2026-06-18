// codeunit 70463 "PO Post Guard"
// {
//     [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
//     local procedure OnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var IsHandled: Boolean)
//     begin
//         if PurchaseHeader."Sent to ISE Receiving" then Error('This Purchase Order has been sent to ISE Receiving and cannot be posted.');
//     end;
// }
