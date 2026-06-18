// codeunit 70462 "PO→ISE Orchestrator"
// {
//     procedure RunFromPO(var PurchHeader: Record "Purchase Header")
//     var
//         Lines: Record "Purchase Line";
//         IseHdr: Record "ISE Customer Order Header";
//         IseLine: Record "ISE Customer Order Line";
//         LnNo: Integer;
//         OutQty: Decimal;
//     begin
//         // Preconditions
//         PurchHeader.TestField("Document Type", PurchHeader."Document Type"::Order);
//         PurchHeader.TestField(Status, PurchHeader.Status::Released);
//         PurchHeader.TestField("Buy-from Vendor No.");
//         // Create ISE header (Adhoc Receipt)
//         IseHdr.Init();
//         IseHdr.Validate("Order Source", IseHdr."Order Source"::Adhoc);
//         IseHdr.Validate("Order Request Type", IseHdr."Order Request Type"::Receipt);
//         // Populate vendor fields (from separate CO add-on)
//         if IseHdr.FieldNo("Vendor No") <> 0 then begin
//             IseHdr.Validate(IseHdr."Vendor No", PurchHeader."Buy-from Vendor No.");
//             //IseHdr.Validate("Vendor Name", PurchHeader."Buy-from Vendor Name");
//             if IseHdr.FieldNo("Sent From Purchase") <> 0 then IseHdr.Validate("Sent From Purchase", true);
//         end;
//         // Optional: link PO No. if such a field exists on your header
//         if IseHdr.FieldNo("Linked Purchase Order No.") <> 0 then IseHdr.Validate("Linked Purchase Order No.", PurchHeader."No.");
//         IseHdr.Insert(true);
//         // Copy outstanding PO lines
//         Lines.SetRange("Document Type", PurchHeader."Document Type");
//         Lines.SetRange("Document No.", PurchHeader."No.");
//         if not Lines.FindSet()then Error('No lines on Purchase Order %1.', PurchHeader."No.");
//         LnNo:=0;
//         repeat OutQty:=Lines.Quantity - Lines."Quantity Received";
//             if OutQty <= 0 then continue;
//             IseLine.Init();
//             IseLine.Validate("Document No.", IseHdr."No.");
//             LnNo+=10000;
//             IseLine.Validate("Line No.", LnNo);
//             if Lines.Type = Lines.Type::Item then IseLine.Validate(Type, IseLine.Type::Inventory)
//             else
//                 IseLine.Validate(Type, IseLine.Type::NonInventory);
//             IseLine.Validate("No.", Lines."No.");
//             IseLine.Validate(Description, Lines.Description);
//             IseLine.Validate(Quantity, OutQty);
//             IseLine.Validate("Qty. to Post", OutQty);
//             IseLine.Validate("Location Code", Lines."Location Code");
//             if Lines.FieldNo("Bin Code") <> 0 then IseLine.Validate("Bin Code", Lines."Bin Code");
//             //if IseLine.FieldNo("Vendor No.") <> 0 then begin
//             //  IseLine.Validate("Vendor No.", PurchHeader."Buy-from Vendor No.");
//             //IseLine.Validate("Vendor Name", PurchHeader."Buy-from Vendor Name");
//             //end;
//             IseLine.Insert(true);
//         until Lines.Next() = 0;
//         // Guard: ensure at least one line copied
//         if not HasLinesToPost(IseHdr."No.")then begin
//             IseHdr.Delete(true);
//             Error('No outstanding lines to send from PO %1.', PurchHeader."No.");
//         end;
//         // Mark PO as sent and save
//         PurchHeader.Validate("Sent to ISE Receiving", true);
//         PurchHeader.Modify(true);
//         // Open Receiving Card
//         Page.Run(Page::"ISE Receiving Card", IseHdr);
//     end;
//     local procedure HasLinesToPost(DocNo: Code[20]): Boolean var
//         L: Record "ISE Customer Order Line";
//     begin
//         L.SetRange("Document No.", DocNo);
//         L.SetFilter("Qty. to Post", '>0');
//         exit(L.FindFirst());
//     end;
// }
