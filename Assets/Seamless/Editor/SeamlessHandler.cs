using UnityEngine;
using UnityEditor;
using UnityEditor.Callbacks;
using System.Reflection;
using UnityEditor.ProjectWindowCallback;
using Seamless;

public class SeamlessHandler
{

    class SeamlessGraphEndNameEditAction : EndNameEditAction
    {
        public SeamlessObject CreateSeamlessGraphAsset()
        {
            return CreateInstance<SeamlessObject>();
        }

        public override void Action(int instanceId, string pathName, string resourceFile)
        {
            var seamlessAsset = CreateSeamlessGraphAsset();
            seamlessAsset.data = "SeamlessGraph\nLinks:\n";
            seamlessAsset.textureSize = new Vector2Int(1024, 1024);
            AssetDatabase.CreateAsset(seamlessAsset, pathName);
            Texture2D icon = Resources.Load<Texture2D>("SeamlessLogo");
#if UNITY_2021_1_OR_NEWER
            EditorGUIUtility.SetIconForObject(seamlessAsset, icon);
#else
            System.Type editorGUIUtilityType = typeof(EditorGUIUtility);
            BindingFlags bindingFlags = BindingFlags.InvokeMethod | BindingFlags.Static | BindingFlags.NonPublic;
            object[] args = new object[] { seamlessAsset, icon };
            editorGUIUtilityType.InvokeMember("SetIconForObject", bindingFlags, null, null, args);
#endif
            AssetDatabase.SaveAssets();
            Selection.activeObject = seamlessAsset;

        }
    }
    [MenuItem("Assets/Create/Seamless Graph", false, 100)]
    public static void CreateSeamlessGraph()
    {
        var graphItem = ScriptableObject.CreateInstance<SeamlessGraphEndNameEditAction>();
        Texture2D icon = Resources.Load<Texture2D>("SeamlessLogo");
        ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0, graphItem,
            "New Seamless Graph.asset", icon, null);
    }

    [OnOpenAssetAttribute(0)]
    public static bool OnSeamlessGraphOpened(int instanceID, int line)
    {
        string name = EditorUtility.InstanceIDToObject(instanceID).name;
        string path = AssetDatabase.GetAssetPath(EditorUtility.InstanceIDToObject(instanceID));
        if (SeamlessUtils.IsSeamlessGraph(path))
        {
            SeamlessEditor[] seamlessWindows = Resources.FindObjectsOfTypeAll<SeamlessEditor>();
            foreach (SeamlessEditor seamlessWindow in seamlessWindows)
            {
                if (seamlessWindow.path == path)
                {
                    seamlessWindow.Show();
                    seamlessWindow.Focus();
                    return true;
                }
            }
#if UNITY_2019_2_OR_NEWER
            SeamlessEditor graphWindow = EditorWindow.CreateWindow<SeamlessEditor>(name, typeof(SceneView));
#else
            SeamlessEditor graphWindow = EditorWindow.CreateInstance<SeamlessEditor>();
#endif
            Texture2D icon = Resources.Load<Texture2D>("SeamlessLogo");
            graphWindow.titleContent = new GUIContent(name, icon);
            graphWindow.name = name;
            graphWindow.Show();
            graphWindow.Focus();
            graphWindow.path = path;
            graphWindow.Load();

            return true;

        }
        return false;
    }
}