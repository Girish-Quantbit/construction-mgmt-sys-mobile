import 'package:flutter/material.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:cms/core/theme/app_sizes.dart';

class LinkSearchBottomSheet extends StatefulWidget {
  final String doctype;
  final List<List<dynamic>>? extraFilters;
  final void Function(String name, String? label) onSelected;

  /// Optional custom fetcher. When provided, it is called with the current
  /// search query and must return a list of [LinkOptionEntity] results.
  /// Overrides the default [sdk.linkOptions.getLinkOptions] call.
  final Future<List<LinkOptionEntity>> Function(String query)? customFetcher;

  const LinkSearchBottomSheet({
    super.key,
    required this.doctype,
    this.extraFilters,
    required this.onSelected,
    this.customFetcher,
  });

  @override
  State<LinkSearchBottomSheet> createState() => _LinkSearchBottomSheetState();
}

class _LinkSearchBottomSheetState extends State<LinkSearchBottomSheet> {
  final _searchController = TextEditingController();
  List<LinkOptionEntity> _options = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOptions([String query = '']) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (widget.doctype == 'Material Request Type' ||
        widget.doctype == 'Purpose') {
      final staticOptions = [
        LinkOptionEntity(
          name: 'Purchase',
          label: 'Purchase',
          doctype: 'Material Request Type',
          lastUpdated: DateTime.now().millisecondsSinceEpoch,
        ),
        LinkOptionEntity(
          name: 'Material Transfer',
          label: 'Material Transfer',
          doctype: 'Material Request Type',
          lastUpdated: DateTime.now().millisecondsSinceEpoch,
        ),
        LinkOptionEntity(
          name: 'Material Issue',
          label: 'Material Issue',
          doctype: 'Material Request Type',
          lastUpdated: DateTime.now().millisecondsSinceEpoch,
        ),
        LinkOptionEntity(
          name: 'Manufacture',
          label: 'Manufacture',
          doctype: 'Material Request Type',
          lastUpdated: DateTime.now().millisecondsSinceEpoch,
        ),
        LinkOptionEntity(
          name: 'Customer Provided',
          label: 'Customer Provided',
          doctype: 'Material Request Type',
          lastUpdated: DateTime.now().millisecondsSinceEpoch,
        ),
      ];
      if (!mounted) return;
      setState(() {
        _options = staticOptions
            .where(
              (opt) => opt.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        _loading = false;
      });
      return;
    }

    try {
      List<LinkOptionEntity> options;
      if (widget.customFetcher != null) {
        options = await widget.customFetcher!(query);
      } else {
        final sdk = sl<FrappeSDK>();
        final List<List<dynamic>> filters = [];
        if (widget.extraFilters != null) {
          filters.addAll(widget.extraFilters!);
        }
        if (query.isNotEmpty) {
          filters.add([widget.doctype, 'name', 'like', '%$query%']);
        }
        options = await sdk.linkOptions.getLinkOptions(
          widget.doctype,
          filters: filters.isNotEmpty ? filters : null,
          forceRefresh: true,
        );
      }
      if (!mounted) return;
      setState(() {
        _options = options;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        top: sizeContextOf(context, 16),
        left: sizeContextOf(context, 16),
        right: sizeContextOf(context, 16),
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select ${widget.doctype}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: sizeContextOf(context, 12)),
          TextField(
            controller: _searchController,
            onChanged: (val) => _fetchOptions(val),
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(
                horizontal: sizeContextOf(context, 12),
                vertical: sizeContextOf(context, 12),
              ),
              filled: true,
              fillColor: const Color(0xFFF2FAF6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: sizeContextOf(context, 16)),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _options.isEmpty
                        ? const Center(child: Text('No options found'))
                        : ListView.builder(
                            itemCount: _options.length,
                            itemBuilder: (context, idx) {
                              final option = _options[idx];
                              return ListTile(
                                title: Text(option.label ?? option.name),
                                subtitle: Text(option.name),
                                onTap: () => widget.onSelected(option.name, option.label),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
