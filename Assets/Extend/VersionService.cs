using System;
using System.Collections;
using UnityEngine;
using System.Collections.Generic;
using System.IO;
using System.Text;
using Extend;
using Extend.Asset;
using Extend.Common;
using Extend.DebugUtil;
using Extend.LuaUtil;
using Extend.Network;
using Extend.Network.HttpClient;
using Extend.Render;
using Extend.SceneManagement;
using Extend.UI.i18n;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using UnityEngine.AddressableAssets;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using XLua;
using Object = UnityEngine.Object;

namespace Extend.Service
{
	/*
	 * @brief	（简要描述）
	 * @details	对该文档的详细说明和解释，可以换行
	 */
	[LuaCallCSharp]
	public class VersionService
	{
		public static readonly string CSVERSION = Application.version;
		public static string PLATFORMVERSION;
		public static string LUAVERSION;
		public static string RESVERSION;

		public static readonly string LUA_KEY = "lua";
		public static readonly string PLATFROM_KEY = "platform";
		public static readonly string RES_KEY = "res";

		public static VersionService Instance
		{
			get { return _instance; }
		}

		public static VersionService _instance;

		public static string ResUrl;
		public static bool IsChecking = true;

		public static bool ReLoadRes
		{
			get { return _reLoadRes; }
		}

		private static bool _reLoadRes = false;
		public string AccountId;
		public string luaUrl;
		public string luaFileMd5;
		public bool isBeginner = false;

		private string VersionPath
		{
			get
			{
				if (string.IsNullOrEmpty(_versionPath))
				{
					_versionPath = $"{Application.persistentDataPath}/versionFile.json";
				}

				return _versionPath;
			}
		}

		private string _versionPath;

		private static Dictionary<string, Version> _localVersionDic;
		private static Dictionary<string, Version> _serverVersionDic;

		private string _deviceInfo;
		public string _luaSavePath;

		public VersionService()
		{
			PLATFORMVERSION = GameSystemSetting.Get().SystemSetting.GetString("GAME", "Version");
			LUAVERSION = GameSystemSetting.Get().SystemSetting.GetString("GAME", "LuaVersion");
			RESVERSION = GameSystemSetting.Get().SystemSetting.GetString("GAME", "ResVersion");
			_luaSavePath = $"{Application.persistentDataPath}/BuiltInData";
			_localVersionDic = new Dictionary<string, Version>();
			_serverVersionDic = new Dictionary<string, Version>();
			isBeginner = false;
		}

		public int ServiceType { get; }

		[BlackList]
		public void Initialize()
		{
			SetDeviceInfo();
			Debug.LogWarning("=-----Initialize VersionService");
			InitVersionVariable();
			_instance = this;
			Application.quitting += () => {
				_instance = null;
			};
		}

		public void AddOrUpdate(Dictionary<string, Version> dic, string key, Version value)
		{
			if (dic.ContainsKey(key))
			{
				dic[key] = value;
			}
			else
			{
				dic.Add(key, value);
			}
		}

		public void ResetResVersion()
		{
			var resVer = GameSystemSetting.Get().SystemSetting.GetString("GAME", "ResVersion");
			AddOrUpdate(_localVersionDic, RES_KEY, Version.Parse(resVer));
		}
		
		private void SetDeviceInfo()
		{
			var info = GameSystemSetting.Get().SystemSetting.GetString("DEBUG", "DeviceInfo");
			Debug.Log("info is " + info);
			if (string.IsNullOrEmpty(info) || info == "Default")
			{
#if UNITY_ANDROID
				_deviceInfo = "Android";
#elif UNITY_IOS
_deviceInfo = "iOS";
#elif UNITY_STANDALONE_WIN ||UNITY_EDITOR
_deviceInfo = "Windows";
#else
_deviceInfo = "UnSurport";
#endif
			}
			else
			{
				_deviceInfo = info;
			}
		}

