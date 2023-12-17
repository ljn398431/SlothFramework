using UnityEngine;
using UnityEditor;
using UnityEditor.AddressableAssets;
using System.Collections.Generic;
using System.Linq;

#if ODIN_INSPECTOR
using Sirenix.OdinInspector;
#endif

[CreateAssetMenu(fileName = "AddressableImportSettings", menuName = "Addressables/Import Settings", order = 50)]
public class AddressableImportSettings : ScriptableObject
{
    public const string kConfigObjectName = "addressableimportsettings";
    public const string kDefaultPath = "Assets/AddressableAssetsData/AddressableImportSettings.asset";

    [Tooltip("Creates a group if the specified group doesn't exist.")]
    public bool allowGroupCreation = false;

    [Tooltip("Rules for managing imported assets.")]
#if ODIN_INSPECTOR
    [ListDrawerSettings(HideAddButton = false,Expanded = false,DraggableItems = true,HideRemoveButton = false)]
    [Searchable(FilterOptions = SearchFilterOptions.ISearchFilterableInterface)]
#endif
    [LabelText("Addressable分组规则")]
    public List<AddressableImportRule> rules = new List<AddressableImportRule>();

    [LabelText("自动检查路径")]
    public  List<string> autoCheckFolderList = new List<string>()
    {
        "Assets/Res",
        "Assets/Shader",
        "Assets/Scenes",
    };
    
    private static void AutoGroupAssets()
    {
        AddressableImporter.FolderImporter.ReimportFolders(AddressableImportSettings.Instance.autoCheckFolderList);
    }
    [Button("保存并自动分组",ButtonSizes.Large)]
    public void Save()
    {
        AssetDatabase.SaveAssets();
        AutoGroupAssets();
    }
    

    [Button("规则说明",ButtonSizes.Large)]
    public void Documentation()
    {
        Application.OpenURL("https://github.com/favoyang/unity-addressable-importer/blob/master/Documentation~/AddressableImporter.md");
    }

    [Button("清除空的Group",ButtonSizes.Large)]
    public void CleanEmptyGroup()
    {
        var settings = AddressableAssetSettingsDefaultObject.Settings;
        if (settings == null)
        {
            return;
        }
        var dirty = false;
        var emptyGroups = settings.groups.Where(x => x.entries.Count == 0 && !x.IsDefaultGroup()).ToArray();
        for (var i = 0; i < emptyGroups.Length; i++)
        {
            dirty = true;
            settings.RemoveGroup(emptyGroups[i]);
        }
        if (dirty)
        {
            AssetDatabase.SaveAssets();
        }
    }

    public static AddressableImportSettings Instance
    {
        get
        {
            AddressableImportSettings so;
            // Try to locate settings from EditorBuildSettings
            if (EditorBuildSettings.TryGetConfigObject(kConfigObjectName, out so))
                return so;
            // Try to locate settings from default path
            so = AssetDatabase.LoadAssetAtPath<AddressableImportSettings>(kDefaultPath);
            if (so != null) {
                EditorBuildSettings.AddConfigObject(kConfigObjectName, so, true);
                return so;
            }
            // Try to locate settings from AssetDatabase
            var path = AssetDatabase.FindAssets($"t:{nameof(AddressableImportSettings)}");
            if (path.Length > 0) {
                var assetPath = AssetDatabase.GUIDToAssetPath(path[0]);
                so = AssetDatabase.LoadAssetAtPath<AddressableImportSettings>(assetPath);
                EditorBuildSettings.AddConfigObject(kConfigObjectName, so, true);
                return so;
            }
            return null;
        }
    }

}