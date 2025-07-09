import 'package:lottie/lottie.dart';
import 'package:fluent_ui/fluent_ui.dart';


class HomePage extends StatelessWidget {
  final VoidCallback onNext;
  const HomePage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(title: Text('Access Review Process'),),

      content: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          color: Colors.white,
        ),
        child: Row(
          children: [
            // Left Side: Explanation
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child:ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Access Review Process Explanation',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'An access review process is a structured approach organizations use to periodically verify that users have appropriate access rights to systems, applications, and data. This helps ensure compliance, reduce security risks, and maintain the principle of least privilege.',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Key Steps in the Access Review Process',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildStep(
                          'Initiation',
                          [
                            'Determine the scope (systems, users, data).',
                            'Schedule the review frequency (quarterly, annually, etc.).',
                          ],
                        ),
                        _buildStep(
                          'Data Collection',
                          [
                            'Gather current access rights from systems.',
                            'Compile a list of users and their permissions.',
                          ],
                        ),
                        _buildStep(
                          'Review & Validation',
                          [
                            'Reviewers (e.g., managers, system owners) assess if access is appropriate.',
                            'Identify excessive, outdated, or unnecessary permissions.',
                          ],
                        ),
                        _buildStep(
                          'Remediation',
                          [
                            'Remove or adjust inappropriate access.',
                            'Document changes and reasons for removal.',
                          ],
                        ),
                        _buildStep(
                          'Certification & Reporting',
                          [
                            'Certify that the review is complete.',
                            'Generate reports for compliance and audit purposes.',
                          ],
                        ),
                        _buildStep(
                          'Continuous Improvement',
                          [
                            'Analyze findings for recurring issues.',
                            'Update policies or processes as needed.',
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Right Side: Lottie Animation
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    flex:10,
                    child: Lottie.asset('assets/AccessReview.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Button(
                    child: const Text('NEXT',),
                    onPressed: onNext,
                  ),
                  SizedBox(height: 70,)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String title, List<String> bullets) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ...bullets.map(
                (b) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(child: Text(b, style: const TextStyle(fontSize: 16))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
