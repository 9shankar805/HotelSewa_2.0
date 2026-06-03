import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class GuestRoomSelectorScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const GuestRoomSelectorScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<GuestRoomSelectorScreen> createState() => _GuestRoomSelectorScreenState();
}

class _GuestRoomSelectorScreenState extends State<GuestRoomSelectorScreen> {
  int _rooms = 1;
  int _adults = 2;
  int _children = 0;
  List<int> _childAges = [];

  @override
  void initState() {
    super.initState();
    final args = widget.arguments ?? {};
    _rooms = args['rooms'] ?? 1;
    _adults = args['adults'] ?? 2;
    _children = args['children'] ?? 0;
    _childAges = List<int>.filled(_children, 5);
  }

  void _updateChildren(int val) {
    setState(() {
      _children = val;
      if (val > _childAges.length) {
        _childAges.addAll(List.filled(val - _childAges.length, 5));
      } else {
        _childAges = _childAges.take(val).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Guests & Rooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
                    child: Column(
                      children: [
                        _guestRow('Rooms', null, _rooms, (v) => setState(() => _rooms = v), 1, 8, Icons.meeting_room_outlined),
                        const Divider(color: AppColors.lightGray, height: 24),
                        _guestRow('Adults', 'Age 18+', _adults, (v) => setState(() => _adults = v), 1, 16, Icons.person_outline_rounded),
                        const Divider(color: AppColors.lightGray, height: 24),
                        _guestRow('Children', 'Age 0–17', _children, _updateChildren, 0, 8, Icons.child_care_rounded),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),

                  if (_children > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Children\'s Ages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                          const SizedBox(height: 4),
                          const Text('Required for accurate pricing', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                          const SizedBox(height: 16),
                          ...List.generate(_children, (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Text('Child ${i + 1}', style: const TextStyle(fontSize: 14, color: AppColors.darkGray, fontWeight: FontWeight.w500)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.lightGray)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _childAges[i],
                                      items: List.generate(18, (age) => DropdownMenuItem(value: age, child: Text('$age years'))),
                                      onChanged: (v) => setState(() => _childAges[i] = v!),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                  ],

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          '$_rooms room${_rooms > 1 ? 's' : ''} · ${_adults + _children} guest${_adults + _children > 1 ? 's' : ''} total',
                          style: const TextStyle(fontSize: 13, color: AppColors.info, fontWeight: FontWeight.w600),
                        )),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4))]),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'rooms': _rooms,
                  'adults': _adults,
                  'children': _children,
                  'childAges': _childAges,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Apply · $_rooms room${_rooms > 1 ? 's' : ''}, ${_adults + _children} guest${_adults + _children > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestRow(String label, String? sub, int value, ValueChanged<int> onChange, int min, int max, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          if (sub != null) Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
        ])),
        Row(children: [
          _btn(Icons.remove_rounded, value > min ? () => onChange(value - 1) : null),
          SizedBox(width: 40, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray))),
          _btn(Icons.add_rounded, value < max ? () => onChange(value + 1) : null),
        ]),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: onTap != null ? AppColors.primary.withOpacity(0.3) : AppColors.lightGray),
        ),
        child: Icon(icon, size: 16, color: onTap != null ? AppColors.primary : AppColors.placeholder),
      ),
    );
  }
}
