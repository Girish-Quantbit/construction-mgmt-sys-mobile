import 'package:cms/core/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:cms/core/theme/app_colors.dart';

class ManpowerUsageFormPage extends StatefulWidget {
  final String? usageName;
  const ManpowerUsageFormPage({super.key, this.usageName});

  @override
  State<ManpowerUsageFormPage> createState() => _ManpowerUsageFormPageState();
}

class _ManpowerUsageFormPageState extends State<ManpowerUsageFormPage> {
  bool _isLoading = true;
  String? _error;
  DocTypeMeta? _meta;
  Document? _document;

  @override
  void initState() {
    super.initState();
    _fetchMeta();
  }

  Future<void> _fetchMeta() async {
    try {
      final sdk = sl<FrappeSDK>();
      final meta = await sdk.meta.getMeta('Manpower Usage', forceRefresh: true);

      // Filter out amended_from field
      meta.fields.removeWhere((field) => field.fieldname == 'amended_from');

      // Define allowed fields for simplicity or use all fields from meta
      // For now, let's just use all fields but prioritize some
      final priorityFields = [
        'project',
        'site_date',
        'company',
        'manpower_usage',
        'remarks',
      ];

      meta.fields.sort((a, b) {
        final indexA = priorityFields.indexOf(a.fieldname ?? '');
        final indexB = priorityFields.indexOf(b.fieldname ?? '');
        if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;
        return 0;
      });

      final docTypeMeta = DocTypeMeta(
        name: meta.name,
        label: meta.label,
        fields: meta.fields,
        isTable: meta.isTable,
        metaData: Map<String, dynamic>.from(meta.metaData ?? {})..['is_submittable'] = 0,
        titleField: meta.titleField,
        sortField: meta.sortField,
        sortOrder: meta.sortOrder,
      );

      Document? doc;
      if (widget.usageName != null) {
        try {
          final serverData = await sdk.api.doctype.getByName('Manpower Usage', widget.usageName!);
          doc = await sdk.repository.saveServerDocument(
            doctype: 'Manpower Usage',
            serverId: widget.usageName!,
            data: serverData,
          );
        } catch (_) {
          doc = await sdk.repository.getDocumentByServerId(widget.usageName!, 'Manpower Usage');
        }
      }

      setState(() {
        _meta = docTypeMeta;
        _document = doc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    const appBarTitle = 'New Manpower Usage';

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CustomAppBar(title: appBarTitle, showSearch: false),
        body: Center(child: Text('Error loading form: $_error')),
      );
    }

    final sdk = sl<FrappeSDK>();

    return FormScreen(
      meta: _meta!,
      document: _document,
      repository: sdk.repository,
      api: sdk.api,
      syncService: sdk.sync,
      metaService: sdk.meta,
      linkOptionService: sdk.linkOptions,
      onSaveSuccess: () {
        Navigator.pop(context, true);
      },
    );
  }
}
