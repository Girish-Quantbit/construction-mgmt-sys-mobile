// import 'package:cms/core/widgets/custom_app_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
// import 'package:cms/core/di/injection_container.dart';
// import 'package:cms/core/theme/app_colors.dart';

// class ProjectFormPage extends StatefulWidget {
//   const ProjectFormPage({super.key});

//   @override
//   State<ProjectFormPage> createState() => _ProjectFormPageState();
// }

// class _ProjectFormPageState extends State<ProjectFormPage> {
//   bool _isLoading = true;
//   String? _error;
//   DocTypeMeta? _meta;

//   @override
//   void initState() {
//     super.initState();
//     _fetchMeta();
//   }

//   Future<void> _fetchMeta() async {
//     try {
//       final sdk = sl<FrappeSDK>();
//       final meta = await sdk.meta.getMeta('Project', forceRefresh: true);
//       setState(() {
//         _meta = meta;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         backgroundColor: AppColors.background,
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_error != null) {
//       return Scaffold(
//         backgroundColor: AppColors.background,
//         appBar: const CustomAppBar(title: 'New Project', showSearch: false),
//         body: Center(child: Text('Error loading form: $_error')),
//       );
//     }

//     final sdk = sl<FrappeSDK>();

//     return FormScreen(
//       meta: _meta!,
//       repository: sdk.repository,
//       api: sdk.api,
//       metaService: sdk.meta,
//       linkOptionService: sdk.linkOptions,
//       translate: (String text) {
//         // WORKAROUND: Prevent RenderFlex overflow in SDK for long field labels
//         if (text == 'Total Consumed Material Cost (via Stock Entry)') {
//           return 'Total Consumed Material\nCost (via Stock Entry)';
//         }
//         if (text.length > 35 && !text.contains('\n')) {
//           // General fallback: insert a newline near the middle
//           final middle = text.length ~/ 2;
//           final spaceIndex = text.indexOf(' ', middle);
//           if (spaceIndex != -1) {
//             return '${text.substring(0, spaceIndex)}\n${text.substring(spaceIndex + 1)}';
//           }
//         }
//         return text;
//       },
//       onSaveSuccess: () {
//         Navigator.pop(
//           context,
//           true,
//         ); // Return true to indicate success and trigger refresh
//       },
//     );
//   }
// }
