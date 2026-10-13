// Fiori elements: the reviewers' worklist of mentor and champion applications.
// Replaces the organisation dashboard's Volunteers pages (DATA_MODEL.md §21).
using OrganisationService as service from '../../srv/organisation-service';

annotate service.Applications with @(
    UI.HeaderInfo      : {
        TypeName       : '{i18n>Application}',
        TypeNamePlural : '{i18n>Applications}',
        Title          : { Value: kind },
        Description    : { Value: account.email }
    },
    UI.SelectionFields : [ status, kind ],
    UI.LineItem        : [
        { Value: submittedAt,   Label: '{i18n>Submitted}' },
        { Value: kind,          Label: '{i18n>Kind}' },
        { Value: account.email, Label: '{i18n>Email}' },
        { Value: area,          Label: '{i18n>Area}' },
        { Value: status,        Label: '{i18n>Status}' }
    ],
    UI.FieldGroup #Main : { Data: [
        { Value: kind,                   Label: '{i18n>Kind}' },
        { Value: status,                 Label: '{i18n>Status}' },
        { Value: submittedAt,            Label: '{i18n>Submitted}' },
        { Value: area,                   Label: '{i18n>Area}' },
        { Value: preferredSchedule,      Label: '{i18n>Schedule}' },
        { Value: proposedVenue,          Label: '{i18n>Venue}' },
        { Value: message,                Label: '{i18n>Message}' },
        { Value: backgroundCheckConsent, Label: '{i18n>CheckConsent}' }
    ]},
    UI.Facets : [ { $Type: 'UI.ReferenceFacet', ID: 'Main', Label: '{i18n>General}', Target: '@UI.FieldGroup#Main' } ],
    UI.PresentationVariant : { SortOrder: [ { Property: submittedAt, Descending: true } ] }
);
