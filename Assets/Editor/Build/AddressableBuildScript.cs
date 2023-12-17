using System;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using System.Linq;
using System.Text;
using UnityEditor;
using UnityEditor.AddressableAssets;
using UnityEditor.AddressableAssets.Build;
using UnityEditor.AddressableAssets.Build.AnalyzeRules;
using UnityEditor.AddressableAssets.Settings;
using UnityEditor.AddressableAssets.Settings.GroupSchemas;
using UnityEngine.AddressableAssets;

namespace LifeGlory.Editor
{
	/*
	 * @brief	（简要描述）
	 * @details	对该文档的详细说明和解释，可以换行
	 */
	public class AddressableBuildScript
	{
		public static string buildScriptPath
			= "Assets/AddressableAssetsData/DataBuilders/BuildScriptPackedMode.asset";

		public static string settingsPath
			= "Assets/AddressableAssetsData/AddressableAssetSettings.asset";

		public static string contentBinPath
			= "Assets/AddressableAssetsData/";
		public static string profileName = "Int";

		public static AddressableAssetSettings Settings
		{
			get
			{
				if (_settings == null)
				{
					_settings
						= AssetDatabase.LoadAssetAtPath<ScriptableObject>(settingsPath)
							as AddressableAssetSettings;
				}

				if (_settings == null)
				{
					Debug.LogError("AddressableAssetSettings scripts object is null");
				}

				return _settings;
			}
		}

		private static AddressableAssetSettings _settings;

		public static void SetProfile(string profile)
		{
			string profileId = Settings.profileSettings.GetProfileId(profile);
			if (String.IsNullOrEmpty(profileId))
				Debug.LogWarning($"Couldn't find a profile named, {profile}, " +
				                 $"using current profile instead.");
			else
				Settings.activeProfileId = profileId;
		}

		private static void SetBuilder(IDataBuilder builder)
		{
			int index = Settings.DataBuilders.IndexOf((ScriptableObject)builder);

			if (index > 0)
				Settings.ActivePlayerDataBuilderIndex = index;
			else
				Debug.LogWarning($"{builder} must be added to the " +
				                 $"DataBuilders list before it can be made " +
				                 $"active. Using last run builder instead.");
		}

		private static bool BuildAddressableContent()
		{
			SetWwisePlatform();
			AddressableAssetSettings
				.BuildPlayerContent(out AddressablesPlayerBuildResult result);
			bool success = string.IsNullOrEmpty(result.Error);

			if (!success)
			{
				Debug.LogError("Addressables build error encountered: " + result.Error);
				throw new Exception("Addressables build error encountered: " + result.Error);
			}

			return success;
		}
		public static void BuildBaseAddressables()
		{
			BuildAddressables(true, "");
		}

		public static void BuildAddressables(bool isBase, string contentPath)
		{
			SetPreloadLabel();
			if (isBase)
			{
				ClearBuildAddressables();

				IDataBuilder builderScript
					= AssetDatabase.LoadAssetAtPath<ScriptableObject>(buildScriptPath) as IDataBuilder;

				SetProfile("Int");
				if (builderScript == null)
				{
					Debug.LogError(builderScript + " couldn't be found or isn't a build script.");
				}

				SetBuilder(builderScript);

				BuildAddressableContent();
				// var contentSource = Path.GetDirectoryName(Application.dataPath) + "/" + Addressables.LibraryPath +
				//                     PlatformMappingService.GetPlatformPathSubFolder() +
				//                     "/addressables_content_state.bin";
				// if (!string.IsNullOrEmpty(contentPath))
				// {
				// 	File.Copy(contentSource, contentPath, true);
				// }
			}
			else
			{
				SetWwisePlatform();
				if (EditorUserBuildSettings.activeBuildTarget == BuildTarget.Android)
				{
					MoveAssetToRemoteGroup("WwiseUpdateAndroid");
				}
				else if (EditorUserBuildSettings.activeBuildTarget == BuildTarget.iOS)
				{
					MoveAssetToRemoteGroup("WwiseUpdateiOS");
				}

				var contentSource = Path.GetDirectoryName(Application.dataPath) + "/" +
				                    $"{AddressableAssetSettingsDefaultObject.kDefaultConfigFolder}/{PlatformMappingService.GetPlatformPathSubFolder()}" +
				                    "/addressables_content_state.bin";
				if (!File.Exists(contentSource))
				{
					Debug.LogWarning($"[UnityBuildLog:] {contentSource} not exist");
					contentSource = Path.GetDirectoryName(Application.dataPath) + "/" + Addressables.LibraryPath +
					                PlatformMappingService.GetPlatformPathSubFolder() +
					                "/addressables_content_state.bin";
				}
				CheckForUpdateContent(contentSource);

				var bundleDupeDependenciesRule = new CheckBundleDupeDependencies();
				bundleDupeDependenciesRule.FixIssues(Settings);
				
				//  if (!string.IsNullOrEmpty(contentPath))
				ContentUpdateScript.BuildContentUpdate(Settings, contentSource);
			}
		}

