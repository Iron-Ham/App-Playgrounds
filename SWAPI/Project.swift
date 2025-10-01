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
      bundleId: "dev.tuist.SWAPI-SwiftUI",
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
        .target(name: "Persistence"),
        .external(name: "SQLiteData"),
        .external(name: "Dependencies"),
        .external(name: "StructuredQueries"),
      ]
    ),
    .target(
      name: "SwiftUI-Tests",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .unitTests,
      bundleId: "dev.tuist.SwiftUI-Tests",
      infoPlist: .default,
      buildableFolders: [
        "SwiftUI/Tests"
      ],
      scripts: [swiftFormatScript],
      dependencies: [
        .target(name: "SWAPI-SwiftUI"),
        .target(name: "Persistence"),
        .target(name: "API"),
        .external(name: "Dependencies"),
      ]
    ),
    .target(
      name: "API",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .framework,
      bundleId: "dev.tuist.API",
      infoPlist: .default,
      buildableFolders: [
        "API/Sources",
        "API/Resources",
      ],
      scripts: [swiftFormatScript],
      dependencies: [
        .external(name: "Dependencies")
      ]
    ),
    .target(
      name: "APITests",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .unitTests,
      bundleId: "dev.tuist.APITests",
      infoPlist: .default,
      buildableFolders: [
        "API/Tests"
      ],
      scripts: [swiftFormatScript],
      dependencies: [.target(name: "API")]
    ),
    .target(
      name: "Persistence",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .framework,
      bundleId: "dev.tuist.Persistence",
      infoPlist: .default,
      buildableFolders: [
        "Persistence/Sources",
        "Persistence/Resources",
      ],
      scripts: [swiftFormatScript],
      dependencies: [
        .external(name: "Dependencies"),
        .external(name: "SQLiteData"),
        .target(name: "API"),
      ]
    ),
    .target(
      name: "PersistenceTests",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .unitTests,
      bundleId: "dev.tuist.PersistenceTests",
      infoPlist: .default,
      buildableFolders: [
        "Persistence/Tests"
      ],
      scripts: [swiftFormatScript],
      dependencies: [.target(name: "Persistence")]
    ),
  ]
)
