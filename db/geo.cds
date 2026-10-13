// geo app: reference data for the dojo finder.
namespace coderdojo.geo;

using { coderdojo.GeoPoint } from './common';

/**
 * Country and province outlines. Django: a MultiPolygonField. CAP has no
 * geometry type; the outline is kept as GeoJSON text, and "which province is
 * this point in" moves to HANA's spatial functions (ST_GeomFromGeoJSON,
 * ST_Covers) in a native query, or to a precomputed province per municipality.
 */
entity AdministrativeBoundaries {
    key ID       : Integer;
        @mandatory kind     : String(10) enum { country; province; };
        name     : String(200) @mandatory;
        boundary : LargeString; // GeoJSON MultiPolygon, SRID 4326
}

entity Municipalities {
    key ID         : Integer;
        postalCode : String(10) @mandatory;
        name       : String(200) @mandatory;
        center     : GeoPoint;
}
