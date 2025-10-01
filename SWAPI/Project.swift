import ProjectDescription

private let swiftFormatScript: TargetScript = .pre(
  path: .relativeToRoot("Scripts/swift-format.sh"),
  arguments: [],
  name: "Swift Format",
  basedOnDependencyAnalysis: false
)

let project = Project(
  name: "SWAPI",
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.0"
    ]
  ),
  targets: [
    .target(
      name: "SWAPI-SwiftUI",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .app,
      bundleId: "dev.iron-ham.SWAPI-SwiftUI",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchScreen": [
            "UIColorName": "",
            "UIImageName": "",
          ]
        ]
      ),
      buildableFolders: [
        "SwiftUI/Sources",
        "SwiftUI/Resources",
      ],
      scripts: [swiftFormatScript],
      dependencies: [
        .target(name: "API"),
        .target(name: "SQLiteDataPersistence"),
        .external(name: "SQLiteData"),
        .external(name: "Dependencies"),
        .external(name: "StructuredQueries"),
      ]
    ),
    .target(
      name: "SwiftUI-Tests",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .unitTests,
      bundleId: "dev.iron-ham.SwiftUI-Tests",
      infoPlist: .default,
      buildableFolders: [
        "SwiftUI/Tests"
      ],
      scripts: [swiftFormatScript],
      dependencies: [
        .target(name: "SWAPI-SwiftUI"),
        .target(name: "SQLiteDataPersistence"),
        .target(name: "API"),
        .external(name: "Dependencies"),
      ]
    ),
    .target(
      name: "API",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .framework,
      bundleId: "dev.iron-ham.API",
      infoPlist: .default,
      buildableFolders: [
        "API/Sources"
      ],
      scripts: [swiftFormatScript],
      dependencies: []
    ),
    .target(
      name: "APITests",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .unitTests,
      bundleId: "dev.iron-ham.APITests",
      infoPlist: .default,
      buildableFolders: [
        "API/Tests"
      ],
      scripts: [swiftFormatScript],
      dependencies: [.target(name: "API")]
    ),
    .target(
      name: "SQLiteDataPersistence",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .framework,
      bundleId: "dev.iron-ham.SQLiteDataPersistence",
      infoPlist: .default,
      buildableFolders: [
        "Persistence/SQLiteData/Sources"
      ],
      scripts: [swiftFormatScript],
      dependencies: [
        .external(name: "Dependencies"),
        .external(name: "SQLiteData"),
        .target(name: "API"),
      ]
    ),
    .target(
      name: "SQliteDataPersistenceTests",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .unitTests,
      bundleId: "dev.iron-ham.SQliteDataPersistenceTests",
      infoPlist: .default,
      buildableFolders: [
        "Persistence/SQLiteData/Tests"
      ],
      scripts: [swiftFormatScript],
      dependencies: [.target(name: "SQLiteDataPersistence")]
    ),
    .target(
      name: "FluentPersistence",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .framework,
      bundleId: "dev.iron-ham.FluentPersistence",
      infoPlist: .default,
      buildableFolders: [
        "Persistence/Fluent/Sources"
      ],
      scripts: [swiftFormatScript],
      dependencies: [
        .external(name: "Fluent"),
        .external(name: "FluentSQLiteDriver"),
        .external(name: "Logging"),
        .external(name: "NIO"),
        .target(name: "API"),
      ]
    ),
    .target(
      name: "FluentPersistenceTests",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .unitTests,
      bundleId: "dev.iron-ham.FluentPersistenceTests",
      infoPlist: .default,
      buildableFolders: [
        "Persistence/Fluent/Tests"
      ],
      scripts: [swiftFormatScript],
      dependencies: [.target(name: "FluentPersistence")]
    ),
  ]
)
