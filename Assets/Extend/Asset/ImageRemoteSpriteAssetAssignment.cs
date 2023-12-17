using Extend.Network.HttpClient;
using UnityEngine;
using UnityEngine.UI;
using XLua;

namespace Extend.Asset {
	[LuaCallCSharp, RequireComponent(typeof(Image))]
	public class ImageRemoteSpriteAssetAssignment : MonoBehaviour {
		private Image m_img;
		private string m_spriteRemotePath;
		private Sprite m_downloadedSprite;
		private Sprite m_defaultSprite;
		public bool isAspectWidthMatch = false;
		private void Awake() {
			m_img = GetComponent<Image>();
			m_defaultSprite = m_img.sprite;
			if(m_defaultSprite == null)
				m_img.enabled = false;
		}
		
		public string SpriteRemotePath {
			get => m_spriteRemotePath;
			set {
				if( m_spriteRemotePath == value )
					return;
				m_spriteRemotePath = value;
				if( string.IsNullOrEmpty(m_spriteRemotePath) ) {
					m_img.sprite = m_defaultSprite;
					if(m_img.sprite == null)
						m_img.enabled = false;
					return;
				}
				var fileRequest = new HttpFileRequest();
				m_img.enabled = false;
				fileRequest.RequestImage(m_spriteRemotePath, texture => {
					if (!m_img) {
						return;
					}

					if (texture != null)
					{
						m_img.sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), Vector2.zero);
						m_downloadedSprite = m_img.sprite;
						if (isAspectWidthMatch)
						{
							m_img.rectTransform.sizeDelta = new Vector2(m_img.rectTransform.sizeDelta.x,m_img
								.rectTransform.sizeDelta.x * m_img.sprite.rect.height / m_img.sprite.rect.width);
							LayoutRebuilder.ForceRebuildLayoutImmediate(this.transform.parent.GetComponent<RectTransform>());
							//GetComponentInParent<UpdateAILayout>().ForceUpdate();
						}
						m_img.enabled = true;
					}
					else
					{
						m_img.sprite = m_defaultSprite;
						m_img.enabled = false;
					}
				});
			}
		}

		private void OnDestroy() {
			if( m_downloadedSprite ) {
				Destroy(m_downloadedSprite);
			}
		}
	}
}