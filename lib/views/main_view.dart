import 'dart:async';
import 'package:flutter/material.dart';

import 'package:bonsoir/bonsoir.dart';

import '../helpers/constants.dart';
import '../components/cam_panel.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  createState()=>MainViewState();
}

class MainViewState extends State<MainView> {
  String _type = "_dartobservatory._tcp";

  BonsoirDiscovery? _discovery;
  List<ResolvedBonsoirService> _resolvedServices = [];

  //--------------------------------------------------------------------------//
  @override
  void initState() {
    super.initState();
    _discoverService();
  }

  //--------------------------------------------------------------------------//
  Future<void> _discoverService() async {
    _discovery = BonsoirDiscovery(type: _type);
    if (_discovery != null) {
      await _discovery!.ready;

      _discovery!.eventStream!.listen((event) {
        if (event.service != null) {
          ResolvedBonsoirService service = event.service as ResolvedBonsoirService;

          if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
            final index = _resolvedServices.indexWhere((ResolvedBonsoirService item) => item.ip == service.ip);
            if (index == -1 && service.ip.toString() != "null") {
              _resolvedServices.add(service);
              setState(() {});
            }
          } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
            _resolvedServices.remove(service);
            setState(() {});
          }
        }
      });
      await _discovery!.start();
    }
  }

  //--------------------------------------------------------------------------//
  void _refreshCameras() async {
    await _discovery!.stop();
    _resolvedServices.clear();
    setState(() {});
    _discovery = null;

    _discoverService();
  }


  //--------------------------------------------------------------------------//
  Widget _camGrid() {
    bool isTablet = MediaQuery.of(context).size.shortestSide > 600;
    bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    if (_resolvedServices.length > 0) {
      return SliverGrid(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          final ResolvedBonsoirService service = _resolvedServices[index];
          return Container(
            child: Card(
              child: CamPanel(service),
            ),
          );
        }, childCount: _resolvedServices.length),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: isTablet ? 600.0 : (isPortrait ? 400.0 : 600.0),
          childAspectRatio: 1.2,
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
        )
      );
    } else {
      return const SliverFillRemaining();
    }
  }

  //--------------------------------------------------------------------------//
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: AppBar(
        title: Text("MyCAM"),
        actions: [
          IconButton(onPressed: _refreshCameras, icon: Icon(Icons.refresh_outlined)),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _camGrid()
            ],
          )
        ],
      ),
    );
  }

}
