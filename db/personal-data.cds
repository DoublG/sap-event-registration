// GDPR classification. Django keeps it in a registry (core/privacy_registry.py,
// each app's privacy.py) that drives the art. 30 register, the data export,
// erasure and the audit log's masking. CAP's equivalent is the @PersonalData
// vocabulary, which @cap-js/audit-logging reads to log changes to personal
// data and reads of sensitive data automatically. This file shows the core
// entities; the rest of the registry still has to be translated (MAPPING.md).
using { coderdojo.accounts as a } from './accounts';
using { coderdojo.events as e } from './events';
using { coderdojo.applications as ap } from './applications';
using { coderdojo.mailing as m } from './mailing';

annotate a.Accounts with @PersonalData: { DataSubjectRole: 'Account', EntitySemantics: 'DataSubject' } {
    ID                         @PersonalData.FieldSemantics: 'DataSubjectID';
    email                      @PersonalData.IsPotentiallyPersonal;
    firstName                  @PersonalData.IsPotentiallyPersonal;
    lastName                   @PersonalData.IsPotentiallyPersonal;
    phone                      @PersonalData.IsPotentiallyPersonal;
    postalCode                 @PersonalData.IsPotentiallyPersonal;
    bio                        @PersonalData.IsPotentiallyPersonal;
    photo                      @PersonalData.IsPotentiallyPersonal;
    backgroundCheckStatus      @PersonalData.IsPotentiallySensitive; // criminal records, art. 10
    backgroundCheckDocument    @PersonalData.IsPotentiallySensitive;
    backgroundCheckExpiresAt   @PersonalData.IsPotentiallySensitive;
};

annotate a.Ninjas with @PersonalData: { DataSubjectRole: 'Child', EntitySemantics: 'DataSubject' } {
    ID             @PersonalData.FieldSemantics: 'DataSubjectID';
    name           @PersonalData.IsPotentiallyPersonal;
    familyName     @PersonalData.IsPotentiallyPersonal;
    dateOfBirth    @PersonalData.IsPotentiallyPersonal;
    gender         @PersonalData.IsPotentiallyPersonal;
    photo          @PersonalData.IsPotentiallyPersonal;
};

annotate a.Guardianships with @PersonalData: { DataSubjectRole: 'Child', EntitySemantics: 'Other' } {
    ninja @PersonalData.FieldSemantics: 'DataSubjectID';
};

annotate e.Registrations with @PersonalData: { DataSubjectRole: 'Child', EntitySemantics: 'Other' } {
    ninja    @PersonalData.FieldSemantics: 'DataSubjectID';
    attended @PersonalData.IsPotentiallyPersonal;
};

annotate ap.BackgroundCheckHistory with @PersonalData: { DataSubjectRole: 'Account', EntitySemantics: 'Other' } {
    account  @PersonalData.FieldSemantics: 'DataSubjectID';
    decision @PersonalData.IsPotentiallySensitive;
    note     @PersonalData.IsPotentiallySensitive;
};

annotate m.EmailMessages with @PersonalData: { DataSubjectRole: 'Account', EntitySemantics: 'Other' } {
    user      @PersonalData.FieldSemantics: 'DataSubjectID';
    recipient @PersonalData.IsPotentiallyPersonal;
    subject   @PersonalData.IsPotentiallyPersonal;
    body      @PersonalData.IsPotentiallyPersonal;
};
