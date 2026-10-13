// The family's own pages (/account/...): their children, their places.
// Django scopes every query to request.user and 404s on anything else;
// CAP does the same declaratively with @restrict ... where.
using { coderdojo.accounts as a } from '../db/accounts';
using { coderdojo.events as e } from '../db/events';

@path: '/family'
@requires: 'family'
service FamilyService {
    /** Ninja.objects.of_guardian(user). */
    @restrict: [{ grant: ['READ', 'UPDATE'], where: 'exists guardianships[guardian.ID = $user.account]' }]
    entity MyNinjas as projection on a.Ninjas excluding { account };

    @restrict: [{ grant: 'READ', where: 'exists ninja.guardianships[guardian.ID = $user.account]' }]
    @readonly
    entity MyRegistrations as projection on e.Registrations;

    @readonly
    entity Events as projection on e.Events excluding { team, teamAttendance, registrations }
        where status = 'open';

    /**
     * events.registrations.sign_up: locks the session, gives each child a
     * place or the next waiting-list position. Raises the same errors.
     */
    action signUp(event : UUID, ninjas : many UUID) returns many MyRegistrations;

    /** events.registrations.cancel: frees the place and moves the first child on the waiting list up. */
    action cancel(registration : UUID) returns Boolean;

    // Django queues the booking mails (mailing.automated) in the same
    // transaction; CAP emits events, delivered through the outbox after commit.
    event booked           { registration : UUID; waitingList : Boolean; }
    event waitlistPromoted { registration : UUID; }
}
