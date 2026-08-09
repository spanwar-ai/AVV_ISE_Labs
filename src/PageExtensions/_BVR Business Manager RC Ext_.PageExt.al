pageextension 50146 "BVR Business Manager RC Ext" extends "Business Manager Role Center"
{
    // Puts the batch tiles on the Business Manager Role Center, among the other activity cues rather
    // than at the bottom under the charts - a manager looks at this strip first.
    //
    // Anchored to ApprovalsActivities, a stable Microsoft control name, rather than to one of the
    // generated Control<n> names on the same page, which are not safe to build on.   //AAV.SP
    layout
    {
        addafter(ApprovalsActivities)
        {
            part(BVRBatchActivities; "BVR Batch Activities")
            {
                ApplicationArea = All;
                Caption = 'Document Batches';
            }
        }
    }
}
