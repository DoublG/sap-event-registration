// notifications app: the dashboard bells.
namespace coderdojo.notifications;

using { cuid } from '@sap/cds/common';
using { coderdojo.accounts.Accounts } from './accounts';
using { coderdojo.dojos.Dojos } from './dojos';

/**
 * Django pushes new rows live over WebSockets (Channels + Redis). CAP has
 * no built-in WebSocket push: the @cap-js-community/websocket plugin or SAP
 * Event Mesh would replace it (MAPPING.md).
 */
entity Notifications : cuid {
        recipient    : Association to Accounts @mandatory;
        dojo         : Association to Dojos;
        organisation : Boolean default false;
        text         : String(300) @mandatory; // rendered in the recipient's language when created
        url          : String(300);
        createdAt    : Timestamp @cds.on.insert: $now;
        read         : Boolean default false;
}
