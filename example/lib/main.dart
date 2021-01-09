import 'package:flutter/material.dart';
import 'package:app_prompter/app_prompter.dart';

/// First plugin test method.
void main() {
  WidgetsFlutterBinding.ensureInitialized(); // This allows to use async methods in the main method without any problem.
  runApp(const MyApp());
}

/// The body of the main App Prompter test widget.
class MyApp extends StatefulWidget {
  /// Creates a new App Prompter test app instance.
  const MyApp();

  @override
  State<StatefulWidget> createState() => MyAppState();
}

/// The body state of the main App Prompter test widget.
class MyAppState extends State<MyApp> {
  /// The widget builder.
  WidgetBuilder builder = buildProgressIndicator;

  AppPrompter appPrompter = AppPrompter(
    preferencesPrefix: 'appPrompter_',
    minDays: 0,
    minLaunches: 3,
    remindDays: 2,
    remindLaunches: 3
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('App Prompter Example'),
          ),
          body: AppPrompterBuilder(
            builder: builder,
            onInitialized: (context, appPrompter) {
              appPrompter.conditions.forEach((condition) {
                if (condition is DebuggableCondition) {
                  print(condition.valuesAsString); // We iterate through our list of conditions and we print all debuggable ones.
                }
              });

              print('Are all conditions met ? ' + (appPrompter.shouldOpenDialog ? 'Yes' : 'No'));

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
            },
          ),
        ),
      );

  /// Builds the progress indicator, allowing to wait for App Prompter to initialize.
  static Widget buildProgressIndicator(BuildContext context) => const Center(child: CircularProgressIndicator());
}
