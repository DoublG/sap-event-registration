// mailing app: the mail engine (queue, templates, consent, bounces).
namespace coderdojo.mailing;

using { cuid } from '@sap/cds/common';
using { coderdojo.Email, coderdojo.MailCategory, coderdojo.LanguageCode } from './common';
using { coderdojo.accounts.Accounts } from './accounts';
using { coderdojo.dojos.Dojos } from './dojos';
using { coderdojo.campaigns.Campaigns } from './campaigns';

/** One row per template key and language (Django translates mail this way, not with gettext). */
entity EmailTemplates : cuid {
        key_        : String(100) @mandatory; // `key` is reserved in CDS
        language    : LanguageCode @mandatory;
        category    : MailCategory @mandatory;
        description : String(255);
        subject     : String(255) @mandatory;
        body        : LargeString @mandatory;
}

/**
 * The outbound queue. Django drains it with Celery workers every 10 s;
 * in CAP that's the outbox (cds.outboxed / @cap-js/event-queue) plus the
 * SAP Alert Notification or a mail service binding (MAPPING.md).
 */
entity EmailMessages : cuid {
        category       : MailCategory @mandatory;
        templateKey    : String(100);
        user           : Association to Accounts;
        recipient      : Email;
        language       : String(10);
        subject        : String(255) @mandatory;
        body           : LargeString @mandatory;
        campaign       : Association to Campaigns;
        dojo           : Association to Dojos;
        replyTo        : Email;
        status         : String(20) enum { pending; sending; sent; failed; bounced; suppressed; } default 'pending';
        statusReason   : String(255);
        priority       : Integer default 5;
        sendAfter      : Timestamp;
        claimedAt      : Timestamp;
        attempts       : Integer default 0;
        idempotencyKey : String(200); // unique when set
        messageId      : String(255);
        isTest         : Boolean default false;
        createdAt      : Timestamp @cds.on.insert: $now;
        sentAt         : Timestamp;
        bouncedAt      : Timestamp;
        bounces        : Association to many BounceRecords on bounces.message = $self;
}

entity MailPreferences : cuid {
        user       : Association to Accounts @mandatory;
        category   : MailCategory @mandatory;
        subscribed : Boolean @mandatory;
        changedAt  : Timestamp @cds.on.insert: $now @cds.on.update: $now;
}

/** Append-only consent log. */
entity ConsentEvents : cuid {
        user           : Association to Accounts @mandatory;
        category       : MailCategory @mandatory;
        dojo           : Association to Dojos;
        subscribed     : Boolean @mandatory;
        @mandatory source         : String(20) enum { signup; preferences; unsubscribe_link; admin; bounce; };
        wordingVersion : String(20);
        createdAt      : Timestamp @cds.on.insert: $now;
}

entity DojoMailMutes : cuid {
        user      : Association to Accounts @mandatory;
        dojo      : Association to Dojos @mandatory;
        createdAt : Timestamp @cds.on.insert: $now;
}

entity EmailSuppressions : cuid {
        email     : Email @mandatory; // lower-case, unique
        @mandatory reason    : String(20) enum { hard_bounce; soft_bounces; complaint; manual; };
        note      : String(255);
        createdAt : Timestamp @cds.on.insert: $now;
}

entity BlockedDomains : cuid {
        domain    : String(253) @mandatory; // unique
        note      : String(255);
        createdAt : Timestamp @cds.on.insert: $now;
}

entity BounceRecords : cuid {
        email      : Email @mandatory;
        @mandatory kind       : String(10) enum { hard; soft; complaint; };
        statusCode : String(20);
        diagnostic : String(255);
        message    : Association to EmailMessages;
        createdAt  : Timestamp @cds.on.insert: $now;
}

entity ProcessedImapMessages : cuid {
        mailbox : String(255) @mandatory;
        uid     : String(255) @mandatory;
}

annotate EmailTemplates with @assert.unique: { keyLanguage: [key_, language] };
annotate EmailMessages with @assert.unique: { idempotency: [idempotencyKey] };
annotate MailPreferences with @assert.unique: { userCategory: [user, category] };
annotate DojoMailMutes with @assert.unique: { userDojo: [user, dojo] };
annotate EmailSuppressions with @assert.unique: { email: [email] };
annotate BlockedDomains with @assert.unique: { domain: [domain] };
annotate ProcessedImapMessages with @assert.unique: { mailboxUid: [mailbox, uid] };