		private void InitVersionVariable()
		{
			AddOrUpdate(_localVersionDic, PLATFROM_KEY, Version.Parse(PLATFORMVERSION));
			AddOrUpdate(_localVersionDic, LUA_KEY, Version.Parse(LUAVERSION));
			AddOrUpdate(_localVersionDic, RES_KEY, Version.Parse(RESVERSION));
			if (File.Exists(VersionPath))
			{
				string json = File.ReadAllText(VersionPath);
				JObject JObj = JObject.Parse(json);

				string version = JObj[PLATFROM_KEY].ToString();
				var tmpVer = Version.Parse(version);
				var tmpLua = Version.Parse(JObj[LUA_KEY].ToString());
				var tmpRes = Version.Parse(JObj[RES_KEY].ToString());

				if (tmpVer.CompareTo(_localVersionDic[PLATFROM_KEY]) >= 0)
				{
					AddOrUpdate(_localVersionDic, PLATFROM_KEY, tmpVer);
				}
				else
				{
					File.Delete(VersionPath);
					DeleteLuaCache();
				}

				if (tmpLua.CompareTo(_localVersionDic[LUA_KEY]) >= 0)
				{
					AddOrUpdate(_localVersionDic, LUA_KEY, tmpLua);
				}
				else
				{
					DeleteLuaCache();
				}

				AddOrUpdate(_localVersionDic, RES_KEY, tmpRes);
				UpdateVersionVariable();
			}

			AddOrUpdate(_serverVersionDic, PLATFROM_KEY, _localVersionDic[PLATFROM_KEY]);
			AddOrUpdate(_serverVersionDic, LUA_KEY, _localVersionDic[LUA_KEY]);
			AddOrUpdate(_serverVersionDic, RES_KEY, _localVersionDic[RES_KEY]);
		}

		private void UpdateVersionVariable()
		{
			PLATFORMVERSION = _localVersionDic[PLATFROM_KEY].ToString();
			LUAVERSION = _localVersionDic[LUA_KEY].ToString();
			RESVERSION = _localVersionDic[RES_KEY].ToString();
		}

		public void ParseServerInfo(string info)
		{
			var serverInfo = JObject.Parse(info);

			Debug.Log(info);
			var PlatformVersion = Version.Parse(serverInfo["UnityVersion"]?.ToString() ?? string.Empty);
			var LuaVersion = Version.Parse(serverInfo["LuaVersion"]?.ToString() ?? string.Empty);
			var ResVersion = Version.Parse(serverInfo["ResourceVersion"]?.ToString() ?? string.Empty);
			luaUrl = serverInfo["LuaUrl"]?.ToString();
			luaFileMd5 = serverInfo["LuaFileMd5"]?.ToString();
			AddOrUpdate(_serverVersionDic, PLATFROM_KEY, PlatformVersion);
			AddOrUpdate(_serverVersionDic, LUA_KEY, LuaVersion);
			AddOrUpdate(_serverVersionDic, RES_KEY, ResVersion);

			ResUrl = serverInfo["ResourceUrl"]?.ToString();
			Debug.LogWarning(
				$"localPlatformVersion {_localVersionDic[PLATFROM_KEY]} _localLuaVersion {_localVersionDic[LUA_KEY]} _localResVersion {_localVersionDic[RES_KEY]}" +
				$" serverPlatformVersion {_serverVersionDic[PLATFROM_KEY]} serverLuaVersion {_serverVersionDic[LUA_KEY]} serverResVersion {_serverVersionDic[RES_KEY]}");
		}

		public void SaveVersion(string key)
		{
			if (_localVersionDic.ContainsKey(key))
			{
				if (_localVersionDic[key] == _serverVersionDic[key])
				{
					Debug.LogWarning($"local {key} equal to server {key} version not need to save file");
					return;
				}

				_localVersionDic[key] = _serverVersionDic[key];
			}
			else
			{
				Debug.LogError("VersionDic not contains key " + key);
			}

			SaveVersion();
		}

