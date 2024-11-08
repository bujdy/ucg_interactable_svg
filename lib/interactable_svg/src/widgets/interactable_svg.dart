import 'package:flutter/material.dart';

import '../models/region.dart';
import '../parser.dart';
import '../size_controller.dart';
import './region_painter.dart';

class UcgInteractableSvg extends StatefulWidget {
  final double? width;
  final double? height;
  final String svgAddress;
  final Function(Region region) onChanged;
  final Color? selectedColor;
  final bool isMultiSelectable;
  final Color? Function(int partId, Color? defaultColor)? unSelectableColor;
  final String? Function(int partId, String? title)? unSelectableText;

  final BoxFit fit;
  final Alignment alignment;
  final Clip clipBehavior;

  const UcgInteractableSvg({
    Key? key,
    required this.svgAddress,
    required this.onChanged,
    this.width,
    this.height,
    this.selectedColor,
    this.isMultiSelectable = false,
    this.unSelectableColor,
    this.unSelectableText,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.clipBehavior = Clip.hardEdge,
  }) : super(key: key);

  @override
  UcgInteractableSvgState createState() => UcgInteractableSvgState();
}

class UcgInteractableSvgState extends State<UcgInteractableSvg> {
  final List<Region> _regionList = [];

  List<Region> selectedRegion = [];
  SizeController? _sizeController;
  Size? mapSize;

  @override
  void initState() {
    super.initState();
    Parser.refreshClass();
    SizeController.refreshClass();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRegionList();
    });
  }

  _loadRegionList() async {
    final list = await Parser.instance.svgToRegionList(widget.svgAddress, widget.unSelectableText, widget.unSelectableColor);
    _sizeController = SizeController.instance;
    _regionList.clear();
    setState(() {
      _regionList.addAll(list);
      mapSize = _sizeController?.mapSize;
    });
  }

  void clearSelect() {
    setState(() {
      selectedRegion.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, contstraints) {
      final Rect viewport = Offset.zero & Size(widget.width ?? 0, widget.height ?? 0);
      double? width = widget.width;
      double? height = widget.height;
      if (width == null && height == null) {
        width = viewport.width;
        height = viewport.height;
      } else if (height != null) {
        width = height / viewport.height * viewport.width;
      } else if (width != null) {
        height = width / viewport.width * viewport.height;
      }

      return SizedBox(
        width: width,
        height: height,
        child: FittedBox(
          fit: widget.fit,
          alignment: widget.alignment,
          clipBehavior: widget.clipBehavior,
          child: SizedBox.fromSize(
            size: viewport.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (var region in _regionList) _buildStackItem(region),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStackItem(Region region) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () => toggleButton(region),
      child: CustomPaint(
        isComplex: true,
        size: Size(widget.width ?? mapSize?.width ?? 0, widget.height ?? mapSize?.height ?? 0),
        painter: RegionPainter(
          region: region,
          selectedRegion: selectedRegion,
          selectedColor: widget.selectedColor,
        ),
      ),
    );
  }

  void toggleButton(Region region) {
    setState(() {
      if (selectedRegion.contains(region)) {
        selectedRegion.remove(region);
        setState(() {});
      } else {
        if (widget.isMultiSelectable) {
          selectedRegion.add(region);
          setState(() {});
        } else {
          selectedRegion.clear();
          selectedRegion.add(region);
          setState(() {});
        }
      }
      widget.onChanged.call(region);
    });
  }
}
