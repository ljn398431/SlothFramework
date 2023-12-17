using System.Collections;
using Extend.Service;
using Extend.Common;
using UnityEngine;
using UnityEngine.AddressableAssets;

namespace Extend
{
	public class AppStartUp : MonoBehaviour
	{
		private void Start()
		{
			VersionService service = new VersionService();
			service.Initialize();
			StartCoroutine(InitAddressable(service));
		}

		private IEnumerator InitAddressable(VersionService service)
		{
			var init = Addressables.InitializeAsync();
			yield return init;
			service.StartLua();
		}
	}
}