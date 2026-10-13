// api app: a dojo's OAuth 2.0 client-credentials apps.
namespace coderdojo.api;

using { cuid } from '@sap/cds/common';
using { coderdojo.accounts.Accounts } from './accounts';
using { coderdojo.dojos.Dojos } from './dojos';

/**
 * Django issues the credentials itself (django-oauth-toolkit). On SAP BTP
 * the IdP issues them (an XSUAA/IAS service-key or app-to-app client), so
 * the OAuth application row disappears; only the link to the dojo and its
 * scopes stay.
 */
entity DojoApiClients : cuid {
        dojo      : Association to Dojos @mandatory;
        name      : String(100) @mandatory;
        scopes    : array of String(30); // attendance:read, attendance:write
        clientId  : String(100);         // the IdP's client id (Django: oauth2_provider.Application)
        account   : Association to Accounts; // the service account it acts as
        createdBy : Association to Accounts;
        createdAt : Timestamp @cds.on.insert: $now;
}
