using UnityEngine;
using UnityEditor;
using System.Reflection;
using Seamless;

class SeamlessAssetPostprocessor : AssetPostprocessor
{
    public override int GetPostprocessOrder()
    {
        return 0;
    }

    static void OnPostprocessAllAssets(string[] importedAssets, string[] deletedAssets, string[] movedAssets, string[] movedFromAssetPaths)
    {
        foreach (string str in importedAssets)
        {
            if (SeamlessUtils.IsSeamlessGraph(str))
            {
                SeamlessObject obj = AssetDatabase.LoadAssetAtPath<SeamlessObject>(str);
                Texture2D icon = Resources.Load<Texture2D>("SeamlessLogo");
#if UNITY_2021_1_OR_NEWER
                EditorGUIUtility.SetIconForObject(obj, icon);
#else
                System.Type editorGUIUtilityType = typeof(EditorGUIUtility);
                BindingFlags bindingFlags = BindingFlags.InvokeMethod | BindingFlags.Static | BindingFlags.NonPublic;
                object[] args = new object[] { obj, icon };
                editorGUIUtilityType.InvokeMember("SetIconForObject", bindingFlags, null, null, args);
#endif
            }
        }
    }
    
}
