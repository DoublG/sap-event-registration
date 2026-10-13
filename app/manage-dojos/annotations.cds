// Fiori elements: the organisation's dojos and badges (List Report + Object Page).
// Replaces the Django admin's and the organisation dashboard's dojo pages.
using OrganisationService as service from '../../srv/organisation-service';

annotate service.Dojos with @(
    UI.HeaderInfo      : {
        TypeName       : '{i18n>Dojo}',
        TypeNamePlural : '{i18n>Dojos}',
        Title          : { Value: name },
        Description    : { Value: tagline }
    },
    UI.SelectionFields : [ status, kind ],
    UI.LineItem        : [
        { Value: name,    Label: '{i18n>Name}' },
        { Value: status,  Label: '{i18n>Status}' },
        { Value: kind,    Label: '{i18n>Kind}' },
        { Value: email,   Label: '{i18n>Email}' },
        { Value: minAge,  Label: '{i18n>MinAge}' },
        { Value: maxAge,  Label: '{i18n>MaxAge}' }
    ],
    UI.FieldGroup #Main : { Data: [
        { Value: name,                Label: '{i18n>Name}' },
        { Value: status,              Label: '{i18n>Status}' },
        { Value: kind,                Label: '{i18n>Kind}' },
        { Value: address,             Label: '{i18n>Address}' },
        { Value: scheduleDescription, Label: '{i18n>Schedule}' },
        { Value: email,               Label: '{i18n>Email}' },
        { Value: phone,               Label: '{i18n>Phone}' },
        { Value: minAge,              Label: '{i18n>MinAge}' },
        { Value: maxAge,              Label: '{i18n>MaxAge}' }
    ]},
    UI.FieldGroup #Texts : { Data: [
        { Value: tagline,     Label: '{i18n>Tagline}' },
        { Value: description, Label: '{i18n>Description}' },
        { Value: visitNotes,  Label: '{i18n>VisitNotes}' }
    ]},
    UI.Facets          : [
        { $Type: 'UI.ReferenceFacet', ID: 'Main',  Label: '{i18n>General}', Target: '@UI.FieldGroup#Main' },
        { $Type: 'UI.ReferenceFacet', ID: 'Texts', Label: '{i18n>Texts}',   Target: '@UI.FieldGroup#Texts' }
    ]
);

annotate service.Dojos with {
    description @UI.MultiLineText;
    visitNotes  @UI.MultiLineText;
};

annotate service.Badges with @(
    UI.HeaderInfo : { TypeName: '{i18n>Badge}', TypeNamePlural: '{i18n>Badges}', Title: { Value: name } },
    UI.LineItem   : [
        { Value: name,      Label: '{i18n>Name}' },
        { Value: kind,      Label: '{i18n>Kind}' },
        { Value: threshold, Label: '{i18n>Threshold}' }
    ],
    UI.FieldGroup #Main : { Data: [
        { Value: name,        Label: '{i18n>Name}' },
        { Value: kind,        Label: '{i18n>Kind}' },
        { Value: description, Label: '{i18n>Description}' },
        { Value: criteria,    Label: '{i18n>Criteria}' },
        { Value: threshold,   Label: '{i18n>Threshold}' }
    ]},
    UI.Facets : [ { $Type: 'UI.ReferenceFacet', ID: 'Main', Label: '{i18n>General}', Target: '@UI.FieldGroup#Main' } ]
);
