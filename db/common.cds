// Shared types for the whole model: the Django `choices` become CDS enums,
// the repeated field shapes become types, and the Django base classes
// (TranslatableModel, OrganisationContent, ScopedContent) become aspects.
namespace coderdojo;


// --- Field shapes ----------------------------------------------------------

type Email      : String(254);
type Phone      : String(30);
type Url        : String(500);
type Name       : String(200);
type ShortText  : String(300);
type PostalCode : String(4);   // Belgian postcodes
type HexColour  : String(7);   // "#f5c518"
type TokenHash  : String(64);  // sha256 hex of an emailed token

/** A site language: en-us, nl-be, fr-be (Django settings.LANGUAGES). */
type LanguageCode : String(10) enum {
    en = 'en-us';
    nl = 'nl-be';
    fr = 'fr-be';
};

/**
 * Django stores images as an ImageField (a path in media storage, resized
 * and stripped of metadata on save, core/uploads.py). CAP has no file field:
 * here it's the stored path, and the upload itself is a separate concern
 * (an Object Store / the attachments plugin, see MAPPING.md).
 */
type ImagePath : String(500);

/**
 * django.contrib.gis PointField (SRID 4326). CAP has no geometry type, so a
 * point is two decimals; distance search needs native SQL on HANA
 * (ST_Point / ST_Distance) or a bounding box plus haversine (MAPPING.md).
 */
type GeoPoint {
    latitude  : Decimal(9, 6);
    longitude : Decimal(9, 6);
}

// --- Enums (Django choices) --------------------------------------------------

type MailCategory : String(20) enum {
    service; registration; reminder; dojo_news; volunteer; newsletter;
};

// --- Aspects (Django abstract base classes) ---------------------------------

/**
 * Django's TranslatableModel keeps the main language in the normal columns
 * and the other languages in one JSON `translations` column, with the
 * languages chosen per dojo. CAP's equivalent is `localized` on each text
 * element, which generates a <Entity>.texts table keyed by locale and
 * falls back to the default text. The per-dojo choice of languages has no
 * CAP equivalent: it stays an attribute (Dojos.languages) checked in code.
 */
aspect Translatable {}

/** Content the organisation writes (pathways, belts, badges, promotions...). */
aspect OrganisationContent : Translatable {}

/** FAQs and testimonials: the organisation's, or a dojo's when scoped to one. */
aspect ScopedContent : Translatable {}
