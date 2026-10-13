// dojos app: the dojos and their teams.
namespace coderdojo.dojos;

using { cuid, managed } from '@sap/cds/common';
using { coderdojo.GeoPoint, coderdojo.Email, coderdojo.Phone, coderdojo.ImagePath, coderdojo.Translatable } from './common';
using { coderdojo.geo.Municipalities, coderdojo.geo.AdministrativeBoundaries } from './geo';
using { coderdojo.accounts.Accounts } from './accounts';
using { coderdojo.pathways.Pathways } from './pathways';
using { coderdojo.events.Events } from './events';

/** Lifecycle: draft -> active <-> dormant -> archived -> draft (dojos/team.py). */
type DojoStatus : String(10) enum { draft; active; dormant; archived; };

entity Dojos : cuid, managed, Translatable {
        name                : String(200) @mandatory;
        municipality        : Association to Municipalities;
        province            : Association to AdministrativeBoundaries;
        address             : String(200);
        location            : GeoPoint;
        status              : DojoStatus default 'draft';
        kind                : String(12) enum { dojo; organisation; } default 'dojo';
        icon                : ImagePath;
        tagline             : localized LargeString;
        description         : localized LargeString;
        scheduleDescription : localized String(200);
        minAge              : Integer;
        maxAge              : Integer;
        email               : Email;
        phone               : Phone;
        visitNotes          : localized LargeString;
        /** Ordered, first = main language; also the languages its sessions are given in. */
        languages           : array of String(10);

        // Django ManyToManyField(Pathway): an explicit link entity in CDS.
        pathways            : Composition of many DojoPathways on pathways.dojo = $self;
        memberships         : Composition of many DojoMemberships on memberships.dojo = $self;
        events              : Association to many Events on events.dojo = $self;
}

entity DojoPathways {
    key dojo    : Association to Dojos;
    key pathway : Association to Pathways;
}

/**
 * One account's place on one dojo's team. Leaving goes dormant, never
 * deleted, because event teams point at memberships.
 */
entity DojoMemberships : cuid {
        dojo        : Association to Dojos @mandatory;
        user        : Association to Accounts @mandatory;
        @mandatory role        : String(20) enum { champion; mentor; youth_mentor; };
        status      : String(10) enum { requested; active; dormant; } default 'active';
        requestedBy : Association to Accounts;
        decidedBy   : Association to Accounts;
        promotedBy  : Association to Accounts;
        joinedAt    : Timestamp;
        leftAt      : Timestamp;
        createdAt   : Timestamp @cds.on.insert: $now;
}

annotate DojoMemberships with @assert.unique: { membershipPerDojo: [dojo, user] };
