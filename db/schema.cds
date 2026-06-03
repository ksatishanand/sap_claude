/**
 * Domain data model for the Traveller management application.
 *
 * Models travellers, their contact details, home/destination addresses,
 * and the vacations they plan. This file is the single source of truth;
 * services in srv/ project over these entities and UI in app/ consumes them.
 */
namespace anubhav.claude;

// Common reuse aspects from CAP:
//   sap      - namespace providing sap.common.CodeList (code/name/descr + texts)
//   cuid     - adds a UUID primary key `ID`
//   Currency - managed association to a shared Currencies code list
//   managed  - adds createdAt/createdBy/modifiedAt/modifiedBy audit fields
using { sap, cuid, Currency, managed } from '@sap/cds/common';

//
// Code list entities
// Value-help / lookup tables. Extending sap.common.CodeList gives each a
// human-readable `name`/`descr` plus localized `_texts` automatically.
//

// Categorises a contact address (e.g. Home, Office, Permanent, Temporary).
entity AddressTypes : sap.common.CodeList {
  key code : String(1); // Home, Office, Permanent, Temporary
}

// Lifecycle status of a traveller (e.g. Active, Inactive, Suspended).
entity TravellerStatus : sap.common.CodeList {
  key code : String(1); // Active, Inactive, Suspended
}

//
// Reusable type definitions
// Named association types so the foreign-key relationships read clearly and
// can be reused across entities.
//

type AddressType : Association to AddressTypes;    // FK -> AddressTypes
type Status      : Association to TravellerStatus; // FK -> TravellerStatus

//
// Main entities
//

// A traveller's address / travel destination. UUID-keyed via cuid.
entity Destinations : cuid {
  address    : String(255);
  city       : String(40);
  postalCode : String(8);
  country    : String(40);
  traveller  : Association to Travellers; // owning traveller (back-reference)
}

// Core entity: a person using the app. cuid = UUID key, managed = audit fields.
entity Travellers : cuid, managed {
  userName  : String(255) @mandatory;  // login / unique handle; required
  firstName : String(255);
  lastName  : String(255);
  // Contact rows owned by this traveller; deleted with the parent (composition).
  contacts  : Composition of many Contacts on contacts.traveller = $self;
  gender    : String(10);
  age       : Integer;
  status    : Status default 'A';      // defaults to TravellerStatus code 'A'
  createdBy  : String(40);             // narrows the managed `createdBy` to 40 chars
  // One home/primary address, owned by this traveller.
  address   : Composition of Destinations;
  // Vacations planned by this traveller; deleted with the parent (composition).
  vacations : Composition of many Vacations on vacations.traveller = $self;
}

// Use the managed `modifiedAt` as an OData ETag for optimistic concurrency.
annotate Travellers with {
  modifiedAt @odata.etag;
}

// A single contact address for a traveller, typed via AddressTypes.
entity Contacts : cuid {
  type      : AddressType;                // kind of address (Home/Office/...)
  address   : String(255);
  traveller : Association to Travellers;   // owning traveller (back-reference)
}

// A planned vacation with budget and date range.
entity Vacations : cuid {
  name        : String(255);
  budget      : Decimal(10, 2);            // up to 99,999,999.99
  currency    : Currency;                  // FK -> sap.common.Currencies
  description : String(1024);
  startsAt    : DateTime;
  endsAt      : DateTime;
  traveller   : Association to Travellers;  // owning traveller (back-reference)
}

//
// Application access / identity entities
//

// Application roles for authorization (e.g. ADMIN, TRAVELLER, AGENT).
entity Roles : sap.common.CodeList {
  key code : String(10); // ADMIN, TRAVELLER, AGENT
}

// An authenticated application user. cuid = UUID key, managed = audit fields.
entity AppUsers : cuid, managed {
  userName    : String(100) @mandatory;     // login / unique handle; required
  email       : String(255) @mandatory;     // contact email; required
  fullName    : String(255);
  role        : Association to Roles;        // FK -> Roles (authorization level)
  isActive    : Boolean default true;        // soft enable/disable flag
  lastLoginAt : DateTime;                    // timestamp of most recent sign-in
  // Optional link to the traveller profile, when this user is a traveller.
  traveller   : Association to Travellers;
}
