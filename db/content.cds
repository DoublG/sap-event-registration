// content app: FAQs, testimonials, dojo updates, the organisation's team,
// promoted events and sponsors.
namespace coderdojo.content;

using { cuid, managed } from '@sap/cds/common';
using { coderdojo.Email, coderdojo.Url, coderdojo.ImagePath, coderdojo.Translatable, coderdojo.OrganisationContent, coderdojo.ScopedContent } from './common';
using { coderdojo.accounts.Accounts } from './accounts';
using { coderdojo.dojos.Dojos } from './dojos';
using { coderdojo.events.Events } from './events';
using { coderdojo.pathways.Pathways } from './pathways';

/** Global when dojo, event and pathway are all empty. */
entity FAQs : cuid, ScopedContent {
        dojo     : Association to Dojos;
        event    : Association to Events;
        pathway  : Association to Pathways;
        question : localized String(300) @mandatory;
        answer   : localized LargeString @mandatory;
        order    : Integer default 0;
}

entity Testimonials : cuid, ScopedContent {
        dojo   : Association to Dojos;
        quote  : localized LargeString @mandatory;
        author : String(200) @mandatory;
        role   : localized String(200);
}

/** A dojo's update ("Announcement"). */
entity Announcements : cuid, Translatable {
        dojo : Association to Dojos @mandatory;
        date : Date @mandatory;
        text : localized LargeString @mandatory;
}

/** The organisation's display-only team listing (not access). */
entity OrganisationTeamMembers : cuid, OrganisationContent {
        name       : String(200) @mandatory;
        position   : localized String(200) @mandatory;
        email      : Email;
        bio        : localized LargeString;
        photo      : ImagePath;
        focusAreas : localized String(300);
        joinedDate : Date;
        order      : Integer default 0;
        isPublic   : Boolean default true;
        account    : Association to Accounts;
}

entity Promotions : cuid, OrganisationContent {
        event     : Association to Events @mandatory;
        @mandatory placement : String(20) enum {
            homepage_hero; event_list_top; upcoming_first; dojo_finder_banner;
        };
        rank      : Integer default 0;
        startsAt  : Timestamp @cds.on.insert: $now;
        endsAt    : Timestamp;
        title     : localized String(200);
        image     : ImagePath;
        text      : localized String(300);
        createdAt : Timestamp @cds.on.insert: $now;
}

entity Sponsors : cuid {
        name     : String(200) @mandatory;
        url      : Url;
        logo     : ImagePath;
        order    : Integer default 0;
        isPublic : Boolean default true;
}