		public void DeleteLuaCache()
		{
			if (File.Exists(_luaSavePath))
				File.Delete(_luaSavePath);
		}

		private void SaveVersion()
		{
			UpdateVersionVariable();
			string json = JObject.FromObject(_localVersionDic).ToString(Formatting.None);
			File.WriteAllText(VersionPath, json);
		}

		private GameObject _consoleGO;
		private GameObject _wwiseGO;

		public void StartLua()
		{
			CSharpServiceManager.Register(new RenderFeatureService());
			CSharpServiceManager.Register(new SpriteAssetService());
			CSharpServiceManager.Register(new LuaVM());
			CSharpServiceManager.Register(new TickService());
			CSharpServiceManager.Register(new I18nService());
			CSharpServiceManager.Register(new SceneLoadManager());

			var mode = GameSystemSetting.Get().SystemSetting.GetString("GAME", "Mode");
			if (mode != "Shipping")
			{
				// using (var assetRef = AssetService.Get().Load<GameObject>("Console.prefab"))
				// {
				// 	var go = assetRef.Instantiate();
				// 	_consoleGO = go;
				// 	CSharpServiceManager.Register(go.GetComponent<InGameConsole>());
				// 	assetRef.Dispose();
				// }
			}

#if !UNITY_EDITOR
			var builder = new StringBuilder(2048);
			builder.AppendLine($"Unity: {Application.unityVersion}");
			builder.AppendLine($"App : {Application.identifier}:{Application.version} {Application.platform}");
			builder.AppendLine($"Device : {SystemInfo.deviceModel}, {SystemInfo.deviceName}, {SystemInfo.deviceType}");
			builder.AppendLine($"Battery : {SystemInfo.batteryStatus}, {SystemInfo.batteryLevel:0.00}");
			builder.AppendLine(
				$"Processor : {SystemInfo.processorType}, {SystemInfo.processorCount}, {SystemInfo.processorFrequency}");
			builder.AppendLine($"Graphics : {SystemInfo.graphicsDeviceName}, {SystemInfo.graphicsDeviceType}, " +
			                   $"{SystemInfo.graphicsDeviceVendor}, {SystemInfo.graphicsDeviceVersion}, " +
			                   $"GMEM : {SystemInfo.graphicsMemorySize}, SM{SystemInfo.graphicsShaderLevel}");

			builder.AppendLine(
				$"OS : {SystemInfo.operatingSystem}, MEM : {SystemInfo.systemMemorySize}, {SystemInfo.operatingSystemFamily}");
			builder.AppendLine("UsesReversedZBuffer : " + SystemInfo.usesReversedZBuffer);
			builder.Append(
				$"NPOT support : {SystemInfo.npotSupport}, Instancing support : {SystemInfo.supportsInstancing}, Texture Size : {SystemInfo.maxTextureSize}, " +
				$"Compute : {SystemInfo.supportsComputeShaders}");
			Debug.LogWarning(builder.ToString());

			var luaVm = CSharpServiceManager.Get<LuaVM>(CSharpServiceManager.ServiceType.LUA_SERVICE);
			var qualitySelector = luaVm.Global.Get<LuaFunction>("Global_QualitySelector");
			var quality =
				qualitySelector.Func<int, string, string>(SystemInfo.processorFrequency, SystemInfo.graphicsDeviceName);
			
			var urpAssetRef =
				AssetService.Get()
					.Load<UniversalRenderPipelineAsset>(
						$"Assets/Settings/UniversalRenderPipelineAsset_{quality}.asset");
			var urpAsset = urpAssetRef.GetObject() as UniversalRenderPipelineAsset;
			GraphicsSettings.renderPipelineAsset = urpAsset;
			QualitySettings.renderPipeline = urpAsset;

			var gameIniSystem =
				CSharpServiceManager.Get<GameSystemSetting>(CSharpServiceManager.ServiceType.GAME_SYSTEM_SERVICE);
			var systemSetting = gameIniSystem.SystemSetting;

			if (!Application.isMobilePlatform)
			{
				string qualityLevelName = "MOBILE.QUALITY." + quality.ToUpper();
				var maxVerticalPixelCount = systemSetting.GetInt(qualityLevelName, "MaxShortEdgePixel");
				var renderScale = 1.0f;
				var srpBatcher = systemSetting.GetBool(qualityLevelName, "SRPBatcher");
				
				urpAsset.renderScale = renderScale;
				urpAsset.useSRPBatcher = srpBatcher;
				Debug.LogWarning($"renderScale : {renderScale}, useSRPBatcher : {srpBatcher}");
			}
#endif
			var maxInstantiateDuration =
				GameSystemSetting.Get().SystemSetting.GetDouble("GAME", "MaxInstantiateDuration");
			AssetService.Get().AfterSceneLoaded((float)maxInstantiateDuration);

			HttpFileRequest.CacheFileExpireCheck();
			var lua = CSharpServiceManager.Get<LuaVM>(CSharpServiceManager.ServiceType.LUA_SERVICE);
			lua.StartUp();
			IsChecking = false;
			_isClean = false;
			
		}

