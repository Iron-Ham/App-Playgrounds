import API
import IdentifiedCollections
import SwiftUI

struct ViewModel: Sendable, Hashable {
  let allFilms: IdentifiedArray<FilmResponse.ID, FilmResponse>
}

class ViewController: UIViewController {
  private typealias CellRegistration = UICollectionView.CellRegistration
  private typealias SupplementaryRegistration = UICollectionView.SupplementaryRegistration

  private lazy var layout = UICollectionViewCompositionalLayout { _, environment in
    var listConfiguration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    listConfiguration.headerMode = .supplementary
    return NSCollectionLayoutSection.list(using: listConfiguration, layoutEnvironment: environment)
  }

  private lazy var collectionView: UICollectionView = {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.delegate = self
    return collectionView
  }()

  private var dataSource: UICollectionViewDiffableDataSource<Section, FilmResponse.ID>!

  private lazy var refreshControl = UIRefreshControl(
    frame: .zero,
    primaryAction: UIAction { [weak self] _ in
      guard let self else { return }
      fetchFilms()
    })

  private var viewModel = ViewModel(allFilms: []) {
    didSet {
      if viewModel.allFilms.isEmpty {
        contentUnavailableConfiguration = UIContentUnavailableConfiguration.empty()
      } else {
        contentUnavailableConfiguration = nil
        dataSource.apply(snapshot())
      }
    }
  }

  override func loadView() {
    view = collectionView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupDataSource()
    navigationItem.title = "Star Wars"
    navigationController?.navigationBar.prefersLargeTitles = true
    collectionView.refreshControl = refreshControl

    contentUnavailableConfiguration = UIContentUnavailableConfiguration.loading()
    fetchFilms()
  }

  private func fetchFilms() {
    Task.detached { [weak self] in
      guard let self else { return }
      await MainActor.run { [weak self] in
        self?.refreshControl.endRefreshing()
      }
      do {
        let films = try await SWAPIClient.films()
        await MainActor.run {
          self.viewModel = ViewModel(allFilms: .init(uniqueElements: films))
        }
      } catch {
        await MainActor.run { [weak self] in
          self?.contentUnavailableConfiguration = self?.errorConfiguration(error: error)
        }
      }
    }
  }

  private func setupDataSource() {
    let cellRegistration = CellRegistration<UICollectionViewListCell, FilmResponse.ID> {
      cell, indexPath, itemID in
      let item = self.viewModel.allFilms.first(where: { $0.id == itemID })!
      cell.accessories = [.disclosureIndicator()]
      cell.backgroundConfiguration = UIBackgroundConfiguration.listCell()
      cell.contentConfiguration = UIHostingConfiguration {
        CellView(film: item)
      }
    }

    let supplementaryRegistration = SupplementaryRegistration<UICollectionViewListCell>(
      elementKind: UICollectionView.elementKindSectionHeader
    ) { supplementaryView, elementKind, indexPath in
      let section = Section.allCases[indexPath.section]
      supplementaryView.contentConfiguration = UIHostingConfiguration {
        Text(section.title)
          .font(.headline)
          .foregroundStyle(.primary)
      }
    }

    let dataSource = UICollectionViewDiffableDataSource<Section, FilmResponse.ID>(
      collectionView: collectionView
    ) { collectionView, indexPath, item in
      collectionView.dequeueConfiguredReusableCell(
        using: cellRegistration, for: indexPath, item: item)
    }
    dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
      collectionView.dequeueConfiguredReusableSupplementary(
        using: supplementaryRegistration, for: indexPath)
    }

    self.dataSource = dataSource
  }

  private func errorConfiguration(error: Error) -> UIContentUnavailableConfiguration {
    var config = UIContentUnavailableConfiguration.empty()
    config.text = error.localizedDescription
    config.image = UIImage(systemName: "x.circle")
    return config
  }

  private func snapshot() -> NSDiffableDataSourceSnapshot<Section, FilmResponse.ID> {
    var snapshot = NSDiffableDataSourceSnapshot<Section, FilmResponse.ID>()
    snapshot.appendSections([.allFilms])
    snapshot.appendItems(viewModel.allFilms.map(\.id), toSection: .allFilms)
    return snapshot
  }
}

extension ViewController: UICollectionViewDelegate {

}

private struct CellView: View {
  let film: FilmResponse

  var body: some View {
    VStack(alignment: .leading) {
      if let releaseDate = film.release?.formatted(date: .abbreviated, time: .omitted) {
        Text(releaseDate)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Text(film.title)
        .font(.title2)
        .foregroundStyle(.primary)
    }
  }
}

private nonisolated enum Section: Sendable, CaseIterable {
  case allFilms

  var title: String {
    switch self {
    case .allFilms:
      "All Films"
    }
  }
}

#Preview {
  UINavigationController(rootViewController: ViewController())
}
