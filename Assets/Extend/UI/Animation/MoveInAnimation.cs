using System;
using DG.Tweening;
using Extend.Common;
using UnityEngine;

namespace Extend.UI.Animation {
	[Serializable]
	public class MoveInAnimation : StateAnimation {
		public enum Direction {
			Left,
			Top,
			Right,
			Bottom
		}

		[SerializeField]
		private bool m_customFromTo;

		[SerializeField]
		private Vector3 m_moveTo;

		[SerializeField]
		private Vector3 m_moveFrom;

		[SerializeField, LabelText("Move From")]
		private Direction m_moveInDirection = Direction.Left;

		public Direction MoveInDirection {
			get => m_moveInDirection;
			set {
				m_moveInDirection = value;
				m_dirty = true;
			}
		}

		protected override Tween DoGenerateTween(RectTransform t, Vector3 start) {
			if( m_customFromTo ) {
				return t.DOAnchorPos3D(start + m_moveTo, Duration).SetEase(Ease).SetDelay(Delay).ChangeStartValue(start + m_moveFrom);
			}

			Vector2 startPosition = start;
			var size = t.rect.size;
			Vector2 position = start;
			switch( MoveInDirection ) {
				case Direction.Left:
					startPosition.x -= size.x;
					break;
				case Direction.Top:
					startPosition.y += size.y;
					break;
				case Direction.Right:
					startPosition.x += size.x;
					break;
				case Direction.Bottom:
					startPosition.y -= size.y;
					break;
				default:
					throw new ArgumentOutOfRangeException();
			}

			return t.DOAnchorPos(position, Duration).SetDelay(Delay).SetEase(Ease).ChangeStartValue(startPosition);
		}
	}
}