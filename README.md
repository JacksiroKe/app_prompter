# App Prompter

This plugin prompts users to a custom action on your app if custom conditions like install time and number of launches are met.

_App Prompter_ is really inspired by [Rate my App](https://github.com/Skyost/RateMyApp)

## How to use

### Installation

If you're building your app for Android, be sure that your app is upgraded to the [Android Embedding V2](https://github.com/flutter/flutter/wiki/Upgrading-pre-1.12-Android-projects)
(if you've created your project with a Flutter version ≥ 1.12, you should be okay).

On iOS, if you want to target a version before _10.3_, add this in your `Info.plist` :

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>itms</string>
</array>
```

By the way, it's important to note that your bundle identifier (in your `Info.plist`) must match the App ID on iTunes Connect and the package identifier (in your `build.gradle`) must match your App ID on Google Play.

If for any reason it doesn't match please go to the _[Using custom identifiers](#using-custom-identifiers)_ section.

### How it works

_App prompter_ default constructor takes two main parameters (see _[Example](#example)_ for more info) :

* `minDays` Minimum elapsed days since the first app launch.
* `minLaunches` Minimum app launches count.

If everything above is verified, the method `shouldOpenDialog` will return `true` (`false` otherwise).
Then you should call `showPromptDialog` which is going to show a native rating dialog on iOS ≥ _10.3_ and a custom rating prompt dialog on Android (and on older iOS versions).

## Screenshots

<details>
    <!--<summary>On Android</summary>-->
    <img src="https://github.com/Jacksiroke/app_prompter/raw/master/images/android.jpg" height="500">
    <br><em><code>showPromptDialog</code> method with <code>ignoreNative</code> set to <code>true</code>.</em>
</details>

<!--<details>
    <summary>On iOS</summary>
    <img src="https://github.com/Jacksiroke/app_prompter/raw/master/images/ios_10_3.png" height="500">
    <br><em><code>showPromptDialog</code> and <code>showStarPrompterDialog</code> methods with <code>ignoreNative</code> set to <code>false</code>.</em>
</details>-->

## Using it in your code

### Code snippets

```dart
// In this snippet, I'm giving a value to all parameters.
// Please note that not all are required (those that are required are marked with the @required annotation).

AppPrompter appPrompter = AppPrompter(
  preferencesPrefix: 'appPrompter_',
  minDays: 0,
  minLaunches: 3,
  remindDays: 2,
  remindLaunches: 3
);

appPrompter.init().then((_) {
  if (appPrompter.shouldOpenDialog) {
    appPrompter.showPromptDialog(
      context,
      title: 'Just a Minute', // The dialog title.
      message: 'Since this app is ad free would you mind donate to support its development', // The dialog message.
      actionButton: 'DONATE', // The dialog "action" button text.
      noButton: 'NO THANKS', // The dialog "no" button text.
      laterButton: 'MAYBE LATER', // The dialog "later" button text.
      listener: (button) { // The button click listener (useful if you want to cancel the click event).
        switch(button) {
          case AppPrompterDialogButton.action:
            print('Clicked on "Donate".');
            break;
          case AppPrompterDialogButton.later:
            print('Clicked on "Later".');
            break;
          case AppPrompterDialogButton.no:
            print('Clicked on "No".');
            break;
        }
        
        return true; // Return false if you want to cancel the click event.
      },
      dialogStyle: DialogStyle(), // Custom dialog styles.
      onDismissed: () => appPrompter.callEvent(AppPrompterEventType.laterButtonPressed),
    );
    
  }
});
```

### Minimal Example

Below is the minimal code example. This will be for the basic minimal working of this plugin.
The below will launch a simple message popup after the defined minimal days/minimal launches along with the default buttons :
_Prompter_, _Maybe later_ and _Cancel_, with their default behavior.

Place this in your main widget state :

```dart
AppPrompter appPrompter = AppPrompter(
  preferencesPrefix: 'appPrompter_',
  minDays: 0, // Show simple popup on first day of install.
  minLaunches: 5, // Show simple popup after 5 launches of app after minDays is passed.
);

@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await appPrompter.init();
    if (mounted && appPrompter.shouldOpenDialog) {  
      appPrompter.showPromptDialog(context);
    }
  });
}
```

If you want a more complete example, please check [this one](https://github.com/Jacksiroke/app_prompter/tree/master/example/) on Github.    
You can also follow [the tutorial of Marcus Ng](https://youtu.be/gOiaSwp984s) on YouTube
(for a replacement of `doNotOpenAgain`, see [Broadcasting events](#broadcasting-events)).

## Advanced

### Where to initialize _App Prompter_

You should be careful on where you initialize _App Prompter_ in your project.
But thankfully, there's a widget that helps you getting through all of this without any trouble : `AppPrompterBuilder`.
Here's an example :

```dart
// The builder should be initialized exactly one time during the app lifecycle.
// So place it where you want but it should respect that condition.

