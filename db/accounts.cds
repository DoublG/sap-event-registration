// accounts app: every login, children, guardianship, organisation roles.
namespace coderdojo.accounts;

using { cuid, managed } from '@sap/cds/common';
using {
    coderdojo.Email, coderdojo.Phone, coderdojo.PostalCode, coderdojo.ImagePath,
    coderdojo.LanguageCode, coderdojo.TokenHash
} from './common';
using { coderdojo.dojos.Dojos, coderdojo.dojos.DojoMemberships } from './dojos';
using { coderdojo.events.Registrations, coderdojo.events.NinjaBadges, coderdojo.events.NinjaBelts } from './events';

/**
 * Django: accounts.User (AbstractUser). In CAP the identity provider (SAP
 * Cloud Identity Services / XSUAA) owns logins: the password hash, the
 * login link, two-step login, passkeys and backup codes leave the data
 * model. What stays is the person's profile, keyed by the IdP's user id
 * (`req.user.id`, here `loginName`), plus the background check.
 */
entity Accounts : cuid, managed {
        loginName                  : String(254) @mandatory; // IdP subject / username; unique
        email                      : Email @mandatory;
        firstName                  : String(150);
        lastName                   : String(150);
        isActive                   : Boolean default true;
        isSuperuser                : Boolean default false; // a role collection in the IdP, kept for parity
        lastLogin                  : Timestamp;
        accountType                : String(10) enum { adult; ninja; service; } default 'adult';
        loginMethod                : String(10) enum { password; link; } default 'password'; // an IdP setting in CAP
        mustChangePassword         : Boolean default false;                                   // idem
        phone                      : Phone;
        preferredLanguage          : LanguageCode default 'nl-be'; // the mail language only
        postalCode                 : PostalCode;

        // Team-page profile, shared by every dojo the person is on.
        displayName                : String(150);
        title                      : String(200);
        bio                        : LargeString;
        photo                      : ImagePath;
        showOnTeamPages            : Boolean default true;

        // Background check (Belgian "model 596.2"), see applications.
        backgroundCheckStatus      : String(20) enum {
            not_requested; requested; submitted; validated; rejected;
        } default 'not_requested';
        backgroundCheckToken       : UUID;
        backgroundCheckDocument    : String(500); // private storage path, never a public URL
        backgroundCheckRequestedAt : Timestamp;
        backgroundCheckSubmittedAt : Timestamp;
        backgroundCheckReviewedAt  : Timestamp;
        backgroundCheckExpiresAt   : Timestamp;

        // Back-links (Django reverse relations).
        ninja                      : Association to one Ninjas on ninja.account = $self; // a ninja's own login
        guardianships              : Composition of many Guardianships on guardianships.guardian = $self;
        organisationRoles          : Composition of many OrganisationRoles on organisationRoles.account = $self;
        memberships                : Association to many DojoMemberships on memberships.user = $self;
}

/** A child aged 7-17. Not a login: it only gets one (an Account) if a guardian opts in. */
entity Ninjas : cuid {
        name           : String(200) @mandatory; // first name
        familyName     : String(200);
        gender         : String(12) enum { girl; boy; other; unspecified; } default 'unspecified';
        account        : Association to Accounts;  // OneToOne, SET_NULL
        dateOfBirth    : Date;
        homeDojo       : Association to Dojos;
        memberSince    : Date;
        allergiesNotes : LargeString @PersonalData.IsPotentiallySensitive; // GDPR art. 9
        photo          : ImagePath;

        guardianships  : Association to many Guardianships on guardianships.ninja = $self;
        registrations  : Association to many Registrations on registrations.ninja = $self;
        badges         : Association to many NinjaBadges on badges.ninja = $self;
        belts          : Association to many NinjaBelts on belts.ninja = $self;
}

entity Guardianships : cuid {
        guardian              : Association to Accounts @mandatory;
        ninja                 : Association to Ninjas @mandatory;
        relation              : GuardianRelation default 'parent';
        createdAt             : Timestamp @cds.on.insert: $now;
        consentGivenAt        : Timestamp;
        consentWordingVersion : String(20);
}

type GuardianRelation : String(20) enum { parent; legal_guardian; other; };

/** Access to the management side. Django syncs a permission group per role; CAP maps each to a role collection. */
entity OrganisationRoles : cuid {
        account   : Association to Accounts @mandatory;
        @mandatory role      : String(10) enum { board; admin; reviewer; };
        grantedAt : Timestamp @cds.on.insert: $now;
}

/** Time-boxed (12 h) access to the Django admin. In CAP there's no Django admin; kept for the elevated-access audit trail. */
entity AdminAccessGrants : cuid {
        account   : Association to Accounts @mandatory;
        reason    : String(300) @mandatory;
        startedAt : Timestamp @cds.on.insert: $now;
        expiresAt : Timestamp @mandatory;
        endedAt   : Timestamp;
        endedBy   : Association to Accounts;
        endReason : String(20) enum { expired; ended; revoked; role_removed; };
}

entity OrganisationInvitations : cuid {
        email      : Email @mandatory;
        name       : String(150) @mandatory;
        roles      : array of String(10); // Django: JSONField list
        language   : String(10);
        invitedBy  : Association to Accounts;
        tokenHash  : TokenHash @mandatory;
        createdAt  : Timestamp @cds.on.insert: $now;
        expiresAt  : Timestamp @mandatory;
        acceptedAt : Timestamp;
        acceptedBy : Association to Accounts;
        withdrawnAt: Timestamp;
}

entity GuardianInvitations : cuid {
        ninja      : Association to Ninjas @mandatory;
        email      : Email @mandatory;
        relation   : GuardianRelation @mandatory;
        language   : String(10);
        invitedBy  : Association to Accounts;
        tokenHash  : TokenHash @mandatory;
        createdAt  : Timestamp @cds.on.insert: $now;
        expiresAt  : Timestamp @mandatory;
        acceptedAt : Timestamp;
        acceptedBy : Association to Accounts;
        withdrawnAt: Timestamp;
}

/** The organisation's sign-in policy per role. In CAP enforced by the IdP's MFA rules, not by the app. */
entity SignInRequirements {
    key role         : String(20) enum {
            superuser; organisation_admin; organisation_board; reviewer; champion; mentor; adult;
        };
        level        : String(10) enum { password; two_step; passkey; } default 'password';
        requiredFrom : Date;
        updatedAt    : Timestamp @cds.on.insert: $now @cds.on.update: $now;
        updatedBy    : Association to Accounts;
}

// Unique constraints (Django Meta.constraints).
annotate Accounts with @assert.unique: { loginName: [loginName] };
annotate Guardianships with @assert.unique: { guardianNinja: [guardian, ninja] };
annotate OrganisationRoles with @assert.unique: { accountRole: [account, role] };
annotate OrganisationInvitations with @assert.unique: { token: [tokenHash] };
annotate GuardianInvitations with @assert.unique: { token: [tokenHash] };
