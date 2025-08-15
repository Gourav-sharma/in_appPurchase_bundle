# in_app_subscription_bundle

This plugin provides a reusable, BLoC-based solution for handling in-app purchases and subscriptions in Flutter applications. It simplifies integration with the `in_app_purchase` package for both Android and iOS, encapsulating complex subscription logic in an easy-to-use API.

## Features
- **BLoC-based API** for clean state management.
- Support for **iOS and Android**.
- Handles **consumable and non-consumable** purchases.
- Full support for **auto-renewable subscriptions**.
- **Restore purchases** with ease.

## Installation
Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  in_app_subscription_bundle: ^0.0.1
```

## Usage

### Step 1: Import the Plugin
```dart
import 'package:in_app_subscription_bundle/in_app_subscription_bundle.dart';
```

### Step 2: Provide the BLoC
Wrap your app or screen with `BlocProvider` to provide access to `SubsBlocNew`:

```dart
Widget build(BuildContext context) {
  return BlocProvider(
    create: (context) => SubsBlocNew(
      context: context,
      checkSubscriptionApi: "",
      subscriptionProductIds: ["monthly_plan", "yearly_plan"],
    ),
    child: const _ProductsBody(),
  );
}
```

### Step 3: Build the UI with BLoC
Use `BlocBuilder` and `BlocListener` to react to state changes:

```dart
class _ProductsBody extends StatefulWidget {
  const _ProductsBody({Key? key}) : super(key: key);

  @override
  State<_ProductsBody> createState() => _ProductsBodyState();
}

class _ProductsBodyState extends State<_ProductsBody> {
  @override
  void initState() {
    super.initState();
    // Dispatch here, when Bloc is ready and context is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubsBlocNew>().add(
        SubscriptionInitEvent(context: context),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SubsBlocNew>().state;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text("Products"),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Column(
            children: [

              ListWidget(
                itemCount: state.products.length,
                itemBuilder: (p0, p1) {
                  final product = state.products[p1];

                  // Skip rendering if it's free
                  if (product.rawPrice == 0.0) {
                    return const SizedBox.shrink();
                  }
                  return  GestureDetector(
                    onTap: () {
                      context.read<SubsBlocNew>().add(
                        ChangeSelectedItemEvent(p1),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: state.products[state.selectedItem].id==product.id?
                        Colors.green : Colors.lightGreenAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(product.title),
                        subtitle: Text(product.description),
                        trailing: Text(product.price),
                      ),
                    ),
                  );
                },
              ),
              CustomButton(
                width: 50.sw,
                text: "Subscribe",
                onTap:() {
                  context.read<SubsBlocNew>().add(
                    BuyProductEvent(context: context, restore: false),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
```