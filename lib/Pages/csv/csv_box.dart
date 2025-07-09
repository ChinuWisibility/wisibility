import 'package:fluent_ui/fluent_ui.dart';
import 'csv_table.dart';

class CsvBox extends StatefulWidget {
  final String type;
  final int dataRowIdx;
  final Map<String, dynamic> col;
  final List<GlobalKey> keys;
  final Map<String, Color> cellColors;
  final double csvBoxWidth;
  final Function(Connection, String, String) onConnection;
  final ScrollController? idmScrollController; // Added for IDM

  const CsvBox({
    required this.type,
    required this.dataRowIdx,
    required this.col,
    required this.keys,
    required this.cellColors,
    required this.csvBoxWidth,
    required this.onConnection,
    this.idmScrollController, // Added for IDM
    super.key,
  });

  @override
  State<CsvBox> createState() => _CsvBoxState();
}

class _CsvBoxState extends State<CsvBox> {
  Map<int, Size> cellSizes = {};

  Size? getCellSize(int idx) {
    final context = widget.keys[idx].currentContext;
    if (context != null) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        return box.size;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Color getTextColorForBackground(Color background) {
      return background.computeLuminance() < 0.5 ? Colors.white : Colors.black;
    }

    // Use the same ListView for all types, no internal scroll for IDM
    Widget listView = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // No internal scrolling
      itemCount: (widget.col['header'] as List<String>).length,
      separatorBuilder: (_, __) => Container(height: 0),
      itemBuilder: (context, idx) {
        final item = widget.col['header'][idx];
        final cellKey = '${widget.type}-${widget.dataRowIdx}-$idx';
        final cellColor = widget.cellColors[cellKey] ?? Colors.white;

        return Padding(
          padding: const EdgeInsets.all(5.0),
          child: DragTarget<Map<String, dynamic>>(
            onWillAccept: (data) {
              return !(data?['type'] == widget.type &&
                  data?['col'] == widget.dataRowIdx &&
                  data?['idx'] == idx);
            },
            onAccept: (data) {
              final fromKey =
                  '${data['type']}-${data['col']}-${data['idx']}';
              final toKey = '${widget.type}-${widget.dataRowIdx}-$idx';
              widget.onConnection(
                Connection(
                  data['type'],
                  data['col'],
                  data['idx'],
                  widget.type,
                  widget.dataRowIdx,
                  idx,
                ),
                fromKey,
                toKey,
              );
            },
            builder: (context, candidateData, rejectedData) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final size = getCellSize(idx);
                    if (size != null && cellSizes[idx] != size) {
                      setState(() {
                        cellSizes[idx] = size;
                      });
                    }
                  });
                  return Draggable<Map<String, dynamic>>(
                    data: {
                      'type': widget.type,
                      'col': widget.dataRowIdx,
                      'idx': idx,
                    },
                    feedback: Container(
                      width: cellSizes[idx]?.width ?? constraints.maxWidth,
                      height: cellSizes[idx]?.height ?? null,
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue, width: 1),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.5,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[30],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    child: Container(
                      key: widget.keys[idx],
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.all(
                          Radius.circular(4),
                        ),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: getTextColorForBackground(cellColor),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );

    // Use the same widget for all types, no special case for IDM
    Widget listWidget = listView;

    return Container(
      width: widget.csvBoxWidth,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        color: Colors.grey[50],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CSV ${widget.dataRowIdx + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            listWidget,
          ],
        ),
      ),
    );
  }}