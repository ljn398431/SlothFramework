using System;
using UnityEngine;
using UnityEngine.UI;

namespace Extend.StateActionGroup.Behaviour {
	[Serializable]
	public class SetOutlineColorBehaviourData : BehaviourDataBase {
		[SerializeField]
		private Color m_color;

		public override void ApplyToBehaviour(BehaviourBase behaviour) {
			var activeBehaviour = behaviour as SetOutlineColorBehaviour;
			if(!activeBehaviour.outline)
				return;
			activeBehaviour.outline.SetColor(m_color);
		}

		public override void CopySourceBehaviour(BehaviourBase behaviour) {
			var activeBehaviour = behaviour as SetOutlineColorBehaviour;
			if(!activeBehaviour.outline)
				return;
			m_color = activeBehaviour.outline.GetColor();
		}
	}
	
	[Serializable]
	public class SetOutlineColorBehaviour : BehaviourBase {
		public SetOutline outline;
		public override void Start() {
			m_data.ApplyToBehaviour(this);
		}

		public override void Exit() {
		}

		public override bool Complete => true;

		public override BehaviourDataBase CreateDefaultData() {
			var data = new SetOutlineColorBehaviourData();
			data.CopySourceBehaviour(this);
			data.TargetId = Id;
			return data;
		}
	}
}