// events app: sessions, registrations, badges and belts, engagement.
namespace coderdojo.events;

using { cuid, managed } from '@sap/cds/common';
using { coderdojo.GeoPoint, coderdojo.ImagePath, coderdojo.Url, coderdojo.HexColour, coderdojo.Translatable, coderdojo.OrganisationContent } from './common';
using { coderdojo.accounts.Accounts, coderdojo.accounts.Ninjas } from './accounts';
using { coderdojo.dojos.Dojos, coderdojo.dojos.DojoMemberships } from './dojos';
using { coderdojo.pathways.Pathways } from './pathways';

/** A dojo's session. */
entity Events : cuid, managed, Translatable {
        name                    : localized String(200) @mandatory;
        dojo                    : Association to Dojos @mandatory;
        status                  : String(10) enum { draft; open; closed; } default 'draft';
        startTime               : Timestamp @mandatory;
        endTime                 : Timestamp @mandatory;
        places                  : Integer @mandatory @assert.range: [0, 10000];
        location                : GeoPoint;
        venueName               : String(200);
        image                   : ImagePath;
        description             : localized LargeString; // markdown
        minAge                  : Integer;
        maxAge                  : Integer;
        audience                : String(10) enum { everyone; girls; } default 'everyone';
        /** Organisation dojos only: sign-up happens elsewhere. */
        externalRegistrationUrl : Url;
        publishedAt             : Timestamp @readonly;
        announcedAt             : Timestamp @readonly;

        team                    : Composition of many EventTeam on team.event = $self;
        pathways                : Composition of many EventPathways on pathways.event = $self;
        registrations           : Association to many Registrations on registrations.event = $self;
        teamAttendance          : Association to many TeamAttendance on teamAttendance.event = $self;

        // Django computes these per query (with_confirmed_count, places_left).
        virtual confirmedCount  : Integer;
        virtual placesLeft      : Integer;
}

entity EventTeam {
    key event      : Association to Events;
    key membership : Association to DojoMemberships;
}

entity EventPathways {
    key event   : Association to Events;
    key pathway : Association to Pathways;
}

/** A ninja's place on a session or its waiting list. Only events.registrations creates these. */
entity Registrations : cuid {
        event       : Association to Events @mandatory;
        ninja       : Association to Ninjas @mandatory;
        waitingList : Boolean @mandatory;
        position    : Integer @mandatory;
        attended    : Boolean; // null = not marked
        createdAt   : Timestamp @cds.on.insert: $now @readonly;
        pathways    : Composition of many RegistrationPathways on pathways.registration = $self;
}

entity RegistrationPathways {
    key registration : Association to Registrations;
    key pathway      : Association to Pathways;
}

entity RegistrationCancellations : cuid {
        ninja         : Association to Ninjas @mandatory;
        event         : Association to Events @mandatory;
        wasWaitlisted : Boolean @mandatory;
        signedUpAt    : Timestamp;
        cancelledAt   : Timestamp @cds.on.insert: $now;
        cancelledBy   : Association to Accounts;
}

entity Belts : cuid, OrganisationContent {
        name         : localized String(100) @mandatory;
        level        : Integer @mandatory; // 1 is the first belt; unique
        colour       : HexColour;
        requirements : localized LargeString;
        icon         : ImagePath;
}

entity Badges : cuid, OrganisationContent {
        name        : localized String(200) @mandatory;
        kind        : String(10) enum { one_off; milestone; } default 'one_off';
        description : localized String(300);
        criteria    : localized String(200);
        threshold   : Integer; // milestone only
        grantsBelt  : Association to Belts;
        icon        : ImagePath;
        /** Which dojos may award a one-off badge; none = any dojo. */
        dojos       : Composition of many BadgeDojos on dojos.badge = $self;
}

entity BadgeDojos {
    key badge : Association to Badges;
    key dojo  : Association to Dojos;
}

entity NinjaBadges : cuid {
        ninja               : Association to Ninjas @mandatory;
        badge               : Association to Badges @mandatory;
        earnedDate          : Date;
        progressCurrent     : Integer;
        progressTotal       : Integer;
        awardedBy           : Association to Accounts;
        awardedAsMembership : Association to DojoMemberships;
        note                : String(300);
}

/** Append-only belt history; the current belt is the highest one. */
entity NinjaBelts : cuid {
        ninja               : Association to Ninjas @mandatory;
        belt                : Association to Belts @mandatory @assert.target; // Django PROTECT
        awardedOn           : Date @mandatory;
        awardedBy           : Association to Accounts;
        awardedAsMembership : Association to DojoMemberships;
        awardedAsRole       : String(20);
        note                : String(300);
}

type EngagementStage : String(20) enum {
    new; regular; occasional; at_risk; lapsed; never_attended; aged_out;
};

/** The nightly engagement snapshot (events/engagement.py). */
entity NinjaEngagement : cuid {
        ninja                : Association to Ninjas @mandatory;
        dojo                 : Association to Dojos; // null = across all dojos
        mainDojo             : Association to Dojos;
        stage                : EngagementStage @mandatory;
        firstAttended        : Date;
        lastAttended         : Date;
        attendedTotal        : Integer default 0;
        attendanceRate       : Double default 0;
        missedInARow         : Integer default 0;
        hasUpcoming          : Boolean default false;
        fromMarkedAttendance : Boolean default false;
        computedOn           : Date @mandatory;
}

entity NinjaEngagementChanges : cuid {
        ninja     : Association to Ninjas @mandatory;
        fromStage : EngagementStage @mandatory;
        toStage   : EngagementStage @mandatory;
        changedOn : Date @mandatory;
}

entity TeamAttendance : cuid {
        event      : Association to Events @mandatory;
        membership : Association to DojoMemberships @mandatory;
        attended   : Boolean;
        markedAt   : Timestamp @cds.on.insert: $now @cds.on.update: $now;
        markedBy   : Association to Accounts;
}

annotate Registrations with @assert.unique: { eventNinja: [event, ninja] };
annotate Belts with @assert.unique: { level: [level] };
annotate NinjaBadges with @assert.unique: { ninjaBadge: [ninja, badge] };
annotate TeamAttendance with @assert.unique: { eventMembership: [event, membership] };
