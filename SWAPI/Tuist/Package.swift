// swift-tools-version: 6.0
import PackageDescription

#if TUIST
  import struct ProjectDescription.PackageSettings

  let packageSettings = PackageSettings(
    // Customize the product types for specific package product
    // Default is .staticFramework
    productTypes: [
      "Clocks": .framework,
      "CombineSchedulers": .framework,
      "ConcurrencyExtras": .framework,
      "CustomDump": .framework,
      "Dependencies": .framework,
      "GRDB": .framework,
      "GRDBSQLite": .framework,
      "IdentifiedCollections": .framework,
      "InternalCollectionsUtilities": .framework,
      "IssueReporting": .framework,
      "IssueReportingPackageSupport": .framework,
      "OrderedCollections": .framework,
      "PerceptionCore": .framework,
      "SQLiteData": .framework,
      "Sharing": .framework,
      "Sharing1": .framework,
      "Sharing2": .framework,
      "StructuredQueriesCore": .framework,
      "StructuredQueriesSQLiteCore": .framework,
      "StructuredQueries": .framework,
      "StructuredQueriesMacros": .framework,
      "XCTestDynamicOverlay": .framework,
    ]
  )
#endif

let package = Package(
  name: "SWAPI",
  dependencies: [
    // Add your own dependencies here:
    // .package(url: "https://github.com/Alamofire/Alamofire", from: "5.0.0"),
    // You can read more about dependencies here: https://docs.tuist.io/documentation/tuist/dependencies
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
    .package(url: "https://github.com/pointfreeco/swift-structured-queries", from: "0.21.0"),
    .package(url: "https://github.com/vapor/fluent", from: "4.13.0"),
    .package(url: "https://github.com/vapor/fluent-sqlite-driver", from: "4.8.1"),
    .package(url: "https://github.com/apple/swift-log", from: "1.5.4"),
    .package(url: "https://github.com/apple/swift-nio", from: "2.60.0"),
  ]
)
