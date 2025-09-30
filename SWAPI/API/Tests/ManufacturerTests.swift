import Foundation
import Testing

@testable import API

@Suite("ManufacturerTests", .serialized)
struct ManufacturerTests {
  @Test
  func initializerTrimsAndCanonicalizes() {
    let manufacturer = Manufacturer(rawName: "  Incom corporation  ")

    #expect(manufacturer.rawName == "Incom corporation")
    #expect(manufacturer.displayName == "Incom Corporation")
    #expect(manufacturer.identifier == "incom corporation")
  }

  @Test
  func identifierStripsCorporateSuffixes() {
    let manufacturer = Manufacturer(rawName: "Cygnus Spaceworks, Inc.")

    #expect(manufacturer.rawName == "Cygnus Spaceworks, Inc.")
    #expect(manufacturer.displayName == "Cygnus Spaceworks")
    #expect(manufacturer.identifier == "cygnus spaceworks")
  }

  @Test
  func manufacturersFromSplitsDelimitersAndPreservesOrder() {
    let raw =
      "Hoersch-Kessel Drive, Inc, Gwori Revolutionary Industries / Kuat Drive Yards, Imperial Department of Military Research"
    let manufacturers = Manufacturer.manufacturers(from: raw)

    #expect(
      manufacturers.map(\.displayName) == [
        "Hoersch-Kessel Drive",
        "Gwori Revolutionary Industries",
        "Kuat Drive Yards",
        "Imperial Department of Military Research",
      ])

    #expect(
      manufacturers.map(\.identifier) == [
        "hoersch-kessel drive",
        "gwori revolutionary industries",
        "kuat drive yards",
        "imperial department of military research",
      ])
  }

  @Test
  func manufacturersFromDeduplicatesCanonicalVariants() throws {
    let raw = "Cygnus Spaceworks / Cyngus Spaceworks, Incorporated"
    let manufacturers = Manufacturer.manufacturers(from: raw)

    #expect(manufacturers.count == 1)
    let canonical = try #require(manufacturers.first)
    #expect(canonical.displayName == "Cygnus Spaceworks")
    #expect(canonical.identifier == "cygnus spaceworks")
    #expect(canonical.rawName == "Cygnus Spaceworks")
  }

  @Test
  func brandNewManufacturerFallsBackGracefully() {
    let manufacturer = Manufacturer(rawName: "Schleem Enterprises, Inc.")

    #expect(manufacturer.rawName == "Schleem Enterprises, Inc.")
    #expect(manufacturer.displayName == "Schleem Enterprises")
    #expect(manufacturer.identifier == "schleem enterprises")
  }

  @Test
  func unknownManufacturerCanonicalization() {
    let manufacturer = Manufacturer(rawName: "unknown")

    #expect(manufacturer.rawName == "unknown")
    #expect(manufacturer.displayName == "Unknown")
    #expect(manufacturer.identifier == "unknown")
  }
}
