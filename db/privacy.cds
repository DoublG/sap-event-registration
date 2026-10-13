// privacy app: erasure and retention records. The field-by-field GDPR
// classification (core/privacy_registry.py) maps to CAP's @PersonalData
// annotations, see db/personal-data.cds.
namespace coderdojo.privacy;

using { cuid } from '@sap/cds/common';
using { coderdojo.accounts.Accounts } from './accounts';

entity ErasureRecords : cuid {
        model       : String(100) @mandatory;
        objectId    : String(36) @mandatory; // a UUID here, an integer pk in Django
        keepVisible : Boolean default false;
        @mandatory reason      : String(20) enum { self; request; retention; };
        requestedBy : Association to Accounts;
        erasedAt    : Timestamp @cds.on.insert: $now;
}

entity RetentionNotices : cuid {
        account       : Association to Accounts @mandatory;
        inactiveSince : Timestamp @mandatory;
        daysBefore    : Integer @mandatory;
        createdAt     : Timestamp @cds.on.insert: $now;
}

annotate RetentionNotices with @assert.unique: { noticePerPeriod: [account, inactiveSince, daysBefore] };
