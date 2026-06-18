codeunit 50150 "BVR Get Released PO Lines"
{
    procedure GetIntoCustomReceipt(var RcptHdr: Record "Purchase Header")
    var
        Buf: Record "BVR PO Line Buffer" temporary;
        SrcHdr: Record "Purchase Header";
        SrcLine: Record "Purchase Line";
        Existing: Record "Purchase Line";
        NewLine: Record "Purchase Line";
        NextLineNo: Integer;
        RemQty: Decimal;
        LocFilter: Code[10];
    begin
        RcptHdr.TestField("Document Type", RcptHdr."Document Type"::Order);
        RcptHdr.TestField("BVR Receive PO", true);
        RcptHdr.TestField("Buy-from Vendor No.");
        LocFilter:=RcptHdr."Location Code";
        SrcHdr.Reset();
        SrcHdr.SetRange("Document Type", SrcHdr."Document Type"::Order);
        SrcHdr.SetRange("Buy-from Vendor No.", RcptHdr."Buy-from Vendor No.");
        SrcHdr.SetRange(Status, SrcHdr.Status::Released);
        //SrcHdr.SetRange("BVR Receive PO", false); // only standard POs
        if SrcHdr.FindSet()then repeat SrcLine.Reset();
                SrcLine.SetRange("Document Type", SrcLine."Document Type"::Order);
                SrcLine.SetRange("Document No.", SrcHdr."No.");
                SrcLine.SetFilter(Type, '%1|%2', SrcLine.Type::Item, SrcLine.Type::"G/L Account");
                SrcLine.SetFilter("Outstanding Quantity", '<>%1', 0);
                if LocFilter <> '' then SrcLine.SetRange("Location Code", LocFilter);
                if SrcLine.FindSet()then repeat RemQty:=SrcLine.Quantity - SrcLine."Quantity Received";
                        if RemQty <= 0 then continue;
                        Existing.Reset();
                        Existing.SetRange("Document Type", RcptHdr."Document Type");
                        Existing.SetRange("Document No.", RcptHdr."No.");
                        Existing.SetRange("BVR Source PO No.", SrcHdr."No.");
                        Existing.SetRange("BVR Source PO Line No.", SrcLine."Line No.");
                        if Existing.FindFirst()then continue;
                        Buf.Init();
                        Buf."PO No.":=SrcHdr."No.";
                        Buf."PO Line No.":=SrcLine."Line No.";
                        Buf.Type:=SrcLine.Type;
                        Buf."No.":=SrcLine."No.";
                        Buf.Description:=SrcLine.Description;
                        Buf."Location Code":=SrcLine."Location Code";
                        Buf.Quantity:=RemQty;
                        //Buf."Quantity Received" := SrcLine."Quantity Received";
                        Buf."Remaining Quantity":=RemQty;
                        Buf."Direct Unit Cost":=SrcLine."Direct Unit Cost";
                        Buf."Dimension Set ID":=SrcLine."Dimension Set ID";
                        Buf.Insert();
                    until SrcLine.Next() = 0;
            until SrcHdr.Next() = 0;
        if Buf.IsEmpty()then Error('No released PO lines found with remaining quantity for the selected vendor/location.');
        Page.RunModal(Page::"BVR Released PO Lines", Buf);
        Existing.Reset();
        Existing.SetRange("Document Type", RcptHdr."Document Type");
        Existing.SetRange("Document No.", RcptHdr."No.");
        if Existing.FindLast()then NextLineNo:=Existing."Line No." + 10000
        else
            NextLineNo:=10000;
        Buf.Reset();
        Buf.SetRange("Select", true);
        if Buf.FindSet()then repeat NewLine.Init();
                NewLine."Document Type":=RcptHdr."Document Type";
                NewLine."Document No.":=RcptHdr."No.";
                NewLine."Line No.":=NextLineNo;
                NextLineNo+=10000;
                NewLine.Type:=Buf.Type;
                NewLine.Validate("No.", Buf."No.");
                NewLine.Description:=Buf.Description;
                NewLine.Validate("Location Code", Buf."Location Code");
                // Quantity is PO ordered quantity (non-editable on UI)
                NewLine.Validate(Quantity, Buf.Quantity);
                NewLine."Qty. to Receive":=0; // user enters
                NewLine.validate("Direct Unit Cost", Buf."Direct Unit Cost");
                NewLine."BVR Source PO No.":=Buf."PO No.";
                NewLine."BVR Source PO Line No.":=Buf."PO Line No.";
                NewLine."BVR Source PO Qty":=Buf.Quantity;
                NewLine."BVR Remaining Qty":=Buf."Remaining Quantity";
                //NewLine.validate("Unit Cost", Buf."Direct Unit Cost");
                NewLine."Dimension Set ID":=Buf."Dimension Set ID";
                NewLine.Insert(true);
            until Buf.Next() = 0;
    end;
}
