import 'package:flutter/material.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:cms/core/theme/app_colors.dart';

class PurchaseReceiptFormPage extends StatefulWidget {
  final String? receiptName;
  const PurchaseReceiptFormPage({super.key, this.receiptName});

  @override
  State<PurchaseReceiptFormPage> createState() =>
      _PurchaseReceiptFormPageState();
}

class _PurchaseReceiptFormPageState extends State<PurchaseReceiptFormPage> {
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
      final meta = await sdk.meta.getMeta(
        'Purchase Receipt',
        forceRefresh: true,
      );

      final generalFields = [
        'naming_series',
        'posting_date',
        'apply_putaway_rule',
        'is_return',
        'supplier',
        'company',
        'posting_time',
        'is_reverse_charge',
        'supplier_delivery_note',
        'set_posting_time',
        'cost_center',
        'project',
        'currency',
        'buying_price_list',
        'ignore_pricing_rule',
        'scan_barcode',
        'set_warehouse',
        'rejected_warehouse',
        'is_subcontracted',
        'items',
        'total_qty',
        'total',
        'tax_category',
        'shipping_rule',
        'incoterm',
        'taxes_and_charges',
        'taxes',
        'base_taxes_and_charges_added',
        'taxes_and_charges_added',
        'base_taxes_and_charges_deducted',
        'taxes_and_charges_deducted',
        'base_total_taxes_and_charges',
        'total_taxes_and_charges',
        'grand_total',
        'disable_rounded_total',
        'rounding_adjustment',
        'rounded_total',
        'apply_discount_on',
        'additional_discount_percentage',
        'discount_amount',
        'supplied_items',
      ];

      final addressFields = [
        'supplier_address',
        'contact_person',
        'dispatch_address',
        'shipping_address',
        'shipping_address_display',
        'billing_address',
        'billing_address_display',
        'company_gstin',
        'place_of_supply',
      ];

      final termsFields = ['tc_name', 'terms'];

      final transporterFields = [
        'transporter',
        'lr_no',
        'gst_transporter_id',
        'lr_date',
        'vehicle_no',
        'driver',
        'distance',
        'driver_name',
        'mode_of_transport',
        'gst_vehicle_type',
      ];

      final moreFields = [
        'instructions',
        'remarks',
        'is_internal_supplier',
        'status',
      ];

      final allAllowed = [
        ...generalFields,
        ...addressFields,
        ...termsFields,
        ...transporterFields,
        ...moreFields,
      ];

      // Reorganize fields and insert Tab Breaks category-wise
      final existingFields = meta.fields.where((f) => allAllowed.contains(f.fieldname)).toList();
      final fieldsMap = {for (final f in existingFields) f.fieldname: f};

      final customizedFields = <DocField>[];

      // 1. General Tab
      customizedFields.add(DocField(
        fieldname: 'general_tab_break',
        fieldtype: 'Tab Break',
        label: 'General',
      ));
      for (final name in generalFields) {
        if (fieldsMap.containsKey(name)) {
          customizedFields.add(fieldsMap[name]!);
        }
      }

      // 2. Address & Contact Tab
      customizedFields.add(DocField(
        fieldname: 'address_tab_break',
        fieldtype: 'Tab Break',
        label: 'Address & Contact',
      ));
      for (final name in addressFields) {
        if (fieldsMap.containsKey(name)) {
          customizedFields.add(fieldsMap[name]!);
        }
      }

      // 3. Terms & Conditions Tab
      customizedFields.add(DocField(
        fieldname: 'terms_tab_break',
        fieldtype: 'Tab Break',
        label: 'Terms & Conditions',
      ));
      for (final name in termsFields) {
        if (fieldsMap.containsKey(name)) {
          customizedFields.add(fieldsMap[name]!);
        }
      }

      // 4. Transporter Details Tab
      customizedFields.add(DocField(
        fieldname: 'transporter_tab_break',
        fieldtype: 'Tab Break',
        label: 'Transporter Details',
      ));
      for (final name in transporterFields) {
        if (fieldsMap.containsKey(name)) {
          customizedFields.add(fieldsMap[name]!);
        }
      }

      // 5. More Info Tab
      customizedFields.add(DocField(
        fieldname: 'more_tab_break',
        fieldtype: 'Tab Break',
        label: 'More Info',
      ));
      for (final name in moreFields) {
        if (fieldsMap.containsKey(name)) {
          customizedFields.add(fieldsMap[name]!);
        }
      }

      final mappedFields = customizedFields.map((f) {
        String? label = f.label;
        if (label != null) {
          label = label.replaceAll('Company Currency', 'Company');
          label = label.replaceAll('Taxes and Charges', 'Taxes & Charges');
        }
        return DocField(
          fieldname: f.fieldname,
          fieldtype: f.fieldtype,
          label: label,
          reqd: f.reqd,
          readOnly: f.readOnly,
          hidden: f.hidden,
          options: f.options,
          dependsOn: f.dependsOn,
          mandatoryDependsOn: f.mandatoryDependsOn,
          readOnlyDependsOn: f.readOnlyDependsOn,
          linkFilters: f.linkFilters,
          fetchFrom: f.fetchFrom,
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

      final customizedMeta = DocTypeMeta(
        name: meta.name,
        label: meta.label,
        fields: mappedFields,
        isTable: meta.isTable,
        metaData: meta.metaData,
        titleField: meta.titleField,
        sortField: meta.sortField,
        sortOrder: meta.sortOrder,
      );

      Document? doc;
      if (widget.receiptName != null) {
        try {
          final serverData = await sdk.api.doctype.getByName('Purchase Receipt', widget.receiptName!);
          doc = await sdk.repository.saveServerDocument(
            doctype: 'Purchase Receipt',
            serverId: widget.receiptName!,
            data: serverData,
          );
        } catch (_) {
          doc = await sdk.repository.getDocumentByServerId(widget.receiptName!, 'Purchase Receipt');
        }
      }

      setState(() {
        _meta = customizedMeta;
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

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
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
        metaService: sdk.meta,
        linkOptionService: sdk.linkOptions,
        initialData: const {
          'items': [],
          'taxes': [],
          'supplied_items': [],
        },
        onSaveSuccess: () {
          Navigator.pop(context, true);
        },
      ),
    );
  }
}
