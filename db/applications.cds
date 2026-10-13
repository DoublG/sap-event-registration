// applications app: becoming a mentor or champion, and the background-check history.
namespace coderdojo.applications;

using { cuid } from '@sap/cds/common';
using { coderdojo.accounts.Accounts } from './accounts';
using { coderdojo.dojos.Dojos } from './dojos';

entity Applications : cuid {
        account                 : Association to Accounts @mandatory;
        @mandatory kind                    : String(10) enum { mentor; champion; };
        status                  : String(10) enum { pending; approved; rejected; } default 'pending';
        submittedAt             : Timestamp @cds.on.insert: $now;
        decidedBy               : Association to Accounts;
        decidedAt               : Timestamp;
        dojo                    : Association to Dojos; // a mentor applying to a specific dojo
        mentorRole              : String(20) enum { volunteer_mentor; other; };
        area                    : String(200);
        preferredSchedule       : String(200);
        proposedVenue           : String(200);
        message                 : LargeString;
        consent                 : Boolean default false;
        backgroundCheckConsent  : Boolean default false;
}

/** Append-only: the decision is kept, the document is deleted (GDPR art. 10). */
entity BackgroundCheckHistory : cuid {
        account     : Association to Accounts @mandatory;
        @mandatory decision    : String(10) enum { validated; rejected; };
        reviewedBy  : Association to Accounts;
        reviewedAt  : Timestamp @mandatory;
        requestedAt : Timestamp;
        submittedAt : Timestamp;
        expiresAt   : Timestamp;
        note        : LargeString;
}
