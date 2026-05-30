import 'package:cms/core/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:cms/core/theme/app_colors.dart';

class MaterialTransferFormPage extends StatefulWidget {
  final String? stockEntryType;
  final String? entryName;

  const MaterialTransferFormPage({super.key, this.stockEntryType, this.entryName});

  @override
  State<MaterialTransferFormPage> createState() =>
      _MaterialTransferFormPageState();
}

class _MaterialTransferFormPageState extends State<MaterialTransferFormPage> {
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
      final meta = await sdk.meta.getMeta('Stock Entry', forceRefresh: true);

      // Filter fields as per requirement
      final allowedFields = {
        'naming_series',
        'stock_entry_type',
        'posting_date',
        'posting_time',
        'add_to_transit',
        'apply_putaway_rule',
        'from_warehouse',
        'to_warehouse',
        'scan_barcode',
        'items',
        'additional_costs',
        'project',
        'cost_center',
        'is_opening',
        'remarks',
      };

      meta.fields.retainWhere(
        (field) => allowedFields.contains(field.fieldname),
      );

      // Make stock_entry_type unchangeable by removing it from the form fields
      // it will still be sent as it's in initialData
      if (widget.stockEntryType != null) {
        meta.fields.removeWhere(
          (field) => field.fieldname == 'stock_entry_type',
        );
      }

      Document? doc;
      if (widget.entryName != null) {
        try {
          final serverData = await sdk.api.doctype.getByName('Stock Entry', widget.entryName!);
          doc = await sdk.repository.saveServerDocument(
            doctype: 'Stock Entry',
            serverId: widget.entryName!,
            data: serverData,
          );
        } catch (_) {
          doc = await sdk.repository.getDocumentByServerId(widget.entryName!, 'Stock Entry');
        }
      }

      setState(() {
        _meta = meta;
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

    final appBarTitle = widget.stockEntryType != null
        ? 'New ${widget.stockEntryType}'
        : 'New Stock Entry';

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(title: appBarTitle, showSearch: false),
        body: Center(child: Text('Error loading form: $_error')),
      );
    }

    final sdk = sl<FrappeSDK>();

    return FormScreen(
      meta: _meta!,
      document: _document,
      repository: sdk.repository,
      api: sdk.api,
      metaService: sdk.meta,
      linkOptionService: sdk.linkOptions,
      initialData: widget.stockEntryType != null
          ? {'stock_entry_type': widget.stockEntryType}
          : null,
      onSaveSuccess: () {
        Navigator.pop(context, true);
      },
    );
  }
}