		private bool _isClean = false;
		public void ReStartService()
		{
			Clear();
			
			CSharpServiceManager.Shutdown();
			CSharpServiceManager.Initialize();
			CSharpServiceManager.Register(new ErrorLogToFile());
			CSharpServiceManager.Register(new StatService());
			CSharpServiceManager.Register(new AssetService());
			CSharpServiceManager.Register(new GameSystemSetting());

			CSharpServiceManager.Register(new NetworkService());
			CSharpServiceManager.Register(new GlobalCoroutineRunnerService());
			_reLoadRes = true;
			Addressables.ClearDependencyCacheAsync("Assets/Res/Console.prefab");
		}

		public void Clear()
		{
			if (!_isClean)
			{
				Debug.LogWarning("Recycle _consoleGO and _wwiseGO");
				AssetService.Recycle(_consoleGO);
				AssetService.Recycle(_wwiseGO);
				Object.DestroyImmediate(_wwiseGO);
				_isClean = true;
			}
		}

		public bool CompareVersion(string key)
		{
			if (_localVersionDic.ContainsKey(key))
			{
				return _localVersionDic[key].CompareTo(_serverVersionDic[key]) < 0;
			}
			else
			{
				Debug.LogError("VersionDic not contains key " + key);
				return false;
			}
		}

		public static string GetVersion(string key)
		{
			if (_localVersionDic.ContainsKey(key))
			{
				return _localVersionDic[key].ToString();
			}
			else
			{
				Debug.LogError("VersionDic not contains key " + key);
				return "";
			}
		}

		public string GetDeviceInfo()
		{
			return _deviceInfo;
		}

		public static void HasAnyUpdate(string acid, Action<bool> callback)
		{
#if UNITY_EDITOR
			var isShowVersion = UnityEditor.EditorPrefs.GetBool("openVersion", false);
			if (!isShowVersion)
			{
				callback?.Invoke(false);
				return;
			}
#elif FULL_PACKAGE
			callback?.Invoke(false);
				return;
#endif
			Instance.AccountId = acid;
			var coroutine =
				CSharpServiceManager.Get<GlobalCoroutineRunnerService>(CSharpServiceManager.ServiceType
					.COROUTINE_SERVICE);
			coroutine.StartCoroutine(CheckUpdate(callback));
		}

		public static IEnumerator CheckUpdate(Action<bool> callback)
		{
			// var op = new UpdateVersionOperation(Instance);
			// yield return op.Start();
			yield return 0;
			if (callback != null)
				callback(Instance.CompareVersion(LUA_KEY) || Instance.CompareVersion(RES_KEY));
		}
	}
}