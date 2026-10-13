// What anyone can read: Django's public pages (homepage, dojo finder, events,
// pathways). Django renders HTML; CAP serves OData, so the pages themselves
// become a Fiori elements app or a separate front end (MAPPING.md).
using { coderdojo.dojos as d } from '../db/dojos';
using { coderdojo.events as e } from '../db/events';
using { coderdojo.pathways as p } from '../db/pathways';
using { coderdojo.content as c } from '../db/content';

@path: '/public'
@readonly
service PublicService {
    /** Dojo.objects.public(): active, never an organisation dojo. */
    entity Dojos as select from d.Dojos {
        ID, name, address, location, tagline, description, scheduleDescription,
        minAge, maxAge, email, phone, icon, languages, municipality, events
    } where status = 'active' and kind = 'dojo';

    /** Event.objects.visible(): open or closed sessions of active dojos. */
    entity Events as select from e.Events {
        *, dojo.name as dojoName
    } excluding { team, teamAttendance, registrations }
      where status != 'draft' and dojo.status = 'active';

    entity Pathways     as projection on p.Pathways;
    entity Skills       as projection on p.Skills;
    entity FAQs         as projection on c.FAQs;
    entity Testimonials as projection on c.Testimonials;
    entity Sponsors     as projection on c.Sponsors where isPublic = true;
    entity Promotions   as projection on c.Promotions;
    entity Belts        as projection on e.Belts;
    entity Badges       as projection on e.Badges excluding { dojos };
}
