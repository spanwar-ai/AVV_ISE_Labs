// The ISE Labs check layout for the pre-printed Deluxe SSLM130 stock: remittance stub, check,
// remittance stub down a letter page.
//
// This is an EXTENSION of Microsoft's report 10411 "Check (Stub/Check/Stub)", not a report of our
// own, and that is the whole point. Check printing is not just a layout: it assigns check numbers,
// writes Check Ledger Entries, stamps "Check Printed" on the journal line, handles voided and test
// prints, and copes with a payment that settles more invoices than one stub can hold. All of that is
// Microsoft's, stays Microsoft's, and keeps getting their fixes. We add columns and a layout.
//
// What the extension adds is only what ISE's stub shows and the base report does not expose:
// the vendor's number, and the payment number. Everything else the stub needs - the voucher numbers,
// dates, amounts, discounts and totals - the base report already publishes.
//
// The layout prints ONLY the variable data. The bank logo, routing fraction, MICR line, signature,
// company address on the check face and "VOID AFTER 90 DAYS" are all pre-printed on the stock, so
// printing them again would double-strike them.
//
// To use it: set "Check Report ID" = 10411 on the Bank Account, then pick this layout on the Report
// Layouts page (or make it the default for report 10411). Expect to nudge the geometry once against
// real stock - the constants live at the top of the generator script that builds the .rdl.   //AAV.SP
reportextension 50147 "BVR Check ISE Ext" extends "Check (Stub/Check/Stub)"
{
    dataset
    {
        // On GenJnlLine rather than on the stub loop: these come straight off the journal line, and a
        // column on an outer dataitem is repeated onto every row beneath it, so the stub can still
        // read them.   //AAV.SP
        add(GenJnlLine)
        {
            // "Payment Number" on the stub. The journal line's own Document No. - what the payment run
            // called this payment, as opposed to the check number the bank sees, which the stub prints
            // separately as "Document Number".   //AAV.SP
            column(BVRPaymentNo; "Document No.")
            {
            }
            // "Vendor ID". Which side of the line the payee sits on is not fixed - a payment journal
            // normally puts the vendor on the account and the bank on the balancing account, but the
            // reverse posts just as well - so both sides are published and the layout picks the one
            // that is a vendor. A column cannot branch; an expression in the layout can.
            //
            // The type goes out as its ORDINAL, not as the enum. An enum column reaches the layout as
            // its translated caption, so a layout that tested for "Vendor" would quietly stop matching
            // in any company that is not running English. The number does not move.   //AAV.SP
            column(BVRAccountTypeNo; "Account Type".AsInteger())
            {
            }
            column(BVRAccountNo; "Account No.")
            {
            }
            column(BVRBalAccountTypeNo; "Bal. Account Type".AsInteger())
            {
            }
            column(BVRBalAccountNo; "Bal. Account No.")
            {
            }
            // The check date as mm/dd/yyyy.
            //
            // The base report already publishes a check date, but only as PROSE - "August 7, 2026" -
            // built by its own DateIndicator logic, and a date that is already text cannot be given a
            // different format in the layout. So the date is published again here from the source
            // the base report itself uses: CheckLedgEntry."Check Date" is assigned GenJnlLine's
            // "Posting Date", so this is the same day the check is written for, not an approximation
            // of it.
            //
            // Formatted with an explicit picture rather than Format(Date) so it reads mm/dd/yyyy in
            // every company, whatever the user's regional settings say.   //AAV.SP
            column(BVRCheckDateMDY; Format("Posting Date", 0, '<Month,2>/<Day,2>/<Year4>'))
            {
            }

            // The stub's column headings, as dataset columns rather than as text typed into the
            // layout. This is how Microsoft's own check layouts carry every caption they print, and
            // there are two reasons for it: a heading that lives in the report is translated with the
            // rest of the app, and it is the binding the RDLC renderer is built around - a caption
            // typed straight into a textbox is at the mercy of how the layout is processed on its way
            // to the printer, which is what left this row blank.   //AAV.SP
            column(BVRVendorIdCaption; BVRVendorIdCaptionLbl)
            {
            }
            column(BVRNameCaption; BVRNameCaptionLbl)
            {
            }
            column(BVRPaymentNoCaption; BVRPaymentNoCaptionLbl)
            {
            }
            column(BVRCheckDateCaption; BVRCheckDateCaptionLbl)
            {
            }
            column(BVRDocumentNoCaption; BVRDocumentNoCaptionLbl)
            {
            }
            column(BVRVoucherNoCaption; BVRVoucherNoCaptionLbl)
            {
            }
            column(BVRDateCaption; BVRDateCaptionLbl)
            {
            }
            column(BVRAmountCaption; BVRAmountCaptionLbl)
            {
            }
            column(BVRAmountPaidCaption; BVRAmountPaidCaptionLbl)
            {
            }
            column(BVRDiscountCaption; BVRDiscountCaptionLbl)
            {
            }
            column(BVRNetAmountPaidCaption; BVRNetAmountPaidCaptionLbl)
            {
            }
        }
    }

    rendering
    {
        layout("BVRCheckISE")
        {
            Type = RDLC;
            LayoutFile = './ReportLayouts/BVRCheckISE.rdl';
            Caption = 'Check (ISE Labs - Stub/Check/Stub)';
            Summary = 'ISE Labs check on pre-printed Deluxe SSLM130 stock: remittance stub, check, remittance stub. Prints variable data only - the bank details, MICR line and signature are pre-printed.';
        }
    }

    var
        // Worded exactly as the ISE stock prints them.   //AAV.SP
        BVRVendorIdCaptionLbl: Label 'Vendor ID';
        BVRNameCaptionLbl: Label 'Name';
        BVRPaymentNoCaptionLbl: Label 'Payment Number';
        BVRCheckDateCaptionLbl: Label 'Check Date';
        BVRDocumentNoCaptionLbl: Label 'Document Number';
        BVRVoucherNoCaptionLbl: Label 'Our Voucher Number';
        BVRDateCaptionLbl: Label 'Date';
        BVRAmountCaptionLbl: Label 'Amount';
        BVRAmountPaidCaptionLbl: Label 'Amount Paid';
        BVRDiscountCaptionLbl: Label 'Discount';
        BVRNetAmountPaidCaptionLbl: Label 'Net Amount Paid';
}
