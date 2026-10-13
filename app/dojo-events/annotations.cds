// Fiori elements: a dojo team's sessions (List Report + Object Page).
// Replaces the Django dojo admin area's Events and attendance pages.
using DojoAdminService as service from '../../srv/dojo-admin-service';

annotate service.Events with @(
    UI.HeaderInfo      : {
        TypeName       : '{i18n>Session}',
        TypeNamePlural : '{i18n>Sessions}',
        Title          : { Value: name },
        Description    : { Value: venueName }
    },
    UI.SelectionFields : [ status, startTime, audience ],
    UI.LineItem        : [
        { Value: name,      Label: '{i18n>Name}' },
        { Value: startTime, Label: '{i18n>Starts}' },
        { Value: endTime,   Label: '{i18n>Ends}' },
        { Value: places,    Label: '{i18n>Places}' },
        { Value: status,    Label: '{i18n>Status}' },
        { Value: audience,  Label: '{i18n>Audience}' }
    ],
    UI.FieldGroup #Main : { Data: [
        { Value: name,        Label: '{i18n>Name}' },
        { Value: status,      Label: '{i18n>Status}' },
        { Value: startTime,   Label: '{i18n>Starts}' },
        { Value: endTime,     Label: '{i18n>Ends}' },
        { Value: places,      Label: '{i18n>Places}' },
        { Value: audience,    Label: '{i18n>Audience}' },
        { Value: minAge,      Label: '{i18n>MinAge}' },
        { Value: maxAge,      Label: '{i18n>MaxAge}' }
    ]},
    UI.FieldGroup #Venue : { Data: [
        { Value: venueName,              Label: '{i18n>Venue}' },
        { Value: location_latitude,      Label: '{i18n>Latitude}' },
        { Value: location_longitude,     Label: '{i18n>Longitude}' },
        { Value: externalRegistrationUrl, Label: '{i18n>ExternalUrl}' }
    ]},
    UI.Facets          : [
        { $Type: 'UI.ReferenceFacet', ID: 'Main',  Label: '{i18n>General}', Target: '@UI.FieldGroup#Main' },
        { $Type: 'UI.ReferenceFacet', ID: 'Venue', Label: '{i18n>Venue}',   Target: '@UI.FieldGroup#Venue' },
        { $Type: 'UI.ReferenceFacet', ID: 'Description', Label: '{i18n>Description}', Target: '@UI.FieldGroup#Description' },
        { $Type: 'UI.ReferenceFacet', ID: 'Registrations', Label: '{i18n>Registrations}', Target: 'registrations/@UI.LineItem' }
    ],
    UI.FieldGroup #Description : { Data: [ { Value: description, Label: '{i18n>Description}' } ] }
);

annotate service.Events with {
    description @UI.MultiLineText;
    dojo        @UI.Hidden;
};

annotate service.Registrations with @(
    UI.LineItem : [
        { Value: position,        Label: '{i18n>Position}' },
        { Value: ninjaName,       Label: '{i18n>FirstName}' },
        { Value: ninjaFamilyName, Label: '{i18n>FamilyName}' },
        { Value: waitingList,     Label: '{i18n>WaitingList}' },
        { Value: attended,        Label: '{i18n>Attended}' }
    ],
    UI.PresentationVariant : { SortOrder: [ { Property: position } ] }
);
