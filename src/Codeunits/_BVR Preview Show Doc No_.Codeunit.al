codeunit 50152 "BVR Preview Show Doc No"
{
    // Makes BC's posting preview keep the real Document No. on the entries it captures.
    //
    // By default codeunit 20 "Posting Preview Event Handler" overwrites "Document No." with '***' on
    // every entry it captures (see its DocumentMaskTok / ShowDocNo). That is fine for the preview
    // PAGE, which shows one document at a time, but it makes the entries impossible to attribute
    // back to the journal line that produced them - which is exactly what the "General Journal -
    // Test" report needs in order to list entries document by document.
    //
    // Codeunit 20 exposes SetShowDocumentNo() for this, and codeunit 19 raises
    // OnAfterBindSubscription with the handler instance right before the simulated posting starts.
    //
    // EventSubscriberInstance = Manual on purpose: bound only for the duration of OUR preview (see
    // "BVR Gen Jnl GL Preview"). A static subscriber would change what every posting preview in the
    // system displays.   //AAV.SP
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnAfterBindSubscription', '', false, false)]
    local procedure ShowDocumentNoOnAfterBindSubscription(var PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
        FailureReason := '';
        PostingPreviewEventHandler.SetShowDocumentNo(true);
    end;

    // Why the failure reason has to be picked up here: codeunit 19 runs the simulated posting in a
    // trapped call and then ends its own OnRun with Error(''), so by the time control returns to the
    // caller the real error text is gone. OnAfterUnbindSubscription is raised immediately after that
    // trapped call, which is the last moment it can still be read.
    //
    // On a SUCCESSFUL preview this is the literal text 'Preview mode.' - the error codeunit 19 uses
    // to roll the simulation back - so it is only ever reported when IsSuccess() is false.   //AAV.SP
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnAfterUnbindSubscription', '', false, false)]
    local procedure CaptureReasonOnAfterUnbindSubscription()
    begin
        FailureReason := GetLastErrorText();
    end;

    procedure GetFailureReason(): Text
    begin
        exit(FailureReason);
    end;

    var
        FailureReason: Text;
}
