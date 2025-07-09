import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'package:wisibility/Pages/csvuploder.dart';
import 'package:wisibility/Pages/home.dart';
import 'package:wisibility/Pages/mapping.dart';
import 'package:wisibility/Pages/result.dart';
import 'package:wisibility/Pages/SOD.dart';

import 'Pages/auth/login.dart';
import 'Pages/certification.dart';
import 'Pages/roleAnalyze.dart';

class NavbarController extends GetxController {
  var selectedIndex = 0.obs;
}

class NavBar extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;
  final VoidCallback? onExpandPane;

  const NavBar({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.onExpandPane,
  });

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  final NavbarController controller = Get.put(NavbarController());
  PaneDisplayMode displayMode = PaneDisplayMode.open;

  Map<String, dynamic>? resultStats;
  Map<String, List<String>>? resultDetails;

  void logout(BuildContext context) async {
    var box = Hive.box('userBox');
    await box.put('isLoggedIn', false);

    Navigator.pushAndRemoveUntil(
      context,
      FluentPageRoute(
        builder: (_) => AuthPage(
          isDarkMode: widget.isDarkMode,
          toggleTheme: widget.onToggleTheme,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationPaneTheme(
      data: NavigationPaneThemeData(
        backgroundColor: Color(0xFF85c48d), // Pane background color
      ),
      child: Obx(
        () => NavigationView(
          appBar: _buildAppBar(),
          pane: _buildNavigationPane(),
        ),
      ),
    );
  }

  void expandPane() {
    setState(() {
      displayMode = PaneDisplayMode.open;
    });
  }

  NavigationAppBar _buildAppBar() {
    return NavigationAppBar(
      leading: Image.asset('assets/wisibility.jpg'),
      height: 60,
      backgroundColor: Colors.black,
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Wisibility',
              style: TextStyle(
                color: Color(0xFFF3F3F3),
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
          ),
          ToggleSwitch(
            checked: widget.isDarkMode,
            onChanged: widget.onToggleTheme,
            content: Text(widget.isDarkMode ? 'Dark' : 'Light'),
          ),
          FilledButton(
            child: const Text('Logout'),
            onPressed: () => logout(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  NavigationPane _buildNavigationPane() {
    return NavigationPane(
      size: const NavigationPaneSize(openWidth: 225, compactWidth: 56),
      selected: controller.selectedIndex.value,
      onChanged: _onPaneChanged,
      displayMode: displayMode,
      items: [
        panWidget(
          title: 'Home',
          icon: const Icon(FluentIcons.home),
          child: HomePage(
            onNext: () {
              controller.selectedIndex.value = 1;
              setState(() {
                displayMode = PaneDisplayMode.open; // Expand the pane
              });
            },
          ),
        ),
        PaneItemExpander(
          tileColor: ButtonState.resolveWith((states) {
            if (states.contains(ButtonStates.hovered)) {
              return const Color(0xFFeec72e); // Hover color
            }
            if (states.contains(ButtonStates.selected)) {
              return const Color(0xFFeec72e); // Selected color
            }
            return null; // Default color
          }),
          title: Text(
            "Access Insights",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),

          icon: const Icon(FluentIcons.comment_previous),
          body: CsvUploader(onResultGenerated: _onResultGenerated),
          items: [
            panWidget(
              title: 'Result',
              icon: const Icon(FluentIcons.show_results),
              child: (resultStats != null && resultDetails != null)
                  ? CsvResultsPage(stats: resultStats!, details: resultDetails!)
                  : const Center(child: Text('No result generated yet.')),
            ),
            panWidget(
              title: 'RoleAnalyze',
              icon: const Icon(FluentIcons.analytics_logo),
              child: RoleAnalyze(),
            ),
            panWidget(
              title: 'SOD',
              icon: const Icon(FluentIcons.accept),
              child: csvTable.isEmpty
                  ? Container()
                  : SodPage(csvTable: csvTable),
            ),
          ],
        ),
        panWidget(
          title: 'Access Certification',
          icon: const Icon(FluentIcons.certificate),
          child: CertificationPage(),
        ),
        panWidget(
          title: 'Data Mapping',
          icon: const Icon(FluentIcons.knowledge_management_app),
          child: DataMapping(),
        ),
        panWidget(
          title: 'SOD & Role Mining',
          icon: const Icon(FluentIcons.rocket),
          child: DataMapping(),
        ),
        panWidget(
          title: 'Access Audit',
          icon: const Icon(FluentIcons.field_not_changed),
          child: (resultStats != null && resultDetails != null)
              ? CsvResultsPage(stats: resultStats!, details: resultDetails!)
              : const Center(child: Text('No result generated yet.')),
        ),
      ],
      footerItems: [
        PaneItemExpander(
          tileColor: ButtonState.resolveWith((states) {
            if (states.contains(ButtonStates.hovered)) {
              return const Color(0xFFeec72e); // Hover color
            }
            if (states.contains(ButtonStates.selected)) {
              return const Color(0xFFeec72e); // Selected color
            }
            return null; // Default color
          }),
          title: Text(
            "Administration",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),

          icon: const Icon(FluentIcons.comment_previous),
          body: CsvUploader(onResultGenerated: _onResultGenerated),
          items: [
            panWidget(
              title: 'Data Upload',
              icon: const Icon(FluentIcons.upload),
              child: CsvUploader(onResultGenerated: _onResultGenerated),
            ),
            panWidget(
              title: 'Configuration',
              icon: const Icon(FluentIcons.settings),
              child: csvTable.isEmpty
                  ? Container()
                  : SodPage(csvTable: csvTable),
            ),
          ],
        ),
      ],
    );
  }

  Widget? _paneTitle(String title) =>
      displayMode == PaneDisplayMode.compact ? null : Text(title);

  Future<void> _onPaneChanged(int index) async {
    // Prevent navigating to Results if no result
    if (index == 2 && (resultStats == null || resultDetails == null)) {
      await showDialog(
        context: context,
        builder: (_) => ContentDialog(
          title: const Text('No Result'),
          content: const Text(
            'Result has not been generated yet. Please upload and analyze a CSV first.',
          ),
          actions: [
            Button(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }
    controller.selectedIndex.value = index;
  }

  void _onResultGenerated(
    Map<String, dynamic> stats,
    Map<String, dynamic> details,
  ) {
    setState(() {
      resultStats = Map<String, dynamic>.from(stats);
      resultDetails = details.map(
        (k, v) => MapEntry(
          k,
          v is List
              ? v
                    .expand(
                      (e) => e is List
                          ? e.map((ee) => ee.toString())
                          : [e.toString()],
                    )
                    .toList()
                    .cast<String>()
              : <String>[],
        ),
      );
    });
    controller.selectedIndex.value = 2;
  }
}

PaneItem panWidget({
  required String title,
  required Widget child,
  required Icon icon, // Add icon parameter
}) {
  return PaneItem(
    tileColor: ButtonState.resolveWith((states) {
      if (states.contains(ButtonStates.hovered)) {
        return const Color(0xFFeec72e); // Hover color
      }
      if (states.contains(ButtonStates.selected)) {
        return const Color(0xFFeec72e); // Selected color
      }
      return null; // Default color
    }),
    icon: icon, // Use the passed icon
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    ),
    body: Container(child: child),
  );
}
