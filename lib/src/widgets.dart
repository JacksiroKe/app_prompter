import 'package:flutter/material.dart';
import 'package:app_prompter/app_prompter.dart';

/// Should be called once App Prompter has been initialized.
typedef AppPrompterInitializedCallback = Function(
    BuildContext context, AppPrompter appPrompter);

/// Allows to build a widget and initialize App Prompter.
class AppPrompterBuilder extends StatefulWidget {
  /// The widget builder.
  final WidgetBuilder builder;

  /// The App Prompter instance.
  final AppPrompter appPrompter;

  /// Called when rate my app has been initialized.
  final AppPrompterInitializedCallback onInitialized;

  /// Creates a new rate my app builder instance.
  const AppPrompterBuilder({
    @required this.builder,
    this.appPrompter,
    this.onInitialized,
  }) : assert(builder != null);

  @override
  State<StatefulWidget> createState() => _AppPrompterBuilderState();
}

/// The rate my app builder state.
class _AppPrompterBuilderState extends State<AppPrompterBuilder> {
  /// The current App Prompter instance.
  AppPrompter appPrompter;

  @override
  void initState() {
    super.initState();

    appPrompter = widget.appPrompter ?? AppPrompter();
    initAppPrompter();
  }

  /// Allows to init rate my app. Should be called one time per app launch.
  Future<void> initAppPrompter() async {
    await appPrompter.init();

    if (widget.onInitialized != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onInitialized(context, appPrompter);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