AppPrompterBuilder(
  builder: (context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: const Text('App prompter !'),
      ),
      body: Center(child: Text('This is my beautiful app !')),
    ),
  ),
  onInitialized: (context, appPrompter) {
    // Called when App prompter has been initialized.
    // See the example project on Github for more info.
  },
);
```

You can totally choose to not use it and to initialize _App prompter_ in your `main()` method. This is up to you !

### Using custom conditions

A condition is something required to be met in order for the `shouldOpenDialog` method to return `true`.
_App prompter_ comes with three default conditions :

* `MinimumDaysCondition` Allows to set a minimum elapsed days since the first app launch before showing the dialog.
* `MinimumAppLaunchesCondition` Allows to set a minimum app launches count since the first app launch before showing the dialog.
* `DoNotOpenAgainCondition` Allows to prevent the dialog from being opened (when the user clicks on the _No_ button for example).

You can easily create your custom conditions ! All you have to do is to extend the `Condition` class. There are five methods to override :

* `readFromPreferences` You should read your condition values from the provided shared preferences here.
* `saveToPreferences` You should save your condition values to the provided shared preferences here.
* `reset` You should reset your condition values here.
* `isMet` Whether this condition is met.
* `onEventOccurred` When an event occurs in the plugin lifecycle. This is usually here that you can update your condition values.
Please note that you're not obligated to override this one (although this is recommended).

You can have an easy example of it by checking the source code of [`DoNotOpenAgainCondition`](https://github.com/Jacksiroke/app_prompter/tree/master/lib/src/conditions.dart#L169).

Then you can add your custom condition to _App prompter_ by using the constructor `customConditions` (or by calling `appPrompter.conditions.add` before initialization).

### Broadcasting events

As said in the previous section, the `shouldOpenDialog` method depends on conditions.

For example, when you click on the _No_ button,
[this event](https://github.com/Jacksiroke/app_prompter/tree/master/lib/src/core.dart#L237) will be triggered
and the condition `DoNotOpenAgainCondition` will react to it and will stop being met and thus the `shouldOpenDialog` will return `false`.

You may want to broadcast events in order to mimic the behaviour of the _No_ button for example.
This can be done either by using the `AppPrompterNoButton` or you can directly call `callEvent` from your current _AppPrompter_ instance in your button `onTap` callback.

Here are what events default conditions are listening to :

* `MinimumDaysCondition` : _Later_ button press.
* `MinimumAppLaunchesCondition` : _App prompter_ initialization, _Later_ button press.
* `DoNotOpenAgainCondition` : _Prompter_ button press, _No_ button press.

For example, starting from version 0.5.0, the getter/setter `doNotOpenAgain` has been removed.
You must trigger the `DoNotOpenAgainCondition` either by calling a _Prompter_ button press event or a _No_ button press event (see [Example on Github](https://github.com/Jacksiroke/app_prompter/blob/master/example/lib/content.dart#L141)).

## Contributions

You have a lot of options to contribute to this project ! You can :

* [Fork it](https://github.com/Jacksiroke/app_prompter/fork) on Github.
* [Submit](https://github.com/Jacksiroke/app_prompter/issues/new/choose) a feature request or a bug report.
* [Donate](https://paypal.me/Jacksiro) to the developer.

## Dependencies

This library depends on some other libraries :

* [shared_preferences](https://pub.dev/packages/shared_preferences)
