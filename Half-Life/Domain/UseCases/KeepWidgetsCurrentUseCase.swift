//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life KeepWidgetsCurrentUseCase
//

/// Keeps the Home Screen widgets' snapshot current for as long as it runs.
///
/// Subscribing to ``WidgetSnapshotRepository/snapshots()`` keeps the repository listening for changes, and each change
/// stores a new snapshot and reloads the widgets. ``AppFeature`` runs it from launch, so a drink logged while the
/// system launched the app in the background still reaches the widgets. See WUSE-1 in the Widgets article.
struct KeepWidgetsCurrentUseCase: UseCase {
    /// The repository that stores the snapshot.
    let repository: any WidgetSnapshotRepository

    /// Subscribes to the snapshots until the stream ends or the task is cancelled.
    ///
    /// - Parameter input: None.
    func execute(_ input: Void) async {
        for await _ in repository.snapshots() {}
    }
}
