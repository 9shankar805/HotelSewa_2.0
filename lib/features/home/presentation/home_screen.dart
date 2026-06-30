import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/hotel_service.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/recommendations_service.dart';
import '../../../core/services/deals_service.dart';
import '../../../core/widgets/floating_chatbot.dart';
import '../../../core/widgets/in_stay_banner.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../hotel/presentation/hotel_details_screen.dart';

enum _BType { nightly, hourly }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _hotelSvc = HotelService();
  final _bookSvc  = BookingService();
  final _recSvc   = RecommendationsService();
  final _dealSvc  = DealsService();

  _BType _bType = _BType.nightly;
  String _cat   = 'All';
  bool   _scrolled = false;
  final  _scrollCtrl = ScrollController();

  List<Map<String,dynamic>> _hotels  = [];
  List<Map<String,dynamic>> _offers  = [];
  List<Map<String,dynamic>> _cities  = [];
  Map<String,dynamic>?      _trip;
  List<Map<String,dynamic>> _recent  = [];
  bool _loading = true;

  static const _cats = ['All','Budget','Luxury','Business','Resort'];
  static const _ncities = [
    {'n':'Kathmandu','i':'https://images.unsplash.com/photo-1605640840605-14ac1855827b?w=300'},
    {'n':'Chitwan',  'i':'https://images.unsplash.com/photo-1601758125946-6ec2ef64daf8?w=300'},
    {'n':'Pokhara',  'i':'https://images.unsplash.com/photo-1544735716-392fe2489ffa?w=300'},
    {'n':'Siraha',   'i':'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=300'},
    {'n':'Lumbini',  'i':'https://images.unsplash.com/photo-1590736704728-f4730bb30770?w=300'},
    {'n':'Bhaktapur','i':'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=300'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(() {
      // toggle=68px + search=78px = 146px — fire only after search fully exits viewport
      final scrolled = _scrollCtrl.offset > 146;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.wait([_loadHotels(), _loadDeals(), _loadBookings(), _loadRecent()]);
    setState(() => _loading = false);
  }

  Future<void> _loadHotels() async {
    try {
      final res = await _hotelSvc.getHotels();
      if (res['success'] != true) return;
      final raw = res['data'];
      final list = (raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['hotels'] ?? raw['items'] ?? []) : [])) as List;
      final parsed = list.map<Map<String,dynamic>>((h) => _ph(h)).toList();
      final cm = <String,int>{};
      for (final h in parsed) { final c = h['city'] as String? ?? ''; if (c.isNotEmpty) cm[c] = (cm[c]??0)+1; }
      _cities = _ncities.map<Map<String,dynamic>>((c) => {'name':c['n']!,'image':c['i']!,'count':cm[c['n']]??0}).toList();
      try {
        final rr = await _recSvc.getTrendingRecommendations(limit:10);
        if (rr['success']==true) { final rl=rr['hotels']; if (rl is List && rl.isNotEmpty) { _hotels=rl.map<Map<String,dynamic>>((h)=>_ph(h)).toList(); return; } }
      } catch (_) {}
      _hotels = parsed.take(10).toList();
    } catch (_) {}
  }

  Future<void> _loadDeals() async {
    try {
      final res = await _dealSvc.getFeaturedDeals(limit:5);
      if (res['success']==true) {
        final raw=res['deals'];
        if (raw is List && raw.isNotEmpty) {
          _offers = raw.map<Map<String,dynamic>>((d)=>{'id':d['id'],'title':d['title']??d['name']??'Offer','subtitle':d['description']??'Up to ${d['discount']??20}% off','image':_img(d['image']??d['banner_image']),'discount':d['discount_percent']??d['discount']??20,'hotelId':null}).toList();
          return;
        }
      }
    } catch (_) {}
    if (_hotels.isNotEmpty) _offers = _hotels.take(4).map((h)=>{'id':h['id'],'title':h['name'],'subtitle':'Up to 40% off','image':h['image'],'discount':20,'hotelId':h['id']}).toList();
  }

  Future<void> _loadBookings() async {
    try {
      final res = await _bookSvc.getMyBookings();
      if (res['success']==true) {
        final bks=(res['bookings'] as List? ?? []).cast<Map<String,dynamic>>();
        final up=bks.where((b)=>{
          'confirmed','pending'
        }.contains((b['status']??'').toString().toLowerCase())).toList();
        if (up.isNotEmpty) { final b=up.first; _trip={'hotelName':b['hotel_name']??b['hotel']?['name']??'Hotel','checkIn':b['check_in']??'','location':b['hotel']?['city']??b['location']??'','image':_img(b['hotel']?['image']??b['hotel_image']),'id':b['id']}; }
      }
    } catch (_) {}
  }

  Future<void> _loadRecent() async {
    try {
      final p=await SharedPreferences.getInstance();
      final raw=p.getStringList('recent_searches')??[];
      _recent=raw.take(4).map((s){try{return jsonDecode(s) as Map<String,dynamic>;}catch(_){return {'city':s,'image':'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=300'};}}).toList();
    } catch (_) {}
  }

  void _clearRecent() async { final p=await SharedPreferences.getInstance(); await p.remove('recent_searches'); setState(()=>_recent=[]); }

  Map<String,dynamic> _ph(dynamic h) => {'id':h['id'],'name':h['name']??'Hotel','city':h['city']?.toString()??h['state']?.toString()??'','address':_addr(h),'image':_img(h['image']??h['images']),'rating':(h['rating'] as num?)?.toDouble()??0.0,'reviewCount':(h['total_reviews']??h['review_count']??0) as int,'price':((h['min_price']??h['starting_price']??h['price']??2500) as num).toInt(),'amenities':_amen(h['amenities']),'discount':(h['discount_percent']??h['discount']??0) as int,'bookingsToday':(h['bookings_today']??h['booked_today']??0) as int};

  String _addr(dynamic h) { final c=h['city']?.toString()??''; final s=h['state']?.toString()??''; if(c.isEmpty&&s.isEmpty) return h['address']?.toString()??''; if(s.isEmpty) return c; if(c.isEmpty) return s; return '$c, $s'; }

  String _img(dynamic v) { String u=''; if(v is String&&v.isNotEmpty) u=v.startsWith('http')?v:''; else if(v is List&&v.isNotEmpty){final f=v[0];u=f is Map?(f['url']?.toString()??''):f.toString();} final m=RegExp(r'https?://[^/]+/storage/(https?://.+)').firstMatch(u); if(m!=null) return m.group(1)!; return u.isNotEmpty?u:'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=600'; }

  List<String> _amen(dynamic a) => a is List ? a.map((x)=>x.toString()).toList() : [];

  List<Map<String,dynamic>> get _filtered => _cat=='All' ? _hotels : _hotels.where((h)=>(h['name'] as String).toLowerCase().contains(_cat.toLowerCase())).toList();

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Stack(children: [
        RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
            _appBar(ctx),
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else ...[
              SliverToBoxAdapter(child: _toggle()),
              SliverToBoxAdapter(child: _search()),
              SliverToBoxAdapter(child: _chips()),
              const SliverToBoxAdapter(child: InStayBanner()),
              if (_trip != null) SliverToBoxAdapter(child: _tripSection()),
              if (_recent.isNotEmpty) SliverToBoxAdapter(child: _recentSection()),
              SliverToBoxAdapter(child: _actions()),
              if (_offers.isNotEmpty) SliverToBoxAdapter(child: _offersSection()),
              SliverToBoxAdapter(child: _citiesSection()),
              SliverToBoxAdapter(child: _recommendedSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ]),
        ),
        const FloatingChatbot(),
      ]),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────
  SliverAppBar _appBar(BuildContext ctx) {
    final auth = ctx.watch<AuthProvider>();
    final name = auth.user?.name ?? '';
    final ini  = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    // Avatar with green dot — reused in both states
    final avatar = Stack(clipBehavior: Clip.none, children: [
      CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Text(ini, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
      ),
      Positioned(bottom: 0, right: 0, child: Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5)),
      )),
    ]);

    // Right icons — same in both states
    final rightIcons = Row(mainAxisSize: MainAxisSize.min, children: [
      Stack(children: [
        _ib(Icons.notifications_outlined, () => ctx.push('/notifications')),
        Positioned(top: 10, right: 10, child: Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5)),
        )),
      ]),
      const SizedBox(width: 8),
      _ib(Icons.grid_view_rounded, () => ctx.push('/advanced-features')),
    ]);

    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0.5,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: 60,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _scrolled
              // ── Scrolled: compact search bar ──────────────────────────
              ? Row(key: const ValueKey('scrolled'), children: [
                  avatar,
                  const SizedBox(width: 10),
                  Expanded(child: GestureDetector(
                    onTap: () => ctx.push('/search'),
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Row(children: [
                        SizedBox(width: 12),
                        Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                        SizedBox(width: 8),
                        Text('Search hotels...', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                      ]),
                    ),
                  )),
                  const SizedBox(width: 10),
                  rightIcons,
                ])
              // ── At top: full HOTELSEWA brand ───────────────────────────
              : Row(key: const ValueKey('top'), children: [
                  avatar,
                  const SizedBox(width: 10),
                  const Text('HOTELSEWA',
                      style: TextStyle(color: AppColors.primary, fontSize: 20,
                          fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const Spacer(),
                  rightIcons,
                ]),
        ),
      ),
    );
  }

  Widget _ib(IconData ic, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      width: 42, height: 42,
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
      child: Icon(ic, size: 22, color: const Color(0xFF374151)),
    ),
  );

  // ─── Nightly / Hourly toggle ──────────────────────────────────────────────
  Widget _toggle() {
    final isNightly = _bType == _BType.nightly;
    return LayoutBuilder(builder: (ctx, constraints) {
      final totalW = constraints.maxWidth - 32; // account for 16px margins
      final nightlyW = totalW * 0.57; // 57% for Nightly pill
      final hourlyW  = totalW * 0.43; // 43% for Hourly pill

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Stack(children: [
          // ── Sliding red pill pinned to LEFT ──────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            top: 4, bottom: 4,
            left: isNightly ? 4 : nightlyW + 4,
            width: isNightly ? nightlyW : hourlyW,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
          // ── Tap areas + labels ────────────────────────────────────────
          Row(children: [
            // Nightly
            SizedBox(
              width: nightlyW + 8,
              child: GestureDetector(
                onTap: () => setState(() => _bType = _BType.nightly),
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Text('Nightly',
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: isNightly ? Colors.white : const Color(0xFF9CA3AF),
                      )),
                ),
              ),
            ),
            // Hourly
            Expanded(
              child: GestureDetector(
                onTap: () { setState(() => _bType = _BType.hourly); context.push('/search'); },
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Hourly',
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: !isNightly ? Colors.white : const Color(0xFF9CA3AF),
                        )),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: !isNightly ? Colors.white.withOpacity(0.25) : AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('NEW',
                          style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w900,
                            color: !isNightly ? Colors.white : Colors.white,
                          )),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ]),
      );
    });
  }

  // ─── Search ───────────────────────────────────────────────────────────────
  Widget _search() {
    return GestureDetector(
      onTap: ()=>context.push('/search'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16,16,16,0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(16),
          boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.04),blurRadius:15,offset:const Offset(0,4))]),
        child: Row(children:[
          Container(width:44,height:44,
            decoration:BoxDecoration(color:AppColors.primary,borderRadius:BorderRadius.circular(12)),
            child:const Icon(Icons.search_rounded,color:Colors.white,size:20)),
          const SizedBox(width:12),
          const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('Where to next?',style:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:Color(0xFF1A1A2E))),
            SizedBox(height:2),
            Text('Search by city, hotel or area',style:TextStyle(fontSize:12,color:Color(0xFF9CA3AF))),
          ])),
          const Icon(Icons.tune_rounded,size:20,color:Color(0xFF1A1A2E)),
        ]),
      ),
    );
  }

  // ─── Chips ───────────────────────────────────────────────────────────────
  Widget _chips() {
    final items = [
      (Icons.near_me_rounded, 'Near Me', '/near-me'),
      (Icons.history_rounded,  'Recent',  '/recently-viewed'),
      (Icons.map_rounded,      'Map',     '/map-search'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(children: items.map((c) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: () => context.push(c.$3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(c.$1, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(c.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            ]),
          ),
        ),
      )).toList()),
    );
  }

  // ─── Upcoming Trip ────────────────────────────────────────────────────────
  Widget _tripSection() {
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Padding(padding:EdgeInsets.fromLTRB(16,24,16,12),child:Text('Upcoming Trip ✈️',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:Color(0xFF1A1A2E)))),
      GestureDetector(onTap:()=>context.push('/my-trips'),child:Container(
        margin:const EdgeInsets.symmetric(horizontal:16),padding:const EdgeInsets.all(12),
        decoration:BoxDecoration(color:AppColors.primary,borderRadius:BorderRadius.circular(20),boxShadow:[BoxShadow(color:AppColors.primary.withOpacity(0.25),blurRadius:15,offset:const Offset(0,5))]),
        child:Row(children:[
          ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.network(_trip?['image']??'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=300',width:70,height:70,fit:BoxFit.cover)),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(_trip?['hotelName']??'Hotel Yak & Yeti',style:const TextStyle(fontSize:15,fontWeight:FontWeight.w800,color:Colors.white)),
            const SizedBox(height:4),
            Row(children:[const Icon(Icons.calendar_today_outlined,size:11,color:Colors.white),const SizedBox(width:5),Text(_trip?['checkIn']??'Tomorrow, 12:00 PM',style:const TextStyle(fontSize:11,color:Colors.white,fontWeight:FontWeight.w500))]),
            const SizedBox(height:3),
            Row(children:[const Icon(Icons.location_on_outlined,size:11,color:Colors.white),const SizedBox(width:5),Text(_trip?['location']??'Durbar Marg, Kathmandu',style:const TextStyle(fontSize:11,color:Colors.white,fontWeight:FontWeight.w500))]),
          ])),
          Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),decoration:BoxDecoration(color:Colors.white.withOpacity(0.2),borderRadius:BorderRadius.circular(10)),child:const Text('Details',style:TextStyle(color:Colors.white,fontSize:12,fontWeight:FontWeight.w700))),
        ]),
      )),
    ]);
  }

  // ─── Recent searches ──────────────────────────────────────────────────────
  Widget _recentSection() {
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,24,16,12),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        const Text('Pick up where you left off',style:TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:Color(0xFF1A1A2E))),
        GestureDetector(onTap:_clearRecent,child:const Text('Clear',style:TextStyle(fontSize:13,color:AppColors.primary,fontWeight:FontWeight.w600))),
      ])),
      SizedBox(height:85,child:ListView.builder(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:16),itemCount:_recent.length,itemBuilder:(_,i){
        final s=_recent[i];
        return GestureDetector(onTap:()=>context.push('/hotel-list',extra:{'location':s['city']}),child:Container(width:185,margin:const EdgeInsets.only(right:14),
          padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.04),blurRadius:12,offset:const Offset(0,4))]),
          child:Row(children:[
            ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.network(s['image']??'',width:50,height:50,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(width:50,height:50,color:const Color(0xFFF7F8FA),child:const Icon(Icons.location_on,color:AppColors.placeholder,size:20)))),
            const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
              Text(s['city']??'',style:const TextStyle(fontSize:14,fontWeight:FontWeight.w800,color:Color(0xFF1A1A2E)),maxLines:1),
              const SizedBox(height:2),
              Text(s['dates']??'Jun 12 - Jun 15',style:const TextStyle(fontSize:11,color:Color(0xFF9CA3AF),fontWeight:FontWeight.w500),maxLines:1),
              Text('2 Guests',style:const TextStyle(fontSize:11,color:Color(0xFF9CA3AF),fontWeight:FontWeight.w500),maxLines:1),
            ])),
          ]),
        ));
      })),
    ]);
  }

  // ─── Quick actions ────────────────────────────────────────────────────────
  Widget _actions() {
    final items = [
      ('Bookings', const Color(0xFFFFEBEB), AppColors.primary, Icons.receipt_long_rounded, '/my-trips'),
      ('Rewards',  const Color(0xFFFFF8E1), const Color(0xFFF59E0B), Icons.card_giftcard_rounded, '/invite-earn'),
      ('Support',  const Color(0xFFE8F4FD), const Color(0xFF3B82F6), Icons.support_agent_rounded, '/help-center'),
      ('About',    const Color(0xFFF3EFFD), const Color(0xFF8B5CF6), null, '/about'),
    ];
    return Padding(padding:const EdgeInsets.fromLTRB(16,24,16,0),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:items.map((a)=>GestureDetector(onTap:()=>context.push(a.$5),child:Column(mainAxisSize:MainAxisSize.min,children:[
      Container(width:68,height:68,decoration:BoxDecoration(color:a.$2,borderRadius:BorderRadius.circular(18)),
        child:a.$4 != null ? Icon(a.$4,color:a.$3,size:26) : ClipRRect(borderRadius:BorderRadius.circular(18),child:Image.asset('assets/images/chatbot.png',fit:BoxFit.cover,errorBuilder:(_,__,___)=>Icon(Icons.info_outline_rounded,color:a.$3,size:26)))),
      const SizedBox(height:8),
      Text(a.$1,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700,color:Color(0xFF1A1A2E))),
    ]))).toList()));
  }

  // ─── Exclusive Offers ─────────────────────────────────────────────────────
  Widget _offersSection() {
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,32,16,12),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        const Row(children:[Text('Exclusive Offers 🔥',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:Color(0xFF1A1A2E))),SizedBox(width:8)]),
        GestureDetector(onTap:()=>context.push('/deals'),child:const Text('See all',style:TextStyle(fontSize:13,color:AppColors.primary,fontWeight:FontWeight.w700))),
      ])),
      Padding(padding:const EdgeInsets.only(left:16,bottom:16),child:Container(width:30,height:3,decoration:BoxDecoration(color:AppColors.primary,borderRadius:BorderRadius.circular(2)))),
      SizedBox(height:180,child:ListView.builder(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:16),itemCount:_offers.length,itemBuilder:(_,i){
        final o=_offers[i];
        return GestureDetector(onTap:(){if(o['hotelId']!=null)Navigator.push(context,MaterialPageRoute(builder:(_)=>HotelDetailsScreen(arguments:{'hotelId':o['hotelId']})));else context.push('/deals');},
          child:Container(width:280,margin:const EdgeInsets.only(right:14),child:ClipRRect(borderRadius:BorderRadius.circular(20),child:Stack(fit:StackFit.expand,children:[
            Image.network(o['image']!,fit:BoxFit.cover),
            Container(decoration:BoxDecoration(gradient:LinearGradient(colors:[Colors.black.withOpacity(0.1),Colors.black.withOpacity(0.7)],begin:Alignment.topCenter,end:Alignment.bottomCenter))),
            Positioned(bottom:16,left:16,right:16,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(o['title']!,style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w800)),
              const SizedBox(height:6),
              Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(8)),child:Text(o['subtitle']!,style:const TextStyle(color:Color(0xFF1A1A2E),fontSize:11,fontWeight:FontWeight.w800))),
            ])),
            Positioned(bottom:12,right:12,child:Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),decoration:BoxDecoration(color:AppColors.primary,borderRadius:BorderRadius.circular(6)),child:const Text('HotelSewa',style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w800)))),
          ]))),
        );
      })),
    ]);
  }

  // ─── Popular Cities ───────────────────────────────────────────────────────
  Widget _citiesSection() {
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,32,16,12),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        const Text('Popular Cities',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:Color(0xFF1A1A2E))),
        GestureDetector(onTap:()=>context.push('/hotel-list'),child:const Text('View all',style:TextStyle(fontSize:13,color:AppColors.primary,fontWeight:FontWeight.w700))),
      ])),
      Padding(padding:const EdgeInsets.only(left:16,bottom:16),child:Container(width:30,height:3,decoration:BoxDecoration(color:AppColors.primary,borderRadius:BorderRadius.circular(2)))),
      SizedBox(height:125,child:ListView.builder(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:16),itemCount:_cities.length,itemBuilder:(_,i){
        final c=_cities[i];
        return GestureDetector(onTap:()=>context.push('/hotel-list',extra:{'location':c['name']}),child:Padding(padding:const EdgeInsets.only(right:20),child:Column(children:[
          Container(width:75,height:75,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:Colors.white,width:2),boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:10)]),child:ClipOval(child:Image.network(c['image']!,fit:BoxFit.cover))),
          const SizedBox(height:8),
          Text(c['name']!,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:Color(0xFF1A1A2E))),
          Text('${c['count']} hotels',style:const TextStyle(fontSize:11,color:Color(0xFF9CA3AF),fontWeight:FontWeight.w500)),
        ])));
      })),
    ]);
  }

  // ─── Recommended for You ──────────────────────────────────────────────────
  Widget _recommendedSection() {
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,32,16,12),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        const Text('Recommended for You',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:Color(0xFF1A1A2E))),
        GestureDetector(onTap:()=>context.push('/hotel-list'),child:const Text('See all',style:TextStyle(fontSize:13,color:AppColors.primary,fontWeight:FontWeight.w700))),
      ])),
      Padding(padding:const EdgeInsets.only(left:16,bottom:20),child:Container(width:30,height:3,decoration:BoxDecoration(color:AppColors.primary,borderRadius:BorderRadius.circular(2)))),
      const Padding(padding:EdgeInsets.fromLTRB(16,0,16,16),child:Text('Explore Categories',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800,color:Color(0xFF1A1A2E)))),
      SizedBox(height:45,child:ListView.builder(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:16),itemCount:_cats.length,itemBuilder:(_,i){
        final cat=_cats[i]; final on=_cat==cat;
        return GestureDetector(onTap:()=>setState(()=>_cat=cat),child:AnimatedContainer(duration:const Duration(milliseconds:150),margin:const EdgeInsets.only(right:10),padding:const EdgeInsets.symmetric(horizontal:20),
          decoration:BoxDecoration(color:on?AppColors.primary:Colors.white,borderRadius:BorderRadius.circular(12),boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.03),blurRadius:10)]),
          child:Row(mainAxisSize:MainAxisSize.min,children:[
            Icon(cat=='All'?Icons.grid_view_rounded:cat=='Budget'?Icons.savings_rounded:cat=='Luxury'?Icons.diamond_rounded:Icons.hotel_rounded,size:15,color:on?Colors.white:const Color(0xFF1A1A2E)),
            const SizedBox(width:8),
            Text(cat,style:TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:on?Colors.white:const Color(0xFF1A1A2E))),
          ])));
      })),
      const SizedBox(height:20),
      if(_filtered.isEmpty)const Padding(padding:EdgeInsets.all(40),child:Center(child:Text('No hotels found',style:TextStyle(color:Color(0xFF9CA3AF)))))
      else ..._filtered.map((h)=>_hotelCard(h)),
    ]);
  }

  Widget _hotelCard(Map<String,dynamic> h) {
    final discount = h['discount'] as int? ?? 0;
    final originalPrice = discount > 0 ? (h['price'] as int) * (100 + discount) ~/ 100 : (h['price'] as int);
    
    return GestureDetector(
      onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>HotelDetailsScreen(arguments:{'hotelId':h['id']}))),
      child:Container(margin:const EdgeInsets.fromLTRB(16,0,16,20),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.04),blurRadius:20,offset:const Offset(0,8))]),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Stack(children:[
            ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(24)),child:Image.network(h['image']!,width:double.infinity,height:210,fit:BoxFit.cover)),
            Positioned(top:12,left:12,child:Row(children:[
              Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),decoration:BoxDecoration(color:AppColors.primary,borderRadius:BorderRadius.circular(8)),child:Text('${discount>0 ? discount : 20}% OFF',style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.w900))),
              const SizedBox(width:8),
              Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(8)),child:const Row(children:[Icon(Icons.verified_rounded,size:12,color:Color(0xFF22C55E)),SizedBox(width:3),Text('Verified',style:TextStyle(color:Color(0xFF1A1A2E),fontSize:10,fontWeight:FontWeight.w700))])),
            ])),
            Positioned(top:12,right:12,child:Container(width:36,height:36,decoration:BoxDecoration(color:Colors.white,shape:BoxShape.circle,boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.1),blurRadius:8)]),child:const Icon(Icons.favorite_border_rounded,size:18,color:AppColors.primary))),
            Positioned(bottom:12,right:12,child:Container(padding:const EdgeInsets.fromLTRB(8,8,12,8),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(30)),child:Row(mainAxisSize:MainAxisSize.min,children:[
              Container(width:40,height:40,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:const Color(0xFFF7F8FA),width:1.5)),child:ClipOval(child:Transform.scale(scale:1.2,child:Image.asset('assets/icon.png',fit:BoxFit.cover)))),
              const SizedBox(width:8),
              Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
                Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(color:AppColors.primary,borderRadius:BorderRadius.circular(4)),child:const Text('HotelSewa',style:TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w900))),
                const SizedBox(height:2),
                Row(textBaseline:TextBaseline.alphabetic,crossAxisAlignment:CrossAxisAlignment.baseline,children:[Text('NPR ${h['price']}',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900,color:Color(0xFF1A1A2E))),const Text('/night',style:TextStyle(fontSize:11,color:Color(0xFF9CA3AF),fontWeight:FontWeight.w600))]),
              ]),
            ]))),
            Positioned(bottom:12,left:12,child:Row(children:[
              Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:Colors.black.withOpacity(0.6),borderRadius:BorderRadius.circular(20)),child:Row(children:[Icon(Icons.trending_up_rounded,size:12,color:Color(0xFF22C55E)),SizedBox(width:6),Text('${h['bookingsToday'] ?? 5} booked today',style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700))])),
            ])),
          ]),
          Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
              Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:const Color(0xFFFFF8E1),borderRadius:BorderRadius.circular(8)),child:Row(children:[const Icon(Icons.star_rounded,size:14,color:Color(0xFFF59E0B)),const SizedBox(width:4),Text('${h['rating']}',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800,color:Color(0xFFF59E0B))),Text(' (${h['reviewCount']} reviews)',style:const TextStyle(fontSize:11,color:Color(0xFF9CA3AF),fontWeight:FontWeight.w600))])),
            ]),
            const SizedBox(height:10),
            Text(h['name']!,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800,color:Color(0xFF1A1A2E))),
            const SizedBox(height:4),
            Row(children:[const Icon(Icons.location_on_rounded,size:13,color:Color(0xFF9CA3AF)),const SizedBox(width:4),Text(h['city']!,style:const TextStyle(fontSize:12,color:Color(0xFF9CA3AF),fontWeight:FontWeight.w600))]),
            const SizedBox(height:12),
            Row(children:[
              Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:3),decoration:BoxDecoration(color:const Color(0xFFF3F4F6),borderRadius:BorderRadius.circular(6)),child:const Icon(Icons.wifi_rounded,size:14,color:Color(0xFF6B7280))),
              const SizedBox(width:8),
              Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:3),decoration:BoxDecoration(color:const Color(0xFFF3F4F6),borderRadius:BorderRadius.circular(6)),child:const Icon(Icons.local_parking_rounded,size:14,color:Color(0xFF6B7280))),
              const SizedBox(width:8),
              Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:3),decoration:BoxDecoration(color:const Color(0xFFF3F4F6),borderRadius:BorderRadius.circular(6)),child:const Icon(Icons.ac_unit_rounded,size:14,color:Color(0xFF6B7280))),
              const Spacer(),
              Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
                if(discount > 0) ...[
                  Text('NPR $originalPrice',style:const TextStyle(fontSize:12,color:Color(0xFF9CA3AF),fontWeight:FontWeight.w600,decoration:TextDecoration.lineThrough)),
                  const SizedBox(width:6),
                ],
                Text('NPR ${h['price']}',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:AppColors.primary)),
                const Text('/night',style:TextStyle(fontSize:11,color:Color(0xFF9CA3AF),fontWeight:FontWeight.w600)),
              ]),
            ]),
            const SizedBox(height:12),
            SizedBox(width:double.infinity,child:GestureDetector(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>HotelDetailsScreen(arguments:{'hotelId':h['id']}))),
              child:Container(padding:const EdgeInsets.symmetric(vertical:12),decoration:BoxDecoration(color:AppColors.primary,borderRadius:BorderRadius.circular(12),boxShadow:[BoxShadow(color:AppColors.primary.withOpacity(0.2),blurRadius:10,offset:const Offset(0,4))]),
                child:const Center(child:Row(mainAxisSize:MainAxisSize.min,children:[Text('Book Now',style:TextStyle(color:Colors.white,fontSize:14,fontWeight:FontWeight.w800)),SizedBox(width:6),Icon(Icons.arrow_forward_rounded,color:Colors.white,size:16)]))))),
          ])),
        ]),
      ),
    );
  }
}
