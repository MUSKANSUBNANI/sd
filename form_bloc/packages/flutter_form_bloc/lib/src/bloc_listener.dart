import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Signature for the listener function which takes the [BuildContext] along with the bloc state
/// and is responsible for executing in response to state changes.
typedef BlocWidgetListener<S> = void Function(BuildContext context, S state);

/// Signature for the condition function which takes the penultimate state, previous state and the current state
/// and is responsible for returning a `bool` which determines whether or not to call [BlocWidgetListener]
/// of [BlocListener] with the current state.
typedef BlocListenerCondition<S> = bool Function(
    S penultimate, S previous, S current);

class BlocListener<B extends Bloc<dynamic, S>, S>
    extends BlocListenerBase<B, S> {
  /// The [Widget] which will be rendered as a descendant of the [BlocListener].
  final Widget child;

  /// Takes a [BlocWidgetListener] and an optional [Bloc]
  /// and invokes the listener in response to state changes in the bloc.
  /// It should be used for functionality that needs to occur only in response to a state change
  /// such as navigation, showing a [SnackBar], showing a [Dialog], etc...
  /// The `listener` is guaranteed to only be called once for each state change unlike the
  /// `builder` in [BlocBuilder].
  ///
  /// If the bloc parameter is omitted, [BlocListener] will automatically perform a lookup using
  /// [BlocProvider] and the current [BuildContext].
  ///
  /// ```dart
  /// BlocListener<BlocA, BlocAState>(
  ///   listener: (context, state) {
  ///     /// do stuff here based on BlocA's state
  ///   },
  ///   child: Container(),
  /// )
  /// ```
  /// Only specify the bloc if you wish to provide a bloc that is otherwise
  /// not accessible via [BlocProvider] and the current [BuildContext].
  ///
  /// ```dart
  /// BlocListener<BlocA, BlocAState>(
  ///   bloc: blocA,
  ///   listener: (context, state) {
  ///     /// do stuff here based on BlocA's state
  ///   },
  ///   child: Container(),
  /// )
  /// ```
  ///
  /// An optional `condition` can be implemented for more granular control
  /// over when `listener` is called.
  /// The `condition` function will be invoked on each bloc state change.
  /// The `condition` takes the penultimate state, previous state and current state and must return a `bool`
  /// which determines whether or not the `listener` function will be invoked.
  /// The penultimate state and previous state will be initialized to `state` when the [BlocListener] is initialized.
  /// `condition` is optional and if it isn't implemented, it will default to return `true`.
  ///
  /// ```dart
  /// BlocListener<BlocA, BlocAState>(
  ///   condition: (penultimateState, previousState, state) {
  ///     // return true/false to determine whether or not
  ///     // to invoke listener with state
  ///   },
  ///   listener: (context, state) {
  ///     // do stuff here based on BlocA's state
  ///   }
  ///   child: Container(),
  /// )
  /// ```
  const BlocListener({
    Key key,
    @required BlocWidgetListener<S> listener,
    B bloc,
    BlocListenerCondition<S> condition,
    this.child,
  })  : assert(listener != null),
        super(
          key: key,
          listener: listener,
          bloc: bloc,
          condition: condition,
        );

  @override
  Widget build(BuildContext context) => child;
}

abstract class BlocListenerBase<B extends Bloc<dynamic, S>, S>
    extends StatefulWidget {
  /// The [Bloc] whose state will be listened to.
  /// Whenever the bloc's state changes, `listener` will be invoked.
  final B bloc;

  /// The [BlocWidgetListener] which will be called on every state change.
  /// This listener should be used for any code which needs to execute
  /// in response to a state change ([Transition]).
  /// The state will be the `nextState` for the most recent [Transition].
  final BlocWidgetListener<S> listener;

  /// The [BlocListenerCondition] that the [BlocListenerBase] will invoke.
  /// The `condition` function will be invoked on each bloc state change.
  /// The `condition` takes the penultimate state, previous state and current state and must return a `bool`
  /// which determines whether or not the `listener` function will be invoked.
  /// The penultimate state and previous state will be initialized to `state` when the [BlocListenerBase] is initialized.
  /// `condition` is optional and if it isn't implemented, it will default to return `true`.
  final BlocListenerCondition<S> condition;

  /// Base class for widgets that listen to state changes in a specified [Bloc].
  ///
  /// A [BlocListenerBase] is stateful and maintains the state subscription.
  /// The type of the state and what happens with each state change
  /// is defined by sub-classes.
  const BlocListenerBase({
    Key key,
    this.listener,
    this.bloc,
    this.condition,
  }) : super(key: key);

  State<BlocListenerBase<B, S>> createState() => _BlocListenerBaseState<B, S>();

  /// Returns a [Widget] based on the [BuildContext].
  Widget build(BuildContext context);
}

class _BlocListenerBaseState<B extends Bloc<dynamic, S>, S>
    extends State<BlocListenerBase<B, S>> {
  StreamSubscription<S> _subscription;
  S _penultimateState;
  S _previousState;
  B _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? BlocProvider.of<B>(context);
    _previousState = _bloc?.state;
    _penultimateState = _bloc?.state;
    _subscribe();
  }

  @override
  void didUpdateWidget(BlocListenerBase<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Stream<S> oldState = oldWidget.bloc ?? BlocProvider.of<B>(context);
    final Stream<S> state = widget.bloc ?? oldState;
    if (oldState != state) {
      if (_subscription != null) {
        _unsubscribe();
        _bloc = widget.bloc ?? BlocProvider.of<B>(context);
        _previousState = _bloc?.state;
        _penultimateState = _bloc?.state;
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(context);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (_bloc?.state != null) {
      _subscription = _bloc.skip(1).listen((S state) {
        if (widget.condition?.call(_penultimateState, _previousState, state) ??
            true) {
          widget.listener(context, state);
        }
        _penultimateState = _previousState;
        _previousState = state;
      });
    }
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
  }
}
