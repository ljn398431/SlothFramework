using System;
using System.IO;
using CSObjectWrapEditor;
using Unity.SharpZipLib.Utils;
using UnityEditor;
using UnityEditor.AddressableAssets.Settings;
using UnityEngine;

namespace LifeGlory.Editor
{
	public static class PlayerBuild
	{
		[MenuItem("Tools/Asset/Lua Pack Zip")]
		private static void PackLuaZip()
		{
			const string luaPackPath = "./Lua.zip";
			if (File.Exists(luaPackPath))
			{
				File.Delete(luaPackPath);
			}

			ZipUtility.CompressFolderToZip(luaPackPath, Application.productName, $"{Application.dataPath}/../Lua");
		}

		private static AddressableAssetSettings m_settings;

		public static void PackScriptAndBuildAddressableSteps(bool buildAddressable)
		{
			//转换lua为Utf-8格式
			FileFormatUtils.ConvertLuaFileFormat();
			PackLuaZip();
			File.Copy("./Lua.zip", Application.streamingAssetsPath + "/Lua", true);
			if (buildAddressable)
			{
				m_settings =
					AssetDatabase.LoadAssetAtPath<AddressableAssetSettings>(
						"Assets/AddressableAssetsData/AddressableAssetSettings.asset");
				if (m_settings == null)
				{
					throw new Exception("Addressable Asset Settings couldn't be found.");
				}

				AddressableAssetSettings.BuildPlayerContent(out var result);
				var success = string.IsNullOrEmpty(result.Error);
				if (!success)
				{
					throw new Exception(result.Error);
				}
			}
		}
		[MenuItem("Tools/Asset/Lua Pack Zip And Copy")]
		public static void PackLuaZipAndCopy()
		{
			PackLuaZip();
			File.Copy("./Lua.zip", Application.streamingAssetsPath + "/BuiltInData", true);
		}

		private static void CheckEnvParamMatch(ref BuildOptions options, string argToMatch, BuildOptions enumValue)
		{
			if (Array.IndexOf(Environment.GetCommandLineArgs(), argToMatch) != -1)
			{
				options |= enumValue;
				Debug.Log($"Add Build Option {enumValue}");
			}
		}

		private static BuildPlayerOptions AnalyseCommandLineArgs()
		{
			var options = BuildOptions.None;
			CheckEnvParamMatch(ref options, "dev", BuildOptions.Development);
			CheckEnvParamMatch(ref options, "debug", BuildOptions.AllowDebugging);
			CheckEnvParamMatch(ref options, "scriptOnly", BuildOptions.BuildScriptsOnly);
			CheckEnvParamMatch(ref options, "compress", BuildOptions.CompressWithLz4);
			CheckEnvParamMatch(ref options, "deep", BuildOptions.EnableDeepProfilingSupport);
			CheckEnvParamMatch(ref options, "strict", BuildOptions.StrictMode);
			var playerOptions = new BuildPlayerOptions
			{
				options = options
			};
			var playerSettings = BuildPlayerWindow.DefaultBuildMethods.GetBuildPlayerOptions(playerOptions);
			return playerSettings;
		}

		private static void BuildPlayer(string outputPath, BuildTarget buildTarget, bool copyAddressable)
		{
			Generator.GenAll();
			if (EditorUserBuildSettings.activeBuildTarget != buildTarget)
			{
				throw new Exception("Current active platform mismatch build platform.");
			}

			var playerSettings = AnalyseCommandLineArgs();
			playerSettings.target = buildTarget;
			BuildPipeline.BuildPlayer(playerSettings);
			if (copyAddressable)
			{
				var addressableDest = $"{outputPath}/AddressableBuildOutput";
				if (Directory.Exists(addressableDest))
				{
					Directory.Delete(addressableDest, true);
				}

				FileUtil.CopyFileOrDirectory($"AddressableBuildOutput/", addressableDest);
			}

			Generator.ClearAll();
		}

		private static void BuildWindowsAndAddressable()
		{
			PackScriptAndBuildAddressableSteps(true);
			BuildPlayer("WinBuild", BuildTarget.StandaloneWindows64, true);
		}

		private static void BuildWindowsPlayer()
		{
			PackScriptAndBuildAddressableSteps(false);
			BuildPlayer("WinBuild", BuildTarget.StandaloneWindows64, false);
		}

		private static void BuildAndroidAndAddressable()
		{
			PackScriptAndBuildAddressableSteps(true);
			BuildPlayer("AndroidBuild", BuildTarget.Android, true);
		}

		private static void BuildAndroidPlayer()
		{
			PackScriptAndBuildAddressableSteps(false);
			BuildPlayer("AndroidBuild", BuildTarget.Android, false);
		}

		private static void BuildLuaScriptOnly()
		{
			const string luaPackPath = "./Lua.zip";
			PackLuaZip();
			File.Copy(luaPackPath, "WinBuild/DBLike_Data/StreamingAssets/Lua.zip", true);
		}
	}
}