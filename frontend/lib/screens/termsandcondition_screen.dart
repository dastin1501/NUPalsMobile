import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';

class TermsConditionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'), // Path to background image
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo.png', // Path to logo image
                        height: 100,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Terms and Conditions',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: nuBlue,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '1. Why Do We Need Your Information?\n'
                        'We collect certain personal data to deliver a customized and interactive experience, ensuring that your time in our app is engaging and tailored to your preferences. This data is essential for various purposes, including:\n\n'
                        '    • Account Creation and Management: Necessary information for setting up your account, including login credentials.\n'
                        '    • Profile Building: Data to connect you with users who share similar interests.\n'
                        '    • Feature Enhancement: Improving in-app functionalities like surveys and content recommendations.\n'
                        '    • User Engagement: Analyzing how you interact with the app to refine your experience.\n\n'
                        '2. What Information Do We Collect?\n'
                        'The information we collect encompasses various aspects of your user experience, providing us with the necessary insights to enhance our services. This includes:\n\n'
                        '    • Account Information: Basic details such as your name, email, and username.\n'
                        '    • Profile Data: Information provided for interest matching, including demographic details (age, year level, college).\n'
                        '    • Interactions: Responses from surveys, custom and categorized interests, and in-app communication.\n'
                        '    • Usage Data: Information on app interactions (time spent, features accessed).\n'
                        'Note: We limit data collection to what is essential for delivering our services.\n\n'
                        '3. How Do We Use Your Information?\n'
                        'Your data is utilized solely within the app to create a seamless and personalized experience, allowing us to understand your needs better and improve our offerings. We use your information for:\n\n'
                        '    • Profile Management: Creating and managing your profile for personalized interactions.\n'
                        '    • User Matching: Connecting you with users who have similar interests.\n'
                        '    • Survey Facilitation: Conducting surveys and analyzing responses.\n'
                        '    • Content Recommendations: Providing tailored insights and community engagement opportunities.\n'
                        'We do not sell or share your information with third parties outside our services without your explicit consent.\n\n'
                        '4. Data Protection and Security Measures\n'
                        'We take your data security seriously and implement comprehensive measures to protect your information from unauthorized access and breaches. Our approach includes:\n\n'
                        '    • Encryption: Utilizing secure, encrypted connections and robust storage solutions.\n'
                        '    • Password Protection: Storing passwords securely using strong encryption protocols.\n'
                        '    • Security Audits: Conducting regular evaluations and updates to ensure data protection.\n'
                        '    • Access Control: Limiting access to sensitive data to authorized personnel only.\n\n'
                        '5. When We May Access Your Chats or Data\n'
                        'Your chat data is treated with the utmost confidentiality, and we access it only under specific circumstances that warrant such actions. These circumstances include:\n\n'
                        '    • Community Safety: Enforcing app guidelines or reviewing reports of violations.\n'
                        '    • User Support: Assisting with issues reported by users.\n'
                        '    • Legal Obligations: Complying with lawful requests from government authorities.\n'
                        'We prioritize your privacy, ensuring access is granted only when essential.\n\n'
                        '6. Community Guidelines and Conduct\n'
                        'To foster a positive and respectful community environment, users are expected to adhere to certain guidelines. These expectations include:\n\n'
                        '    • Communicate Respectfully: Engage with others in a respectful and honest manner.\n'
                        '    • Protect Privacy: Respect other users’ privacy and refrain from harassment.\n'
                        '    • Appropriate Use: Use the app as intended, avoiding unauthorized access or misuse.\n'
                        'Violations of these guidelines may result in consequences, including account suspension or termination.\n\n'
                        '7. Your Data Privacy Rights\n'
                        'Your rights regarding your personal information are of great importance to us, and we are committed to ensuring that you are empowered and informed about how your data is handled. As a user, you have the right to:\n\n'
                        '    • Access Your Information: Review your data and request corrections if needed.\n'
                        '    • Request Deletion: Ask for your account and personal data to be deleted.\n'
                        '    • Understand Data Use: Gain insight into how your data is used.\n'
                        'We are committed to ensuring your data rights are respected and providing transparency regarding our data practices.\n\n'
                        'By using this app, you acknowledge and agree to these terms, understanding our dedication to your privacy and data security.',
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Go back to the previous screen
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: nuBlue,
                          backgroundColor: nuYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Back to Sign Up'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
