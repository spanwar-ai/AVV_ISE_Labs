tableextension 50117 "BVR User Setup Ext" extends "User Setup"
{
    fields
    {
        // Identifies AP-team users who may still edit the accrual accounts on a
        // Custom Purchase Receipt after it has been marked "AP Updated".  //AAV.SP
        field(50130; "BVR AP Team"; Boolean)   //AAV.SP
        {
            Caption = 'AP Team';
            DataClassification = CustomerContent;
        }
        // Grants this user the right to post general journal batches - every template type, not just
        // the General template. Enforced by codeunit "BVR GL Posting Guard".
        //
        // An ALLOW flag, not a block flag: an unticked box and a user with no User Setup card at all
        // both mean "not granted". That is the safe default for an authorisation, but it does mean
        // nobody can post a journal until somebody is ticked.   //AAV.SP
        field(50131; "BVR GL Posting Allowed"; Boolean)   //AAV.SP
        {
            Caption = 'GL Posting Allowed';
            DataClassification = CustomerContent;
        }
    }

    // Enforcement of "BVR GL Posting Allowed". The check lives here with the field it reads; only
    // the event subscriber that calls it sits elsewhere, because AL allows [EventSubscriber] in a
    // codeunit and nowhere else (AL0313). See codeunit "BVR Gen Jnl GL Preview".   //AAV.SP
    // A missing User Setup card cannot be read as permission. This is an authorisation check, and the
    // absence of a record is the absence of an authorisation - failing open would make the field
    // pointless for exactly the users nobody has set up yet.   //AAV.SP
    procedure BVRCheckGLPostingAllowed()
    var
        BVRUserSetup: Record "User Setup";
    begin
        if not BVRUserSetup.Get(UserId()) then
            Error(BVRNoUserSetupErr, UserId());
        if not BVRUserSetup."BVR GL Posting Allowed" then
            Error(BVRNotAllowedErr, UserId());
    end;

    // The same test without the error, for greying out a Post action.   //AAV.SP
    procedure BVRIsGLPostingAllowed(): Boolean
    var
        BVRUserSetup: Record "User Setup";
    begin
        if not BVRUserSetup.Get(UserId()) then
            exit(false);
        exit(BVRUserSetup."BVR GL Posting Allowed");
    end;

    var
        BVRNoUserSetupErr: Label 'You cannot post G/L entries. There is no User Setup card for %1 - ask an administrator to create one and tick GL Posting Allowed.', Comment = '%1 = user id';
        BVRNotAllowedErr: Label 'You cannot post G/L entries. GL Posting Allowed is not ticked on the User Setup card for %1.', Comment = '%1 = user id';
}
