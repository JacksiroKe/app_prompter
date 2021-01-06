import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pedantic/pedantic.dart';
import 'package:app_prompter/src/conditions.dart';
import 'package:app_prompter/src/dialogs.dart';
import 'package:app_prompter/src/style.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Allows to kindly ask users to action your app if custom conditions are met (eg. install time, number of launches, etc...).
class AppPrompter {
  /// The plugin channel.
  static const MethodChannel _channel = MethodChannel('app_prompter');

  /// Prefix for preferences.
  final String preferencesPrefix;

  /// All conditions that should be met to show the dialog.
  final List<Condition> conditions;

  /// Creates a new App Prompter instance.
  AppPrompter({
    this.preferencesPrefix = 'appPrompter_',
    int minDays,
    int remindDays,
    int minLaunches,
    int remindLaunches,
  })  : conditions = [],
        assert(preferencesPrefix != null) {
    populateWithDefaultConditions(
      minDays: minDays,
      remindDays: remindDays,
      minLaunches: minLaunches,
      remindLaunches: remindLaunches,
    );
  }

  /// Creates a new App Prompter instance with custom conditions.
  const AppPrompter.customConditions({
    this.preferencesPrefix = 'appPrompter_',
    @required this.conditions,
  })  : assert(preferencesPrefix != null),
        assert(conditions != null);

  /// Initializes the plugin (loads base launch date, app launches and whether the dialog should not be opened again).
  Future<void> init() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    conditions.forEach((condition) =>
        condition.readFromPreferences(preferences, preferencesPrefix));
    await callEvent(AppPrompterEventType.initialized);
  }

  /// Saves the plugin current data to the shared preferences.
  Future<void> save() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    for (Condition condition in conditions) {
      await condition.saveToPreferences(preferences, preferencesPrefix);
    }

    await callEvent(AppPrompterEventType.saved);
  }

  /// Resets the plugin data.
  Future<void> reset() async {
    conditions.forEach((condition) => condition.reset());
    await save();
  }

  /// Whether the dialog should be opened.
  bool get shouldOpenDialog =>
      conditions.firstWhere((condition) => !condition.isMet,
          orElse: () => null) ==
      null;

  /// Returns whether native review dialog is supported.
  Future<bool> get isNativeReviewDialogSupported =>
      _channel.invokeMethod<bool>('isNativeDialogSupported');

  /// Launches the native review dialog.
  /// You should check for [isNativeReviewDialogSupported] before running the method.
  Future<void> launchNativeReviewDialog() =>
      _channel.invokeMethod('launchNativeReviewDialog');

  /// Shows the action dialog.
  Future<void> showPromptDialog(
    BuildContext context, {
    String title,
    String message,
    DialogContentBuilder contentBuilder,
    DialogActionsBuilder actionsBuilder,
    String actionButton,
    String noButton,
    String laterButton,
    AppPrompterDialogButtonClickListener listener,
    bool ignoreNativeDialog,
    DialogStyle dialogStyle,
    VoidCallback onDismissed,
  }) async {
    ignoreNativeDialog ??= Platform.isAndroid;
    if (!ignoreNativeDialog && await isNativeReviewDialogSupported) {
      unawaited(callEvent(AppPrompterEventType.iOSRequestReview));
      await launchNativeReviewDialog();
      return;
    }

    unawaited(callEvent(AppPrompterEventType.dialogOpen));
    AppPrompterDialogButton clickedButton =
        await showDialog<AppPrompterDialogButton>(
      context: context,
      builder: (context) => AppPrompterDialog(
        this,
        title: title ?? 'Just a Minute',
        message: message ?? 'Since this app is ad free would you mind donate to support its development',
        contentBuilder:
            contentBuilder ?? ((context, defaultContent) => defaultContent),
        actionsBuilder: actionsBuilder,
        actionButton: actionButton ?? 'YES',
        noButton: noButton ?? 'NO',
        laterButton: laterButton ?? 'LATER',
        listener: listener,
        dialogStyle: dialogStyle ?? const DialogStyle(),
      ),
    );

    if (clickedButton == null && onDismissed != null) {
      onDismissed();
    }
  }

  /// Calls the specified event.
  Future<void> callEvent(AppPrompterEventType eventType) async {
    bool saveSharedPreferences = false;
    conditions.forEach((condition) => saveSharedPreferences =
        condition.onEventOccurred(eventType) || saveSharedPreferences);
    if (saveSharedPreferences) {
      await save();
    }
  }

  /// Adds the default conditions to the current conditions list.
  void populateWithDefaultConditions({
    int minDays,
    int remindDays,
    int minLaunches,
    int remindLaunches,
  }) {
    conditions.add(MinimumDaysCondition(
      minDays: minDays ?? 1,
      remindDays: remindDays ?? 2,
    ));
    conditions.add(MinimumAppLaunchesCondition(
      minLaunches: minLaunches ?? 3,
      remindLaunches: remindLaunches ?? 3,
    ));
    conditions.add(DoNotOpenAgainCondition());
  }
}

/// Represents all events that can occur during the App Prompter lifecycle.
enum AppPrompterEventType {
  /// When App Prompter is fully initialized.
  initialized,

  /// When App Prompter is saved.
  saved,

  /// When a native iOS rating dialog will be opened.
  iOSRequestReview,

  /// When the classic App Prompter dialog will be opened.
  dialogOpen,

  /// When the star dialog will be opened.
  starDialogOpen,

  /// When the action button has been pressed.
  actionButtonPressed,

  /// When the later button has been pressed.
  laterButtonPressed,

  /// When the no button has been pressed.
  noButtonPressed,
}

/// Allows to handle the result of the `launchStore` method.
enum LaunchStoreResult {
  /// The store has been opened, everything is okay.
  storeOpened,

  /// The store has not been opened, but a link to your app has been opened in the user web browser.
  browserOpened,

  /// An error occurred and the method did nothing.
  errorOccurred,
}
