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
BlocProvider(
  create: (context) => SubsBlocNew(
    context: context,
    checkSubscriptionApi: 'YOUR_CHECK_SUBSCRIPTION_API_URL',
    checkSubscriptonApiRequestType: RequestType.get,
    saveSubscriptionApiUrl: 'YOUR_SAVE_SUBSCRIPTION_API_URL',
    subscriptionProductIds: ['product_1', 'product_2'],
  )..add(SubscriptionInitEvent(context: context)),
  child: MaterialApp(
    home: SubscriptionPage(),
  ),
);
```

### Step 3: Build the UI with BLoC
Use `BlocBuilder` and `BlocListener` to react to state changes:

```dart
class SubscriptionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('In-App Subscription')),
      body: BlocListener<SubsBlocNew, SubscriptionState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          }
        },
        child: BlocBuilder<SubsBlocNew, SubscriptionState>(
          builder: (context, state) {
            if (state.loader == true) {
              return Center(child: CircularProgressIndicator());
            }

            if (state.isSubscribed == true) {
              return Center(child: Text('You are successfully subscribed!'));
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Current Status: Not Subscribed', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 20),
                  if (state.products.isNotEmpty)
                    ElevatedButton(
                      onPressed: () {
                        BlocProvider.of<SubsBlocNew>(context).add(
                          BuyProductEvent(context: context, selectedItem: state.selectedItem),
                        );
                      },
                      child: Text('Buy ${state.products[state.selectedItem].title}'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```