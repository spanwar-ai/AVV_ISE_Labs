permissionset 50300 "BVR Custom Receipt"
{
    Assignable = true;
    Permissions = tabledata "Purchase Header"=RM,
        tabledata "Purchase Line"=RIMD,
        tabledata "Purch. Rcpt. Header"=RIMD,
        tabledata "Purch. Rcpt. Line"=RIMD,
        tabledata "BVR PO Line Buffer"=RIMD,
        tabledata "BVR Posting Preview Line"=RIMD,
        codeunit "BVR Get Released PO Lines"=X,
        codeunit "BVR Custom Rcpt Post V2"=X,
        codeunit "BVR Receipt Approval Mgt"=X,
        codeunit "BVR Posting Preview Mgt"=X,
        codeunit "BVR Purch Doc Mgt"=X,
        codeunit "BVR Create Custom Invoice"=X,
        page "BVR Custom Purch Receipt"=X,
        page "BVR Custom Purch Rcpt Lines"=X,
        page "BVR Released PO Lines"=X,
        page "BVR Receipt Approval Queue"=X,
        page "BVR Receipt Approval Card"=X,
        page "BVR Posting Preview"=X,
        page "BVR Custom Purch Invoice"=X,
        page "BVR Custom Purch Inv Lines"=X,
        report "BVR Custom Receipt Report"=X,
        report "BVR Custom Invoice Report"=X;
}
