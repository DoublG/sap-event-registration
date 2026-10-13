// campaigns app: segments, campaigns and journeys on top of the mail engine.
namespace coderdojo.campaigns;

using { cuid, managed } from '@sap/cds/common';
using { coderdojo.MailCategory, coderdojo.Translatable } from './common';
using { coderdojo.accounts.Accounts } from './accounts';
using { coderdojo.dojos.Dojos } from './dojos';
using { coderdojo.mailing.EmailMessages } from './mailing';

entity Segments : cuid, managed {
        name        : String(200) @mandatory;
        description : LargeString;
        isActive    : Boolean default true;
        groups      : Composition of many SegmentGroups on groups.segment = $self;
}

/** A tree of AND/OR groups: a self-association, the same as Django's. */
entity SegmentGroups : cuid {
        segment  : Association to Segments @mandatory;
        parent   : Association to SegmentGroups;
        children : Composition of many SegmentGroups on children.parent = $self;
        operator : String(3) enum { and; or; } default 'and';
        scope    : String(5) enum { user; ninja; } default 'user';
        rules    : Composition of many SegmentRules on rules.group = $self;
}

entity SegmentRules : cuid {
        group     : Association to SegmentGroups @mandatory;
        attribute : String(100) @mandatory;
        operator  : String(50) @mandatory;
        value     : LargeString @mandatory; // Django: JSONField
}

entity Campaigns : cuid, Translatable {
        segment         : Association to Segments;
        segmentSnapshot : LargeString;  // JSON
        dojo            : Association to Dojos; // a dojo's own mailing
        audience        : String(30);
        audienceParams  : LargeString;  // JSON
        subject         : localized String(150);
        message         : localized LargeString;
        createdBy       : Association to Accounts;
        name            : String(200) @mandatory;
        category        : MailCategory default 'newsletter';
        templateKey     : String(100);
        context         : LargeString;  // JSON
        status          : String(10) enum { draft; queued; sending; completed; cancelled; } default 'draft';
        createdAt       : Timestamp @cds.on.insert: $now;
        scheduledAt     : Timestamp;
        launchedAt      : Timestamp @readonly;
        launchedBy      : Association to Accounts;
        queuedAt        : Timestamp;
        queuedUpTo      : Integer64;
}

entity Journeys : cuid {
        name         : String(200) @mandatory;
        segment      : Association to Segments;
        category     : MailCategory default 'dojo_news';
        templateKey  : String(100) @mandatory;
        context      : LargeString; // JSON
        cooldownDays : Integer;
        isActive     : Boolean default false;
        activatedAt  : Timestamp @readonly;
        createdAt    : Timestamp @cds.on.insert: $now;
        deliveries   : Composition of many JourneyDeliveries on deliveries.journey = $self;
}

entity JourneyDeliveries : cuid {
        journey   : Association to Journeys @mandatory;
        user      : Association to Accounts @mandatory;
        email     : Association to EmailMessages;
        createdAt : Timestamp @cds.on.insert: $now;
}
