import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cms/core/theme/app_colors.dart';
import 'package:cms/core/theme/app_sizes.dart';
import 'package:cms/core/di/injection_container.dart';
import 'package:cms/core/widgets/link_search_bottom_sheet.dart';
import 'package:cms/core/widgets/error_dialog.dart';
import 'package:cms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cms/features/auth/presentation/bloc/auth_state.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';

class EmployeeCheckinPage extends StatefulWidget {
  const EmployeeCheckinPage({super.key});

  @override
  State<EmployeeCheckinPage> createState() => _EmployeeCheckinPageState();
}

class _EmployeeCheckinPageState extends State<EmployeeCheckinPage> {
  // Controllers
  final _employeeController = TextEditingController();
  final _locationController = TextEditingController();

  // State Fields
  String? _employeeId;
  String? _employeeName;
  String _logType = 'IN';

  double? _latitude;
  double? _longitude;

  bool _isEmployeeLoading = false;
  bool _isSubmitting = false;
  bool _isAutoFetched = false;

  @override
  void initState() {
    super.initState();

    // Trigger async fetching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _employeeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final userEmail = authState.user.username;
      await _fetchEmployeeData(userEmail);
    }
    await _determinePosition();
  }

  Future<void> _fetchEmployeeData(String userEmail) async {
    setState(() {
      _isEmployeeLoading = true;
    });

    try {
      final sdk = sl<FrappeSDK>();
      final list = await sdk.api.doctype.list(
        'Employee',
        filters: [
          ['Employee', 'user_id', '=', userEmail],
        ],
        fields: ['name', 'employee_name'],
      );

      if (list.isNotEmpty) {
        final emp = list.first;
        setState(() {
          _employeeId = emp['name']?.toString();
          _employeeName = emp['employee_name']?.toString();
          _employeeController.text = _employeeName ?? _employeeId ?? '';
          _isAutoFetched = true;
        });
      } else {
        // Logged in user not found as Employee
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Logged-in user email is not linked to any Employee. Please select manually.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching employee: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isEmployeeLoading = false;
        });
      }
    }
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text =
            '${position.latitude}, ${position.longitude}';
      });
    } catch (e) {
      debugPrint('Error fetching location: $e');
    }
  }

  Future<void> _showLinkSearch(
    String doctype,
    ValueChanged<String> onSelected,
  ) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return LinkSearchBottomSheet(
          doctype: doctype,
          onSelected: (val, _) {
            Navigator.pop(context);
            onSelected(val);
          },
        );
      },
    );
  }

  Future<void> _saveCheckin() async {
    if (_employeeId == null || _employeeId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or load an Employee.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final sdk = sl<FrappeSDK>();

      final Map<String, dynamic> payload = {
        'employee': _employeeId,
        'log_type': _logType,
        'device_id': _locationController.text.isNotEmpty
            ? _locationController.text
            : 'Mobile App',
      };

      if (_latitude != null) {
        payload['latitude'] = _latitude;
      }
      if (_longitude != null) {
        payload['longitude'] = _longitude;
      }

      await sdk.api.document.createDocument('Employee Checkin', payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in logged successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, 'Failed to Log Checkin', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Employee Check in / Check out',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!_isSubmitting)
            TextButton(
              onPressed: _saveCheckin,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF4A8B5F),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A8B5F)),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(sizeContextOf(context, 16)),
        child: Column(
          children: [
            _buildCard(
              title: 'Checkin Form',
              icon: Icons.fingerprint,
              children: [
                _buildTextField(
                  label: 'Employee *',
                  controller: _employeeController,
                  placeholder: 'Select Employee',
                  readOnly: _isAutoFetched,
                  suffixIcon: _isEmployeeLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey,
                            ),
                          ),
                        )
                      : (_isAutoFetched
                            ? null
                            : const Icon(Icons.search, color: Colors.grey)),
                  onTap: _isAutoFetched
                      ? null
                      : () => _showLinkSearch('Employee', (val) async {
                          setState(() {
                            _employeeId = val;
                            _employeeController.text = val;
                          });
                          try {
                            final sdk = sl<FrappeSDK>();
                            final empData = await sdk.api.doctype.getByName(
                              'Employee',
                              val,
                            );
                            final name =
                                empData['employee_name']?.toString() ?? val;
                            setState(() {
                              _employeeName = name;
                              _employeeController.text = name;
                            });
                          } catch (_) {}
                        }),
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                _buildLogTypeSelector(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(sizeContextOf(context, 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.black54),
                SizedBox(width: sizeContextOf(context, 8)),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: sizeContextOf(context, 16)),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    Widget? suffixIcon,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: sizeContextOf(context, 6)),
        GestureDetector(
          onTap: readOnly ? null : onTap,
          child: AbsorbPointer(
            absorbing: readOnly || onTap != null,
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: sizeContextOf(context, 12),
                  vertical: sizeContextOf(context, 12),
                ),
                filled: true,
                fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
                suffixIcon: suffixIcon != null
                    ? Padding(
                        padding: EdgeInsets.only(
                          right: sizeContextOf(context, 8.0),
                        ),
                        child: suffixIcon,
                      )
                    : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCDE0D5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4A8B5F)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Log Type *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: sizeContextOf(context, 6)),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _logType = 'IN'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _logType == 'IN'
                        ? const Color(0xFF4A8B5F)
                        : Colors.white,
                    border: Border.all(
                      color: _logType == 'IN'
                          ? const Color(0xFF4A8B5F)
                          : const Color(0xFFCDE0D5),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Check In (IN)',
                      style: TextStyle(
                        color: _logType == 'IN' ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _logType = 'OUT'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _logType == 'OUT'
                        ? const Color(0xFFC98585)
                        : Colors.white,
                    border: Border.all(
                      color: _logType == 'OUT'
                          ? const Color(0xFFC98585)
                          : const Color(0xFFCDE0D5),
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Check Out (OUT)',
                      style: TextStyle(
                        color: _logType == 'OUT'
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
