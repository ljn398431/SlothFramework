using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using UnityEditor;
using Debug = UnityEngine.Debug;

namespace LifeGlory.Editor
{
    /*
     * @brief	（简要描述）
     * @details	对该文档的详细说明和解释，可以换行
     */
    public class FileFormatUtils
    {
        private static readonly string _luaFileFolder = "/../Lua";
        private static readonly string _fileSuffix = ".lua";

        private static string LuaFileFolder
        {
            get { return Application.dataPath + _luaFileFolder; }
        }

        [MenuItem("Tools/Asset/Convert LuaFile to UTF-8")]
        public static void ConvertLuaFileFormat()
        {
            if (!Directory.Exists(LuaFileFolder))
            {
                Debug.Log("folder is not exists "+LuaFileFolder);
                return;
            }
            
            string[] files = Directory.GetFiles(LuaFileFolder, "*.lua", SearchOption.AllDirectories);
            foreach (string file in files)
            {
                if (!file.EndsWith(_fileSuffix)) continue;
                string strTempPath = file.Replace(@"\", "/");
                Debug.Log("文件路径：" + strTempPath);
                ConvertFileEncoding(strTempPath, null, new UTF8Encoding(false));
            }

            Debug.Log("格式转换完成！");
        }
        [MenuItem("Tools/Asset/Convert LuaFile to UTF-8 And Complie")]
        public static void ConvertLuaFileFormatAndEncode()
        {
            if (!Directory.Exists(LuaFileFolder))
            {
                Debug.Log("folder is not exists "+LuaFileFolder);
                return;
            }
            
            string[] files = Directory.GetFiles(LuaFileFolder, "*.lua", SearchOption.AllDirectories);
            foreach (string file in files)
            {
                if (!file.EndsWith(_fileSuffix)) continue;
                string strTempPath = file.Replace(@"\", "/");
                Debug.Log("文件路径：" + strTempPath);
                ConvertFileEncoding(strTempPath, null, new UTF8Encoding(false));
            }
           
            Debug.Log("格式转换完成！");
        }

        private static void CompileByLuac(string path)
        {
            var process = new Process();
            process.StartInfo = new ProcessStartInfo {
#if UNITY_EDITOR_WIN
                FileName = "luac.exe",
#else
				FileName = "luac",
#endif
                Arguments = $"-o {path} {path}",
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                UseShellExecute = false
            };
            process.Start();
        }

        private static void ConvertFileEncoding(string sourceFile, string destFile, Encoding targetEncoding)
        {
            destFile = string.IsNullOrEmpty(destFile) ? sourceFile : destFile;
            File.WriteAllText(destFile, File.ReadAllText(sourceFile, Encoding.UTF8), targetEncoding);
        }
    }
}