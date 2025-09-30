# ``DataStore``

Bring the Star Wars API offline with a set of ``SwiftData`` models, a ready-to-use ``ModelContainer``, and a batch importer that maps networking responses into local persistence.

## Overview

The ``DataStore`` module mirrors the networking layer provided by the ``API`` target and exposes:

- ``Film``, ``Person``, ``Planet``, ``Species``, ``Starship``, and ``Vehicle`` SwiftData models with rich computed properties for presentation.
- ``SWAPIDataStore`` as a lightweight factory for creating a configured ``SwiftData/ModelContainer``.
- ``SnapshotImporter`` to translate decoded ``API`` response structs into managed models, wiring up all cross-entity relationships.

Use these tools to hydrate a SwiftUI or UIKit experience with offline-capable data, preview fixtures, and testing support.

## Topics

### Building the container

- ``SWAPIDataStore``
- ``SWAPIDataStorePreview``

### Persisted models

- ``Film``
- ``Person``
- ``Planet``
- ``Species``
- ``Starship``
- ``Vehicle``

### Importing API responses

- ``SnapshotImporter``
