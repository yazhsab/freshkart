import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/models/zone.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/section_header.dart';
import 'zones_provider.dart';

class ZonesScreen extends ConsumerStatefulWidget {
  const ZonesScreen({super.key});

  @override
  ConsumerState<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends ConsumerState<ZonesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncZones = ref.watch(zonesProvider);

    return Column(
      children: [
        SectionHeader(
          title: 'Zones',
          subtitle: 'Manage delivery and service coverage areas',
          actions: [
            FilledButton.icon(
              onPressed: () => _showZoneSheet(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Zone'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
        TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Delivery Zones'),
            Tab(text: 'Service Zones'),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: asyncZones.when(
            loading: () => const LoadingShimmer(),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text('Failed to load zones: $e'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => ref.read(zonesProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (zones) {
              return TabBarView(
                controller: _tabCtrl,
                children: [
                  _ZoneTabContent(
                    zones: zones
                        .where((z) => z.zoneType == 'delivery')
                        .toList(),
                    onEdit: (z) => _showZoneSheet(context, z),
                    onToggle: (z) => ref
                        .read(zonesProvider.notifier)
                        .toggleZone(z.id, !z.isActive),
                  ),
                  _ZoneTabContent(
                    zones: zones
                        .where((z) => z.zoneType == 'service')
                        .toList(),
                    onEdit: (z) => _showZoneSheet(context, z),
                    onToggle: (z) => ref
                        .read(zonesProvider.notifier)
                        .toggleZone(z.id, !z.isActive),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showZoneSheet(BuildContext context, Zone? zone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ZoneFormSheet(
        zone: zone,
        onSave: (data) async {
          if (zone != null) {
            await ref.read(zonesProvider.notifier).updateZone(
                  id: zone.id,
                  name: data['name'] as String,
                  city: data['city'] as String,
                  pincodes: data['pincodes'] as List<String>,
                  zoneType: data['zone_type'] as String,
                  deliveryFeeOverride:
                      data['delivery_fee_override'] as double?,
                  isActive: data['is_active'] as bool,
                );
          } else {
            await ref.read(zonesProvider.notifier).addZone(
                  name: data['name'] as String,
                  city: data['city'] as String,
                  pincodes: data['pincodes'] as List<String>,
                  zoneType: data['zone_type'] as String,
                  deliveryFeeOverride:
                      data['delivery_fee_override'] as double?,
                  isActive: data['is_active'] as bool,
                );
          }
        },
      ),
    );
  }
}

// ── Tab content: left list + right panel ─────────────────────────

class _ZoneTabContent extends StatefulWidget {
  const _ZoneTabContent({
    required this.zones,
    required this.onEdit,
    required this.onToggle,
  });

  final List<Zone> zones;
  final ValueChanged<Zone> onEdit;
  final ValueChanged<Zone> onToggle;

  @override
  State<_ZoneTabContent> createState() => _ZoneTabContentState();
}

class _ZoneTabContentState extends State<_ZoneTabContent> {
  Zone? _selected;

  @override
  Widget build(BuildContext context) {
    if (widget.zones.isEmpty) {
      return const EmptyState(
        icon: Icons.map_outlined,
        title: 'No zones configured',
        subtitle: 'Add your first zone to get started.',
      );
    }

    return Row(
      children: [
        // Left panel: zone cards
        SizedBox(
          width: 380,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: widget.zones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final zone = widget.zones[i];
              final isSelected = _selected?.id == zone.id;
              return _ZoneCard(
                zone: zone,
                isSelected: isSelected,
                onTap: () => setState(() => _selected = zone),
                onEdit: () => widget.onEdit(zone),
                onToggle: () => widget.onToggle(zone),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        // Right panel
        Expanded(
          child: _selected == null
              ? const Center(
                  child: Text(
                    'Select a zone to view details',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : _ZoneDetailPanel(zone: _selected!),
        ),
      ],
    );
  }
}

// ── Zone card ────────────────────────────────────────────────────

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.zone,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onToggle,
  });

  final Zone zone;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    zone.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: zone.isActive,
                  onChanged: (_) => onToggle(),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined, size: 18,
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${zone.city} | ${zone.zoneType ?? 'delivery'}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            if (zone.deliveryFeeOverride != null) ...[
              const SizedBox(height: 2),
              Text(
                'Delivery fee override: \u20B9${zone.deliveryFeeOverride!.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
            if (zone.pincodes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: zone.pincodes.map((p) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      p,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Zone detail panel (right side) ───────────────────────────────

class _ZoneDetailPanel extends StatelessWidget {
  const _ZoneDetailPanel({required this.zone});
  final Zone zone;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map placeholder
          Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'Map view coming soon',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pincodes: ${zone.pincodes.join(", ")}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Data table
          Text(
            'Zone Details',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Name', value: zone.name),
          _DetailRow(label: 'City', value: zone.city),
          _DetailRow(label: 'State', value: zone.state),
          _DetailRow(label: 'Zone Type', value: zone.zoneType ?? 'delivery'),
          _DetailRow(
              label: 'Delivery Fee Override',
              value: zone.deliveryFeeOverride != null
                  ? '\u20B9${zone.deliveryFeeOverride!.toStringAsFixed(0)}'
                  : 'Default'),
          _DetailRow(label: 'Status', value: zone.isActive ? 'Active' : 'Inactive'),
          _DetailRow(
              label: 'Pincodes',
              value: zone.pincodes.isNotEmpty
                  ? zone.pincodes.join(', ')
                  : 'None'),
          _DetailRow(
              label: 'Created',
              value: zone.createdAt?.toLocal().toString().split('.').first ??
                  '—'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ── Zone form bottom sheet ───────────────────────────────────────

class _ZoneFormSheet extends StatefulWidget {
  const _ZoneFormSheet({this.zone, required this.onSave});
  final Zone? zone;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  @override
  State<_ZoneFormSheet> createState() => _ZoneFormSheetState();
}

class _ZoneFormSheetState extends State<_ZoneFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _feeCtrl;
  late final TextEditingController _pincodeInputCtrl;
  late String _city;
  late String _zoneType;
  late bool _isActive;
  late List<String> _pincodes;
  bool _saving = false;

  static const _cities = [
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Tiruchirappalli',
    'Salem',
    'Tirunelveli',
    'Erode',
    'Vellore',
    'Thoothukudi',
    'Thanjavur',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.zone?.name ?? '');
    _feeCtrl = TextEditingController(
        text: widget.zone?.deliveryFeeOverride?.toStringAsFixed(0) ?? '');
    _pincodeInputCtrl = TextEditingController();
    _city = widget.zone?.city ?? 'Chennai';
    _zoneType = widget.zone?.zoneType ?? 'delivery';
    _isActive = widget.zone?.isActive ?? true;
    _pincodes = List<String>.from(widget.zone?.pincodes ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _feeCtrl.dispose();
    _pincodeInputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.zone != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Edit Zone' : 'Add Zone',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Zone Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              // City dropdown
              DropdownButtonFormField<String>(
                value: _cities.contains(_city) ? _city : _cities.first,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                items: _cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _city = v ?? 'Chennai'),
              ),
              const SizedBox(height: 16),
              // Zone type
              const Text('Zone Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'delivery', label: Text('Delivery')),
                  ButtonSegment(value: 'service', label: Text('Service')),
                ],
                selected: {_zoneType},
                onSelectionChanged: (v) =>
                    setState(() => _zoneType = v.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.15),
                  selectedForegroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              // Pincodes chip input
              const Text('Pincodes',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pincodeInputCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Enter pincode and press Add',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _addPincode(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addPincode,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _pincodes.map((p) {
                  return Chip(
                    label: Text(p, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () =>
                        setState(() => _pincodes.remove(p)),
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.08),
                    side: BorderSide.none,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Delivery fee override
              TextFormField(
                controller: _feeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Delivery Fee Override (optional)',
                  prefixText: '\u20B9 ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Active toggle
              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text('Active'),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: 16),
              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEdit ? 'Update Zone' : 'Create Zone'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _addPincode() {
    final pin = _pincodeInputCtrl.text.trim();
    if (pin.length == 6 && int.tryParse(pin) != null && !_pincodes.contains(pin)) {
      setState(() => _pincodes.add(pin));
      _pincodeInputCtrl.clear();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final feeText = _feeCtrl.text.trim();
      final fee = feeText.isNotEmpty ? double.tryParse(feeText) : null;
      await widget.onSave({
        'name': _nameCtrl.text.trim(),
        'city': _city,
        'pincodes': _pincodes,
        'zone_type': _zoneType,
        'delivery_fee_override': fee,
        'is_active': _isActive,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
