import 'package:flutter/material.dart';
import 'package:app_prompter/app_prompter.dart';
import 'package:app_prompter/src/core.dart';
import 'package:app_prompter/src/style.dart';

/// A simple dialog button click listener.
typedef AppPrompterDialogButtonClickListener = bool Function(
    AppPrompterDialogButton button);

/// Validates a state when called in a function.
typedef Validator = bool Function();

/// Allows to change the default dialog content.
typedef DialogContentBuilder = Widget Function(
    BuildContext context, Widget defaultContent);

/// Allows to dynamically build actions.
typedef DialogActionsBuilder = List<Widget> Function(BuildContext context);

/// Allows to dynamically build actions according to the specified rating.
typedef StarDialogActionsBuilder = List<Widget> Function(
    BuildContext context, double stars);

/// The Android App Prompter dialog.
class AppPrompterDialog extends StatelessWidget {
  /// The App Prompter instance.
  final AppPrompter appPrompter;

  /// The dialog's title.
  final String title;

  /// The dialog's message.
  final String message;

  /// The content builder.
  final DialogContentBuilder contentBuilder;

  /// The actions builder.
  final DialogActionsBuilder actionsBuilder;

  /// The dialog's action button.
  final String actionButton;

  /// The dialog's no button.
  final String noButton;

  /// The dialog's later button.
  final String laterButton;

  /// The buttons listener.
  final AppPrompterDialogButtonClickListener listener;

  /// The dialog's style.
  final DialogStyle dialogStyle;

  /// Creates a new App Prompter dialog.
  const AppPrompterDialog(
    this.appPrompter, {
    @required this.title,
    @required this.message,
    @required this.contentBuilder,
    this.actionsBuilder,
    @required this.actionButton,
    @required this.noButton,
    @required this.laterButton,
    this.listener,
    @required this.dialogStyle,
  })  : assert(title != null),
        assert(message != null),
        assert(actionButton != null),
        assert(noButton != null),
        assert(laterButton != null),
        assert(dialogStyle != null);

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      child: Padding(
        padding: dialogStyle.messagePadding,
        child: Text(
          message,
          style: dialogStyle.messageStyle,
          textAlign: dialogStyle.messageAlign,
        ),
      ),
    );

    return AlertDialog(
      title: Padding(
        padding: dialogStyle.titlePadding,
        child: Text(
          title,
          style: dialogStyle.titleStyle,
          textAlign: dialogStyle.titleAlign,
        ),
      ),
      content: contentBuilder(context, content),
      contentPadding: dialogStyle.contentPadding,
      shape: dialogStyle.dialogShape,
      actions: (actionsBuilder ?? _defaultActionsBuilder)(context),
    );
  }

  List<Widget> _defaultActionsBuilder(BuildContext context) => [
        AppPrompterRateButton(
          appPrompter,
          text: actionButton,
          validator: () =>
              listener == null || listener(AppPrompterDialogButton.action),
        ),
        AppPrompterLaterButton(
          appPrompter,
          text: laterButton,
          validator: () =>
              listener == null || listener(AppPrompterDialogButton.later),
        ),
        AppPrompterNoButton(
          appPrompter,
          text: noButton,
          validator: () =>
              listener == null || listener(AppPrompterDialogButton.no),
        ),
      ];
}

/// The App Prompter star dialog.
class AppPrompterStarDialog extends StatefulWidget {
  /// The App Prompter instance.
  final AppPrompter appPrompter;

  /// The dialog's title.
  final String title;

  /// The dialog's message.
  final String message;

  /// The content builder.
  final DialogContentBuilder contentBuilder;

  /// The rating changed callback.
  final StarDialogActionsBuilder actionsBuilder;

  /// The dialog's style.
  final DialogStyle dialogStyle;

  /// The smooth star rating style.
  final StarRatingOptions starRatingOptions;

  /// Creates a new App Prompter star dialog.
  const AppPrompterStarDialog(
    this.appPrompter, {
    @required this.title,
    @required this.message,
    @required this.contentBuilder,
    this.actionsBuilder,
    @required this.dialogStyle,
    @required this.starRatingOptions,
  })  : assert(title != null),
        assert(message != null),
        assert(dialogStyle != null),
        assert(starRatingOptions != null);

  @override
  State<StatefulWidget> createState() => AppPrompterStarDialogState();

