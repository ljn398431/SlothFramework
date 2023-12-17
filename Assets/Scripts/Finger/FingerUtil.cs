using System.Collections.Generic;
using UnityEngine;
using XLua;

namespace DigitalRubyShared {
	[LuaCallCSharp]
	public static class FingerUtil {
		[CSharpCallLua]
		public delegate void OnTapEvent(float x, float y);

		[CSharpCallLua]
		public delegate void OnScaleEvent(float scale);

		[CSharpCallLua]
		public delegate void OnPanEvent(float x, float y);

		private interface IGestureDataWrapper {
			void Trigger(GestureRecognizer gesture);

			void Dispose();
		}

		private abstract class GestureDataBase : IGestureDataWrapper {
			protected readonly GestureRecognizer _recognizer;

			protected GestureDataBase(GestureRecognizer recognizer) {
				_recognizer = recognizer;
				_recognizer.StateUpdated += Filter;
				FingersScript.Instance.AddGesture(_recognizer);
			}

			private void Filter(GestureRecognizer gesture) {
				if( gesture.State == GestureRecognizerState.Executing || gesture.State == GestureRecognizerState.Ended ) {
					Trigger(gesture);
				}
			}

			public abstract void Trigger(GestureRecognizer gesture);

			public void Dispose() {
				_recognizer.StateUpdated -= Filter;
				if( !FingersScript.Instance ) {
					return;
				}
				FingersScript.Instance.RemoveGesture(_recognizer);
			}
		}

		private class ScaleGestureDataWrapper : GestureDataBase {
			private readonly OnScaleEvent _callback;

			public ScaleGestureDataWrapper(OnScaleEvent callback) : base(new ScaleGestureRecognizer()) {
				_callback = callback;
			}

			public override void Trigger(GestureRecognizer gesture) {
				var scaleGesture = gesture as ScaleGestureRecognizer;
				_callback.Invoke(scaleGesture.ScaleMultiplier);
			}
		}

		private class PanGestureDataWrapper : GestureDataBase {
			private readonly OnPanEvent _callback;

			public PanGestureDataWrapper(OnPanEvent callback, int numberOfFinger) : base(new PanGestureRecognizer() {
				MinimumNumberOfTouchesToTrack = numberOfFinger
			}) {
				_callback = callback;
			}

			public override void Trigger(GestureRecognizer gesture) {
				var panGesture = gesture as PanGestureRecognizer;
				_callback.Invoke(panGesture.DeltaX, panGesture.DeltaY);
			}
		}

		private class TapGestureDataWrapper : GestureDataBase {
			private readonly OnTapEvent _callback;

			public TapGestureDataWrapper(OnTapEvent callback, int numberOfTapRequire) : base(new TapGestureRecognizer()) {
				_callback = callback;
				var tapGestureRecognizer = _recognizer as TapGestureRecognizer;
				tapGestureRecognizer.NumberOfTapsRequired = numberOfTapRequire;
			}

			public override void Trigger(GestureRecognizer gesture) {
				var tapGesture = gesture as TapGestureRecognizer;
				GestureTouch touch = tapGesture.TapTouches[0];
				_callback.Invoke(touch.X, touch.Y);
			}
		}

		private static readonly Dictionary<object, IGestureDataWrapper> _callbacks = new Dictionary<object, IGestureDataWrapper>();

		public static void RegisterTap(OnTapEvent callback, int numberOfTapRequire = 1) {
			_callbacks.Add(callback, new TapGestureDataWrapper(callback, numberOfTapRequire));
		}

		public static void UnregisterTap(OnTapEvent callback) {
			Unregister(callback);
		}

		public static void RegisterScale(OnScaleEvent callback) {
			_callbacks.Add(callback, new ScaleGestureDataWrapper(callback));
		}

		public static void UnregisterScale(OnScaleEvent callback) {
			Unregister(callback);
		}

		public static void RegisterPan(OnPanEvent callback, int numberOfFinger = 1) {
			Debug.Log("--RegisterPan");
			_callbacks.Add(callback, new PanGestureDataWrapper(callback, numberOfFinger));
		}

		public static void UnregisterPan(OnPanEvent callback) {
			Unregister(callback);
		}

		private static void Unregister(object key) {
			IGestureDataWrapper wrapper = _callbacks[key];
			wrapper.Dispose();
			_callbacks.Remove(key);
		}
	}
}