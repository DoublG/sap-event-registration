// A dojo's admin area (/dojos/<id>/...): only for an active champion or
// mentor of that dojo (dojos.access). The valid background check that
// Django also requires is checked in the handler.
using { coderdojo.dojos as d } from '../db/dojos';
using { coderdojo.events as e } from '../db/events';

@path: '/dojo-admin'
@requires: 'dojo-team'
service DojoAdminService {
    @restrict: [{ grant: ['READ', 'UPDATE'],
                  where: 'exists memberships[user.ID = $user.account and status = ''active'' and role != ''youth_mentor'']' }]
    entity Dojos as projection on d.Dojos;

    @restrict: [{ grant: '*',
                  where: 'exists dojo.memberships[user.ID = $user.account and status = ''active'' and role != ''youth_mentor'']' }]
    entity Events as projection on e.Events;

    @restrict: [{ grant: ['READ', 'UPDATE'],
                  where: 'exists event.dojo.memberships[user.ID = $user.account and status = ''active'' and role != ''youth_mentor'']' }]
    entity Registrations as projection on e.Registrations {
        *, ninja.name as ninjaName, ninja.familyName as ninjaFamilyName
    };
}

// Fiori elements edits through drafts.
annotate DojoAdminService.Events with @odata.draft.enabled;