  /// Used when there is no onRatingChanged callback.
  List<Widget> _defaultOnRatingChanged(BuildContext context, double rating) => [
        AppPrompterRateButton(
          appPrompter,
          text: 'RATE',
        ),
        AppPrompterLaterButton(
          appPrompter,
          text: 'MAYBE LATER',
        ),
        AppPrompterNoButton(
          appPrompter,
          text: 'NO',
        ),
      ];
}

/// The App Prompter star dialog state.
class AppPrompterStarDialogState extends State<AppPrompterStarDialog> {
  /// The current rating.
  double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.starRatingOptions.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: widget.dialogStyle.messagePadding,
            child: Text(
              widget.message,
              style: widget.dialogStyle.messageStyle,
              textAlign: widget.dialogStyle.messageAlign,
            ),
          ),
        ],
      ),
    );

    return AlertDialog(
      title: Padding(
        padding: widget.dialogStyle.titlePadding,
        child: Text(
          widget.title,
          style: widget.dialogStyle.titleStyle,
          textAlign: widget.dialogStyle.titleAlign,
        ),
      ),
      content: widget.contentBuilder(context, content),
      contentPadding: widget.dialogStyle.contentPadding,
      shape: widget.dialogStyle.dialogShape,
      actions: (widget.actionsBuilder ?? widget._defaultOnRatingChanged)(
          context, _currentRating),
    );
  }
}

/// A App Prompter dialog button with a text, a validator and a callback.
abstract class _AppPrompterDialogButton extends StatelessWidget {
  /// The App Prompter instance.
  final AppPrompter appPrompter;

  /// The button text.
  final String text;

  /// The state validator (whether this button should have an effect).
  final Validator validator;

  /// Called when the action has been executed.
  final VoidCallback callback;

  /// Creates a new App Prompter button widget instance.
  const _AppPrompterDialogButton(
    this.appPrompter, {
    @required this.text,
    this.validator = _validatorTrue,
    this.callback,
  }) : assert(text != null);

  @override
  Widget build(BuildContext context) => FlatButton(
        child: Text(text),
        onPressed: () async {
          if (validator != null && !validator()) {
            return;
          }

          await onButtonClicked(context);
          if (callback != null) {
            callback();
          }
        },
      );

  /// Triggered when a button has been clicked.
  Future<void> onButtonClicked(BuildContext context);

  /// A validator that always return true.
  static bool _validatorTrue() => true;
}

/// The App Prompter "action" button widget.
class AppPrompterRateButton extends _AppPrompterDialogButton {
  /// Creates a new App Prompter "action" button widget instance.
  const AppPrompterRateButton(
    AppPrompter appPrompter, {
    @required String text,
    Validator validator,
    VoidCallback callback,
  }) : super(
          appPrompter,
          text: text,
          validator: validator,
          callback: callback,
        );

  @override
  Future<void> onButtonClicked(BuildContext context) async {
    await appPrompter.callEvent(AppPrompterEventType.actionButtonPressed);
    Navigator.pop<AppPrompterDialogButton>(context, AppPrompterDialogButton.action);
    //await appPrompter.launchStore();
  }
}

/// The App Prompter "later" button widget.
class AppPrompterLaterButton extends _AppPrompterDialogButton {
  /// Creates a new App Prompter "later" button widget instance.
  const AppPrompterLaterButton(
    AppPrompter appPrompter, {
    @required String text,
    Validator validator,
    VoidCallback callback,
  }) : super(
          appPrompter,
          text: text,
          validator: validator,
          callback: callback,
        );

  @override
  Future<void> onButtonClicked(BuildContext context) async {
    await appPrompter.callEvent(AppPrompterEventType.laterButtonPressed);
    Navigator.pop<AppPrompterDialogButton>(context, AppPrompterDialogButton.later);
  }
}

/// The App Prompter "no" button widget.
class AppPrompterNoButton extends _AppPrompterDialogButton {
  /// Creates a new App Prompter "no" button widget instance.
  const AppPrompterNoButton(
    AppPrompter appPrompter, {
    @required String text,
    Validator validator,
    VoidCallback callback,
  }) : super(
          appPrompter,
          text: text,
          validator: validator,
          callback: callback,
        );

  @override
  Future<void> onButtonClicked(BuildContext context) async {
    await appPrompter.callEvent(AppPrompterEventType.noButtonPressed);
    Navigator.pop<AppPrompterDialogButton>(context, AppPrompterDialogButton.no);
  }
}

/// Represents a App Prompter dialog button.
enum AppPrompterDialogButton {
  /// The "action" button.
  action,

  /// The "later" button.
  later,

  /// The "no" button.
  no,
}