		private static void SetPreloadLabel()
		{
			foreach (var assetGroup in Settings.groups)
			{
				var schema  = assetGroup.GetSchema<BundledAssetGroupSchema>();
				if (schema != null)
				{
					Debug.Log($"schema.LoadPath.Id {schema.LoadPath.Id}  ");
					//schema.LoadPath == profileName
				}
			}
		}
		
		public static void MoveAssetToRemoteGroup(string groupName)
		{
			AddressableAssetGroup contentGroup;
			if (TryGetGroup(Settings, "RemoteDynamicSplit", out contentGroup))
			{
				AddressableAssetGroup outGroup;
				if (TryGetGroup(Settings, groupName, out outGroup))
				{
					var list = outGroup.entries.ToList();
					foreach (var entry in list)
					{
						Settings.MoveEntry(entry, contentGroup, false, true);
						entry.labels.Add("preload");
					}
				}
			}
		}

		public static void CheckForUpdateContent(string contentSource)
		{
			AddressablesContentState cacheData = ContentUpdateScript.LoadContentState(contentSource);

			//与上次打包做资源对比

			var entries = ContentUpdateScript.GatherModifiedEntriesWithDependencies(Settings, contentSource);
			if (entries.Count == 0) return;
			foreach (var entry in entries)
			{
				StringBuilder sbuider = new StringBuilder();
				sbuider.AppendLine("Need Update Assets:");
				sbuider.AppendLine(entry.Key.address);
				Debug.Log(sbuider.ToString());
				entry.Key.labels.Add("preload");
				//将被修改过的资源单独分组
				CreateContentUpdateGroup(Settings, entry.Key, "Content Update");
			}
		}

		public static void CreateContentUpdateGroup(AddressableAssetSettings settings,
			AddressableAssetEntry entry, string groupName)
		{
			AddressableAssetGroup contentGroup;
			if (!TryGetGroup(settings, groupName, out contentGroup))
			{
				contentGroup = settings.CreateGroup(groupName, false, false, true, null);
				var schema = contentGroup.AddSchema<BundledAssetGroupSchema>();
				schema.BuildPath.SetVariableByName(settings, AddressableAssetSettings.kRemoteBuildPath);
				schema.LoadPath.SetVariableByName(settings, AddressableAssetSettings.kRemoteLoadPath);
				schema.BundleNaming = BundledAssetGroupSchema.BundleNamingStyle.OnlyHash;
				schema.BundleMode = BundledAssetGroupSchema.BundlePackingMode.PackSeparately;
				contentGroup.AddSchema<ContentUpdateGroupSchema>().StaticContent = false;
			}

			settings.MoveEntry(entry, contentGroup, false, true);
		}

		static bool TryGetGroup(AddressableAssetSettings settings, string groupName, out AddressableAssetGroup group)
		{
			if (string.IsNullOrWhiteSpace(groupName))
			{
				group = settings.DefaultGroup;
				return true;
			}

			return ((group = settings.groups.Find(g => string.Equals(g.Name, groupName.Trim()))) == null)
				? false
				: true;
		}

		public static bool BuildAddressablesDebug()
		{
			IDataBuilder builderScript
				= AssetDatabase.LoadAssetAtPath<ScriptableObject>(buildScriptPath) as IDataBuilder;

			ClearBuildAddressables();

			SetProfile("Default");

			Settings.BuildRemoteCatalog = false;

			if (builderScript == null)
			{
				Debug.LogError(builderScript + " couldn't be found or isn't a build script.");
				return false;
			}

			SetBuilder(builderScript);

			return BuildAddressableContent();
		}

		public static void ClearBuildAddressables()
		{
			IDataBuilder builderScript
				= AssetDatabase.LoadAssetAtPath<ScriptableObject>(buildScriptPath) as IDataBuilder;
			AddressableAssetSettings.CleanPlayerContent(builderScript);
		}

		public static void SetWwisePlatform()
		{
			var wwisePlatform = GetCurrentPlatfrom();
			foreach (var group in Settings.groups)
			{
				var include = false;

				if (group.Name.Contains("WwiseData"))
				{
					if (group.Name.Contains(wwisePlatform))
					{
						include = true;
					}

					var bundleSchema = group.GetSchema<BundledAssetGroupSchema>();
					if (bundleSchema != null)
						bundleSchema.IncludeInBuild = include;
				}
			}
		}

		private static string GetCurrentPlatfrom()
		{
			var target = EditorUserBuildSettings.activeBuildTarget;
			string platform = "None";
			switch (target)
			{
				case BuildTarget.StandaloneWindows:
				case BuildTarget.StandaloneWindows64:
					platform = "Windows";
					break;
				case BuildTarget.iOS:
					platform = "iOS";
					break;
				case BuildTarget.Android:
					platform = "Android";
					break;
				case BuildTarget.NoTarget:
					break;
				default:
					throw new ArgumentOutOfRangeException();
			}

			return platform;
		}
	}
}