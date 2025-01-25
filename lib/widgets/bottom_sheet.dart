import 'package:flutter/material.dart';
import 'package:the_carbon_conscious_traveller/widgets/drag_handle.dart';
import 'package:the_carbon_conscious_traveller/widgets/travel_mode_view.dart';

class TravelModeBottomSheet extends StatelessWidget {
  const TravelModeBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
        initialChildSize: 0.3,
        minChildSize: 0.15,
        maxChildSize: 0.6,
        snap: true,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      const SliverAppBar(
                        automaticallyImplyLeading: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        pinned: true,
                        expandedHeight: 20,
                        flexibleSpace: FlexibleSpaceBar(
                          title: DragHandle(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: const TravelModeView()),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}
