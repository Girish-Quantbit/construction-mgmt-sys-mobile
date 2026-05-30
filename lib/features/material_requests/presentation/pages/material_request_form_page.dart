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
    if (doctype == 'Material Request Item') {
      final allowedFields = [
        'item_code',
        'schedule_date',
        'item_name',
        'description',
        'gst_hsn_code',
        'qty',
        'uom',
        'stock_uom',
        'conversion_factor',
        'warehouse',
        'rate',
        'expense_account',
        'wip_composite_asset',
        'manufacturer',
        'bom_no',
        'project',
        'cost_center',
        'page_break',
      ];
      final fetchFromMappings = {
        'item_name': 'item_code.item_name',
        'description': 'item_code.description',
        'uom': 'item_code.stock_uom',
        'stock_uom': 'item_code.stock_uom',
        'conversion_factor': 'item_code.conversion_factor',
        'rate': 'item_code.valuation_rate',
        'amount': 'item_code.valuation_rate',
        'qty': 'item_code.qty',
        'expense_account': 'item_code.expense_account',
        'cost_center': 'item_code.cost_center',
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

class MaterialRequestFormPage extends StatefulWidget {
  final String? requestName;
  const MaterialRequestFormPage({super.key, this.requestName});

  @override
  State<MaterialRequestFormPage> createState() =>
      _MaterialRequestFormPageState();
}

class _MaterialRequestFormPageState extends State<MaterialRequestFormPage> {
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
      final meta = await _customMetaService.getMeta(
        'Material Request',
        forceRefresh: true,
      );

      final generalFields = [
        'naming_series',
        'transaction_date',
        'material_request_type',
        'schedule_date',
        'buying_price_list',
        'scan_barcode',
        'set_warehouse',
        'items',
      ];

      meta.fields.retainWhere((f) => generalFields.contains(f.fieldname));
      meta.fields.sort((a, b) {
        final indexA = generalFields.indexOf(a.fieldname ?? '');
        final indexB = generalFields.indexOf(b.fieldname ?? '');
        return indexA.compareTo(indexB);
      });

      Document? doc;
      if (widget.requestName != null) {
        try {
          final serverData = await sdk.api.doctype.getByName('Material Request', widget.requestName!);
          doc = await sdk.repository.saveServerDocument(
            doctype: 'Material Request',
            serverId: widget.requestName!,
            data: serverData,
          );
        } catch (_) {
          doc = await sdk.repository.getDocumentByServerId(widget.requestName!, 'Material Request');
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
        onSaveSuccess: () {
          Navigator.pop(context, true);
        },
      ),
    );
  }
}
