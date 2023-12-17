using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using UnityEditor;
using Debug = UnityEngine.Debug;

namespace Extend.Editor
{
    /*
     * @brief	（简要描述）
     * @details	对该文档的详细说明和解释，可以换行
     */
    public class TableTools
    {
        [MenuItem("Tools/Asset/打tsv表")]
        public static void BuildTables()
        {
            Debug.Log("执行打表");
            ExcureExe();
            CopyTsvFile();
            AssetDatabase.Refresh();
        }

        private static readonly string ExeName = "ExcelExport.exe";

        private static readonly string ExePath = "../../Doc/ExportRelease/";

        private static void ExcureExe()
        {
            string path = Path.Combine(Application.dataPath, ExePath + ExeName);
            Debug.Log("path is " + path);

            ProcessStartInfo info = new ProcessStartInfo(path)
            {
                // 必须禁用操作系统外壳程序  
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                StandardErrorEncoding = System.Text.Encoding.UTF8,
                StandardOutputEncoding = System.Text.Encoding.UTF8,
                WorkingDirectory = Path.Combine(Application.dataPath, ExePath)
            };

            var process = Process.Start(info);
            if (process != null)
            {
                string output = process.StandardOutput.ReadToEnd();
                process.WaitForExit();
                process.Close();

                var builder = new StringBuilder();
                var errorExist = false;
                using( var reader = new StringReader(output) ) {
                    var line = reader.ReadLine();
                    while( !string.IsNullOrEmpty(line) ) {
                        if( line.StartsWith("Error") || errorExist ) {
                            builder.AppendLine(line);
                            errorExist = true;
                        }
                        line = reader.ReadLine();
                    }
                }

                if( builder.Length > 0 ) {
                    EditorUtility.DisplayDialog("Error", builder.ToString(), "OK");
                }
                
                Debug.Log(output);
            }
        }

        private static void CopyTsvFile()
        {
            var path = Application.dataPath + "../../../Doc/Export/";
            if (!Directory.Exists(path))
            {
                Debug.LogError($"path is not exist {path}");
                return;
            }

            var files = Directory.GetFiles(path, "*.tsv");
            foreach (var file in files)
            {
                try
                {
                    var fileName = Path.GetFileName(file);
                    if (File.Exists(file))
                    {
                        if(!fileName.Contains("_Server"))
                            File.Copy(file, Application.dataPath + "/Res/Xlsx/" + fileName, true);
                        //Debug.Log($"copy {fileName} to Res/Xlsx Folder");
                    }
                }
                catch (Exception e)
                {
                    Debug.Log(e);
                }
            }

            Debug.Log("拷贝tsv文件完成");
        }
    }
}