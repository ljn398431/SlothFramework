using System.Collections.Generic;
using Extend.Common;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace Extend.LuaBindingEvent {
	public class LuaBindingClickLongTapEvent : LuaBindingEventBase , IPointerDownHandler, IPointerUpHandler,
		/*IPointerExitHandler,*/ IBeginDragHandler, IDragHandler, IEndDragHandler
	{
		[ReorderList, LabelText("On Long Tap ()"), SerializeField]
		private BindingEvent[] m_longTapEvent;
		[ReorderList, LabelText("On Shot Click  Up()"), SerializeField]
		private BindingEvent[] m_clickEvent;
		[ReorderList, LabelText("On Click Up()"), SerializeField]
		private BindingEvent[] m_clickUpEvent;
		[ReorderList, LabelText("On Click Down()"), SerializeField]
		private BindingEvent[] m_clickDownEvent;
		public float LongTapTime = 1f;
		public ScrollRect ScrollRect;
		float m_downTime;
		bool m_down = false;

		void Update()
		{
			if (!m_down) return;
			if (Time.time - m_downTime > LongTapTime)
			{
				TriggerPointerEvent("OnLongTap", m_longTapEvent, null);
				m_down = false;
			}
		}
		public void OnPointerDown(PointerEventData eventData)
		{
			m_downTime = Time.time;
			TriggerPointerEvent("OnClickDown", m_clickDownEvent, eventData);
			m_down = true;
		}
		public void OnPointerUp(PointerEventData eventData)
		{
			if (Time.time - m_downTime < LongTapTime)
			{
				TriggerPointerEvent("OnClickShot", m_clickEvent, eventData);
				m_down = false;
			}
			else
			{
				TriggerPointerEvent("OnClickEnd", m_clickUpEvent, eventData);
				m_down = false;
			}
		}

		//public void OnPointerExit(PointerEventData eventData)
		//{
		//	m_down = false;
		//}
		public void OnBeginDrag(PointerEventData eventData)
		{
			m_down = false;
			ScrollRect?.OnBeginDrag(eventData);
		}
		public void OnDrag(PointerEventData eventData)
		{
			ScrollRect?.OnDrag(eventData);
		}
		public void OnEndDrag(PointerEventData eventData)
		{
			ScrollRect?.OnEndDrag(eventData);
		}
	}
}