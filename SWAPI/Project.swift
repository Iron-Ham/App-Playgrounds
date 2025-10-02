import ProjectDescription

private let swiftFormatScript: TargetScript = .pre(
  path: .relativeToRoot("Scripts/swift-format.sh"),
  arguments: [],
  name: "Swift Format",
  basedOnDependencyAnalysis: false
)

let project = Project(
  name: "StarWarsDB",
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.0",
      "EXCLUDED_ARCHS[sdk=macosx*]": "x86_64",
    ]
  ),
  targets: [
    .target(
      name: "StarWarsDB",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .app,
      bundleId: "dev.iron-ham.StarWarsDB",
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
        .target(name: "FluentPersistence"),
        .external(name: "Dependencies"),
      ]
    ),
    .target(
      name: "StarWarsDBTests",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .unitTests,
      bundleId: "dev.iron-ham.StarWarsDBTests",
      infoPlist: .default,
      buildableFolders: [
        "SwiftUI/Tests"
      ],
      scripts: [swiftFormatScript],
      dependencies: [
        .target(name: "StarWarsDB"),
        .target(name: "FluentPersistence"),
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
