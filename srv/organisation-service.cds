// The organisation dashboard (/manage/...). Django gives each sidebar
// group ("area") a permission; here each area is a role and @restrict.
using { coderdojo.dojos as d } from '../db/dojos';
using { coderdojo.events as e } from '../db/events';
using { coderdojo.pathways as p } from '../db/pathways';
using { coderdojo.content as c } from '../db/content';
using { coderdojo.applications as ap } from '../db/applications';
using { coderdojo.accounts as a } from '../db/accounts';

@path: '/manage'
@requires: ['organisation-admin', 'reviewer']
service OrganisationService {
    // Public site / ninjas areas: the organisation admin role.
    @restrict: [{ grant: '*', to: 'organisation-admin' }]
    entity Dojos as projection on d.Dojos;
    @restrict: [{ grant: '*', to: 'organisation-admin' }]
    entity Badges as projection on e.Badges;
    @restrict: [{ grant: '*', to: 'organisation-admin' }]
    entity Belts as projection on e.Belts;
    @restrict: [{ grant: '*', to: 'organisation-admin' }]
    entity Pathways as projection on p.Pathways;
    @restrict: [{ grant: '*', to: 'organisation-admin' }]
    entity Promotions as projection on c.Promotions;
    @restrict: [{ grant: '*', to: 'organisation-admin' }]
    entity Sponsors as projection on c.Sponsors;

    // Volunteers area: the reviewer role only (applications.can_review_background_checks).
    @restrict: [{ grant: ['READ', 'UPDATE'], to: 'reviewer' }]
    entity Applications as projection on ap.Applications;
    @restrict: [{ grant: 'READ', to: 'reviewer' }]
    entity BackgroundCheckHistory as projection on ap.BackgroundCheckHistory;
    @restrict: [{ grant: 'READ', to: 'reviewer' }]
    entity Volunteers as projection on a.Accounts {
        ID, firstName, lastName, email, backgroundCheckStatus,
        backgroundCheckSubmittedAt, backgroundCheckExpiresAt
    } where accountType = 'adult';
}

// Fiori elements edits through drafts.
annotate OrganisationService.Dojos with @odata.draft.enabled;
annotate OrganisationService.Badges with @odata.draft.enabled;
