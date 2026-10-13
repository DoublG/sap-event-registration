// reports app: saved Perspective reports over curated datasets.
namespace coderdojo.reports;

using { cuid, managed } from '@sap/cds/common';
using { coderdojo.accounts.Accounts } from './accounts';

/**
 * The datasets themselves are Python classes (reports/datasets/). In CAP
 * they'd be aggregating CDS views (@Aggregation, @Analytics) exposed over
 * OData, which SAP Analytics Cloud or an analytical list page can read.
 */
entity Reports : cuid {
        name           : String(200) @mandatory;
        description    : LargeString;
        dataset        : String(50) @mandatory;
        config         : LargeString; // Perspective viewer settings, JSON
        status         : String(10) enum { draft; published; } default 'draft';
        sharedWithDojos: Boolean default false;
        position       : Integer default 0;
        standardKey    : String(50);
        standardHash   : String(64);
        createdBy      : Association to Accounts;
        updatedBy      : Association to Accounts;
        createdAt      : Timestamp @cds.on.insert: $now;
        updatedAt      : Timestamp @cds.on.insert: $now @cds.on.update: $now;
}
