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
        "App/Sources",
        "App/Resources",
      ],
      scripts: [swiftFormatScript],
      dependencies: [
        .target(name: "API"),
        .target(name: "Persistence"),
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
        "App/Tests"
      ],
      scripts: [swiftFormatScript],
      dependencies: [
        .target(name: "StarWarsDB"),
        .target(name: "Persistence"),
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
      name: "Persistence",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .framework,
      bundleId: "dev.iron-ham.Persistence",
      infoPlist: .default,
      buildableFolders: [
        "Persistence/Sources"
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
      name: "PersistenceTests",
      destinations: [.iPad, .iPhone, .mac, .appleVision],
      product: .unitTests,
      bundleId: "dev.iron-ham.PersistenceTests",
      infoPlist: .default,
      buildableFolders: [
        "Persistence/Tests"
      ],
      scripts: [swiftFormatScript],
      dependencies: [.target(name: "Persistence")]
    ),
  ],
  schemes: [
    .scheme(
      name: "StarWarsDB",
      shared: true,
      buildAction: .buildAction(targets: ["StarWarsDB"]),
      testAction: .testPlans([
        .relativeToRoot("TestPlans/StarWarsDB.xctestplan")
      ])
    ),
    .scheme(
      name: "API",
      shared: true,
      buildAction: .buildAction(targets: ["API"]),
      testAction: .testPlans([
        .relativeToRoot("TestPlans/API.xctestplan")
      ])
    ),
    .scheme(
      name: "Persistence",
      shared: true,
      buildAction: .buildAction(targets: ["Persistence"]),
      testAction: .testPlans([
        .relativeToRoot("TestPlans/Persistence.xctestplan")
      ])
    ),
  ]
)
