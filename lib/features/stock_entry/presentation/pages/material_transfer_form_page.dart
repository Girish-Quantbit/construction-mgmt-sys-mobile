import 'package:cms/core/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:cms/core/theme/app_colors.dart';

class _CustomMetaService extends MetaService {
  _CustomMetaService(super.client, super.database);

  @override
  Future<DocTypeMeta> getMeta(
    String doctype, {
    bool forceRefresh = false,
  }) async {
    final meta = await super.getMeta(doctype, forceRefresh: forceRefresh);
    if (doctype == 'Stock Entry Detail') {
      final allowedFields = [
        'item_code',
        'item_name',
        'description',
        'qty',
        'uom',
        'stock_uom',
        'conversion_factor',
        's_warehouse',
        't_warehouse',
        'basic_rate',
        'amount',
        'project',
        'cost_center',
      ];
      final fetchFromMappings = {
        'item_name': 'item_code.item_name',
        'description': 'item_code.description',
        'uom': 'item_code.stock_uom',
        'stock_uom': 'item_code.stock_uom',
        'basic_rate': 'item_code.valuation_rate',
      };

      final enrichedFields = meta.fields.map((f) {
        final hasCustomFetch = fetchFromMappings.containsKey(f.fieldname);
        return DocField(
          fieldname: f.fieldname,
          fieldtype: f.fieldtype,
          label: f.label,
          reqd: f.reqd,
          readOnly: f.readOnly,
          hidden: f.hidden,
          options: f.options,
          dependsOn: f.dependsOn,
          mandatoryDependsOn: f.mandatoryDependsOn,
          readOnlyDependsOn: f.readOnlyDependsOn,
          linkFilters: f.linkFilters,
          fetchFrom: hasCustomFetch
              ? fetchFromMappings[f.fieldname]
              : f.fetchFrom,
          section: f.section,
          defaultValue: f.defaultValue,
          description: f.description,
          placeholder: f.placeholder,
          precision: f.precision,
          length: f.length,
          idx: f.idx,
          inListView: f.inListView,
          allowMultiple: f.allowMultiple,
        );
      }).toList();

      enrichedFields.retainWhere((f) => allowedFields.contains(f.fieldname));
      enrichedFields.sort((a, b) {
        final indexA = allowedFields.indexOf(a.fieldname ?? '');
        final indexB = allowedFields.indexOf(b.fieldname ?? '');
        return indexA.compareTo(indexB);
      });

      return DocTypeMeta(
        name: meta.name,
        label: meta.label,
        fields: enrichedFields,
        isTable: meta.isTable,
        metaData: meta.metaData,
        titleField: meta.titleField,
        sortField: meta.sortField,
        sortOrder: meta.sortOrder,
      );
    }
    return meta;
  }
}

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
  late MetaService _customMetaService;

  @override
  void initState() {
    super.initState();
    _fetchMeta();
  }

  Future<void> _fetchMeta() async {
    try {
      final sdk = sl<FrappeSDK>();
      _customMetaService = _CustomMetaService(sdk.api, sdk.database);
      final meta = await _customMetaService.getMeta('Stock Entry', forceRefresh: true);

      final allowedFields = {
        'naming_series',
        'stock_entry_type',
        'posting_date',
        'posting_time',
        if (widget.stockEntryType == 'Material Transfer') ...[
          'add_to_transit',
          'apply_putaway_rule',
        ],
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FormScreen(
        meta: _meta!,
        document: _document,
        repository: sdk.repository,
        api: sdk.api,
        metaService: _customMetaService,
        linkOptionService: sdk.linkOptions,
        initialData: widget.stockEntryType != null
            ? {'stock_entry_type': widget.stockEntryType}
            : null,
        onSaveSuccess: () {
          Navigator.pop(context, true);
        },
      ),
    );
  }
}
