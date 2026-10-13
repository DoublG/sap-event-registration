// monitoring app: the daily capacity sample.
namespace coderdojo.monitoring;

entity CapacitySamples {
    key takenOn : Date;
        takenAt : Timestamp @mandatory;
        data    : LargeString; // JSON
}
