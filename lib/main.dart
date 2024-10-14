import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// Root widget of the application.
///
/// Builds the [MaterialApp] and displays the [DockHomePage].
class MyApp extends StatelessWidget {
  /// Creates a [MyApp] instance.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Draggable Dock',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DockHomePage(),
    );
  }
}

/// Home page displaying the [Dock] widget.
///
/// Provides the main scaffold and centers the dock in the view.
class DockHomePage extends StatelessWidget {
  /// Creates a [DockHomePage] instance.
  const DockHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draggable Dock'),
      ),
      body: Center(
        child: Dock<IconData>(
          items: const [
            Icons.person,
            Icons.message,
            Icons.call,
            Icons.camera,
            Icons.photo,
          ],
          builder: (e) {
            return Container(
              constraints: const BoxConstraints(minWidth: 48),
              height: 48,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.primaries[e.hashCode % Colors.primaries.length],
              ),
              child: Center(child: Icon(e, color: Colors.white)),
            );
          },
        ),
      ),
    );
  }
}

/// A customizable dock widget that displays draggable and sortable items.
///
/// The [Dock] arranges its [items] horizontally and allows users to reorder them
/// by dragging. Animations are used to smoothly transition items during reordering.
class Dock<T> extends StatefulWidget {
  /// Creates a [Dock] widget.
  ///
  /// The [items] and [builder] parameters must not be null.
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial list of items to display in the dock.
  final List<T> items;

  /// Builder function to create each dock item widget.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State class for the [Dock] widget.
///
/// Manages the current list of items and handles drag-and-drop reordering.
class _DockState<T> extends State<Dock<T>> {
  /// Current list of items being displayed and manipulated.
  late List<T> _items;

  /// Index of the item currently being dragged. Null if no item is being dragged.
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    _items = widget.items.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          return _DraggableDockItem<T>(
            key: ValueKey(item),
            item: item,
            index: index,
            isDragging: _draggingIndex == index,
            onDragStarted: () {
              setState(() {
                _draggingIndex = index;
              });
            },
            onDragEnded: () {
              setState(() {
                _draggingIndex = null;
              });
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                final movedItem = _items.removeAt(oldIndex);
                _items.insert(newIndex, movedItem);
              });
            },
            builder: widget.builder,
          );
        }),
      ),
    );
  }
}

/// A single draggable item within the [Dock].
///
/// Handles the drag interactions and provides visual feedback during dragging.
class _DraggableDockItem<T> extends StatefulWidget {
  /// Creates a draggable dock item.
  const _DraggableDockItem({
    required Key key,
    required this.item,
    required this.index,
    required this.isDragging,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onReorder,
    required this.builder,
  }) : super(key: key);

  /// The data item represented by this widget.
  final T item;

  /// The current index of this item in the dock.
  final int index;

  /// Whether this item is currently being dragged.
  final bool isDragging;

  /// Callback when the drag starts.
  final VoidCallback onDragStarted;

  /// Callback when the drag ends.
  final VoidCallback onDragEnded;

  /// Callback when the item needs to be reordered.
  ///
  /// Provides the old and new indices for the item.
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Builder function to create the visual representation of the dock item.
  final Widget Function(T) builder;

  @override
  State<_DraggableDockItem<T>> createState() => _DraggableDockItemState<T>();
}

/// State class for [_DraggableDockItem].
///
/// Manages the animation and drag target detection for reordering.
class _DraggableDockItemState<T> extends State<_DraggableDockItem<T>>
    with SingleTickerProviderStateMixin {
  /// Animation controller for scaling the icon during dragging.
  late final AnimationController _scaleController;

  /// Animation for scaling the icon.
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _DraggableDockItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDragging) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  /// Initiates the drag operation.
  void _startDrag() {
    widget.onDragStarted();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != widget.index,
      onAcceptWithDetails: (draggedIndex) {
        widget.onReorder(draggedIndex.data, widget.index);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onLongPress: _startDrag,
          child: Draggable<int>(
            data: widget.index,
            axis: Axis.horizontal,
            feedback: _buildFeedback(),
            childWhenDragging: Opacity(
              opacity: 0.5,
              child: widget.builder(widget.item),
            ),
            onDragStarted: widget.onDragStarted,
            onDragEnd: (_) => widget.onDragEnded(),
            child: AnimatedScale(
              scale: widget.isDragging ? _scaleAnimation.value : 1.0,
              duration: const Duration(milliseconds: 200),
              child: widget.builder(widget.item),
            ),
          ),
        );
      },
    );
  }

  /// Builds the widget shown as feedback during dragging.
  Widget _buildFeedback() {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors
              .primaries[widget.item.hashCode % Colors.primaries.length]
              .withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            widget.item as IconData,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
