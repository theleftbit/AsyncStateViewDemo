import SwiftUI

public struct AsyncStateView<Data, HostedView: View, ErrorView: View, LoadingView: View, ID: Equatable>: View {
  
  /// Represents the state of this view
  struct Operation {
    
    var id: ID
    var phase: Phase
    
    enum Phase {
      case idle
      case loading
      case loaded(Data)
      case error(Swift.Error)
    }
  }
  
  public typealias DataGenerator = () async throws -> Data
  public typealias HostedViewGenerator = (Data) -> HostedView
  public typealias ErrorViewGenerator = (Swift.Error, @escaping OnRetryHandler) -> ErrorView
  public typealias LoadingViewGenerator = () -> LoadingView
  public typealias OnRetryHandler = () -> ()
  
  @Binding var id: ID
  let dataGenerator: DataGenerator
  let hostedViewGenerator: HostedViewGenerator
  let errorViewGenerator: ErrorViewGenerator
  let loadingView: LoadingView
  @State private var currentOperation: Operation
  
  /// Creates a new `AsyncStateView`
  /// - Parameters:
  ///   - id: A `Binding` to the identifier for this view. This allows SwiftUI to unequivocally know what's being rendered when the view is loaded. For this value you can use the remote ID of the object being loaded.
  ///   - dataGenerator: The function that generates the data that is required for your `HostedView`
  ///   - hostedViewGenerator: The function that creates the `HostedView`.
  ///   - errorViewGenerator: The function that creates the `ErrorView`.
  ///   - loadingViewGenerator: The function that creates the `LoadingView`.
  public init(id: Binding<ID>,
              dataGenerator: @escaping DataGenerator,
              @ViewBuilder hostedViewGenerator: @escaping HostedViewGenerator,
              @ViewBuilder errorViewGenerator: @escaping ErrorViewGenerator,
              @ViewBuilder loadingViewGenerator: LoadingViewGenerator) {
    self._id = id
    self._currentOperation = .init(initialValue: .init(id: id.wrappedValue, phase: .idle))
    self.dataGenerator = dataGenerator
    self.hostedViewGenerator = hostedViewGenerator
    self.errorViewGenerator = errorViewGenerator
    self.loadingView = loadingViewGenerator()
  }
  
  public init(id: ID,
              dataGenerator: @escaping DataGenerator,
              @ViewBuilder hostedViewGenerator: @escaping HostedViewGenerator,
              @ViewBuilder errorViewGenerator: @escaping ErrorViewGenerator,
              @ViewBuilder loadingViewGenerator: LoadingViewGenerator) {
    self.init(id: .constant(id), dataGenerator: dataGenerator, hostedViewGenerator: hostedViewGenerator, errorViewGenerator: errorViewGenerator, loadingViewGenerator: loadingViewGenerator)
  }
  
  public var body: some View {
    actualView
      .task(id: id) {
        await fetchData()
      }
  }

  @ViewBuilder
  private var actualView: some View {
    switch currentOperation.phase {
    case .idle, .loading:
      loadingView
    case .loaded(let data):
      hostedViewGenerator(data)
    case .error(let error):
      errorViewGenerator(error, {
        fetchData()
      })
    }
  }
  
  //MARK: Private
  
  @Environment(\.redactionReasons) private var reasons
  
  private func fetchData() {
    Task { await fetchData() }
  }
  
  @MainActor
  private func fetchData() async {
    if reasons.contains(.placeholder) {
      /// Make sure no request is fired in case that this view
      /// is used to compose a sub-section of the view hierarchy.
      return
    }
    /// Turns out `.task { }` is called also
    /// when the view appears so if we're already
    /// loaded do not schedule a new fetch operation.
    if currentOperation.isLoaded(forID: id) { return }
    
    /// If the previous fetch has failed for non-cancelling reasons,
    /// then we should not retry the operation automatically
    /// and give the user chance to retry it using the UI.
    if currentOperation.isNonCancelledError(forID: id) { return }
    
    /// If we we are on the right state, let's perform the fetch.
    currentOperation.id = id
    withAnimation {
      currentOperation.phase = .loading
    }
    do {
      let finalData = try await dataGenerator()
      withAnimation {
        currentOperation.phase = .loaded(finalData)
      }
    } catch is CancellationError {
      /// Do nothing as we handle this `.onAppear`
    } catch {
      withAnimation {
        currentOperation.phase = .error(error)
      }
    }
  }
}

private extension AsyncStateView.Operation {
  
  func isNonCancelledError(forID id: ID) -> Bool {
    guard self.id == id else { return false }
    switch self.phase {
    case .error(let error):
      let isCancelledError = (error is CancellationError)
      return !isCancelledError
    default:
      return false
    }
  }
  
  func isLoaded(forID id: ID) -> Bool {
    guard self.id == id else { return false }
    switch self.phase {
    case .loaded:
      return true
    default:
      return false
    }
  }
}
