Hello SwiftUI team,

In order to ease our transition to SwiftUI, we created a generic view called `AsyncStateView` that helps developers build UIs where the data is coming from remote web servers.

This, paired with SwiftUI's data-driven approach, has enabled our developers to be more productive and build more engaging user interfaces.

This tech was used to build the new Standings for the MLB app and we're excited with the result, just had some questions on some behaviour we are seeing.

We found found that sometimes, some interaction glitches occurred due to invalidation of `body`.

You can checkout the project and run it to see the structure:

-  The `DemoApp` creates a `RootView`
- `RootView` will simulate fetching some "Means of Transport" categories and put that as some sort of "selectable tabs" on the top of the UI. It does so by using `AsyncStateView`.
- When that fetch is completed, the details for the Selected Tab will be fetched and displayed on a ScrollView. It also does this using `AsyncStateView`

And here is a video of the glitches that we are seeing: 

https://github.com/theleftbit/AsyncStateViewDemo/assets/869981/ace720af-d6da-40d9-9118-15dab6a314b8

During our debugging, we narrowed down the problem to `AsyncStateView`'s `body` [implementation](https://github.com/theleftbit/AsyncStateViewDemo/blob/main/AsyncStateViewDemo/AsyncStateView.swift#L61):

```swift
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
```

Changing the `actualView` implemetation from a `@ViewBuilder` to a `VStack` fixes the issue we are seeing changing the selected element in the `TabView` on top. 

We don't know why this change would have any effect, but we are inclined to think that this is due to SwiftUI not being able to figure out the Structural Identity of this View when using a `@ViewBuilder`, which brings the question: Why? 

We tried debugging with `Self._printChanges()` but couldn't see any significant changes. We also tried using `Group` but the result is the same. Why is a `VStack` with one element better in terms of generating a stable Structural Identity? Or maybe that is not the problem, but `VStack` is a workaround? We also started wondering if maybe creating the views inside the `body` using an `@escaping` closure would be a problem, but `AsyncImage` (among other Views in the SDK) do it like this, so we couldn't conclude anything in that front.

So, if you where to only make this change (swap `@ViewBuilder` for `VStack` in AsyncStateView.swift line 61) and run the project, the behaviour would be almost be correct: if you scroll all the way to the "Feet" tab and select it, it would also glitch.

https://github.com/theleftbit/AsyncStateViewDemo/assets/869981/6eb35c73-d1db-4ccc-bd5e-4015766ff6f6

Turns out that we are using `@ViewBuilder` in another place, now in the `ContentView` to decide what view to display after a user's [selection:](https://github.com/theleftbit/AsyncStateViewDemo/blob/main/AsyncStateViewDemo/Views/ContentView.swift#L21)

Changing that to a `VStack` with just one element _also_ fixes this issue. Which brings again the question? Why? Isn't this what `@ViewBuilder` or `Group` is for? to create views using conditional logic and applying view modifiers to it? We tried breaking this logic apart in a different subview but coudln't see any different result. Only wrapping it in a `VStack` would do.

We are asking these questions because, even though we have a valid workaround, `AsyncStateView` is one of the core types that we are using to build the rest of the UI and we'd like to know if there are any deficiencies on it's implementation. 

Thanks for your help and sorry for the long long question, but lots of moving pieces and this is as narrowed down as we could do it. 



