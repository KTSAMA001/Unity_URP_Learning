using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEditor.Rendering;
using ActionTest = System.Action<UnityEngine.AnimationCurve, UnityEngine.AnimationCurve, UnityEngine.AnimationCurve, UnityEngine.Rendering.VolumeStack>;

namespace UnityEngine.Rendering.Tests
{
    public class VolumeComponentAnimCurveTests
    {
        #region Interpolation
        static bool TestAnimationCurveInterp(AnimationCurve lhsCurve, AnimationCurve rhsCurve, float t, float startTime, float endTime, int numSteps, float eps, bool debugPrint)
        {
            AnimationCurve midCurve = new AnimationCurve(lhsCurve.keys);
            KeyframeUtility.InterpAnimationCurve(ref midCurve, rhsCurve, t);

            for (int i = 0; i <= numSteps; i++)
            {
                float timeT = ((float)i) / ((float)numSteps);
                float currTime = Mathf.Lerp(startTime, endTime, timeT);

                float lhsVal = lhsCurve.Evaluate(currTime);
                float rhsVal = rhsCurve.Evaluate(currTime);

                float expectedVal = Mathf.Lerp(lhsVal, rhsVal, t);

                float actualVal = midCurve.Evaluate(currTime);

                float offset = actualVal - expectedVal;
                if (debugPrint)
                {
                    Debug.Log(i.ToString() + ": " + offset.ToString());
                }

                if (Mathf.Abs(offset) >= eps)
                {
                    return false;
                }
            }

            return true;
        }

        static AnimationCurve CreateTestCurve(int index)
        {
            AnimationCurve testCurve = new AnimationCurve();
            if (index == 0)
            {
                testCurve.AddKey(new Keyframe(0.0f, 3.0f, 2.0f, 2.0f));
                testCurve.AddKey(new Keyframe(4.0f, 2.0f, -1.0f, -1.0f));
                testCurve.AddKey(new Keyframe(7.0f, 2.6f, -1.0f, -1.0f));
            }
            else if (index == 1)
            {
                testCurve.AddKey(new Keyframe(-1.0f, 3.0f, 2.0f, 2.0f));
                testCurve.AddKey(new Keyframe(4.0f, 2.0f, 3.0f, 3.0f));
                testCurve.AddKey(new Keyframe(5.0f, 2.6f, 0.0f, 0.0f));
                testCurve.AddKey(new Keyframe(9.0f, 2.6f, -5.0f, -5.0f));
            }
            else if (index == 2)
            {
                // Needed for the same positions as curve 0 but different values and tangents
                testCurve.AddKey(new Keyframe(0.0f, 1.0f, -1.0f, 3.0f));
                testCurve.AddKey(new Keyframe(4.0f, 6.0f, -9.0f, -2.0f));
                testCurve.AddKey(new Keyframe(7.0f, 5.2f, -3.0f, -4.0f));
            }
            else
            {
                // Need for the test case where two curves have no overlap
                testCurve.AddKey(new Keyframe(11.0f, 1.0f, -1.0f, 3.0f));
                testCurve.AddKey(new Keyframe(14.0f, 6.0f, -9.0f, -2.0f));
                testCurve.AddKey(new Keyframe(17.0f, 5.2f, -3.0f, -4.0f));
            }

            return testCurve;
        }

        static TestCaseData[] s_AnimationCurveTestDatas =
        {
            new TestCaseData(CreateTestCurve(0), CreateTestCurve(1), 0.25f)
                .SetName("CurveTest 1"),
            new TestCaseData(CreateTestCurve(1), CreateTestCurve(2), 0.25f)
                .SetName("CurveTest 2"),
            new TestCaseData(CreateTestCurve(0), CreateTestCurve(2), 0.25f)
                .SetName("CurveTest Same Positions"),
            new TestCaseData(CreateTestCurve(0), CreateTestCurve(3), 0.25f)
                .SetName("CurveTest No Overlap"),
        };

        [Test, TestCaseSource(nameof(s_AnimationCurveTestDatas))]
        public void RenderInterpolateAnimationCurve(AnimationCurve lhsCurve, AnimationCurve rhsCurve, float t)
        {
            Assert.IsTrue(TestAnimationCurveInterp(lhsCurve, rhsCurve, t, -5.0f, 20.0f, 100, 1e-5f, false));
        }

        #endregion

        class TestAnimationCurveVolumeComponent : VolumeComponent
        {
            public AnimationCurveParameter testParameter = new (AnimationCurve.Linear(0.5f, 10.0f, 1.0f, 15.0f), true);
        }

        static TestCaseData[] s_AnimationCurveKeysNotSharedTestDatas =
        {
            new TestCaseData(null)
                .SetName("Reloading the stack makes the parameters be the same as TestAnimationCurveVolumeComponent")
                .Returns((2,2,2)),
            new TestCaseData((ActionTest)((parameterInterpolated, _, _, stack) =>
                {
                    // The replace data will call: AnimationCurveParameter.SetValue make sure the C++ reference is not shared
                    VolumeManager.instance.ReplaceData(stack);

                    // Check that the value that stores the interpolated data, if is modified both default values are modified
                    parameterInterpolated.RemoveKey(1);
                }))
                .SetName("When Replacing the current interpolated values by the ones in the default, applying modifications to the interpolated parameter do not modify the default parameters")
                .Returns((1,2,2)),
            new TestCaseData((ActionTest)((_, _, defaultComponentParameterUsedToInitializeStack, _) =>
                {
                    defaultComponentParameterUsedToInitializeStack.AddKey(0.0f, 1.0f);
                }))
                .SetName("When modifying the default component used to initialize the stack, the parameters on the stack remain the same, as they should be cloned")
                .Returns((2,2,3)),
            new TestCaseData((ActionTest)((_, defaultParameterForFastAccess, _, _) =>
                {
                    defaultParameterForFastAccess.AddKey(0.0f, 1.0f);
                    defaultParameterForFastAccess.AddKey(0.6f, 2.0f);
                }))
                .SetName("Check that the default parameter on the stack do not modifies the interpolated value or either the default used to initialize the stack")
                .Returns((2,4,2)),
            new TestCaseData((ActionTest)((_, defaultParameterForFastAccess, _, stack) =>
                {
                    defaultParameterForFastAccess.AddKey(0.0f, 1.0f);
                    defaultParameterForFastAccess.AddKey(0.6f, 2.0f);

                    VolumeManager.instance.ReplaceData(stack);
                }))
                .SetName("Check that ReplaceData should have modified the interpolated value with the default value stored in the stack and not the one used from the default")
                .Returns((4,4,2)),
            new TestCaseData((ActionTest)((_, _, _, stack) =>
                {
                    stack.Clear();
                }))
                .SetName("Check that clearing the stack should modify and release memory from the parameters and volume components that have locally in the stack, but not the default volume used to initialize the stack")
                .Returns((-1,-1,2)),
        };

        private TestAnimationCurveVolumeComponent m_DefaultComponent;

        [SetUp]
        public void Setup()
        {
            m_DefaultComponent = ScriptableObject.CreateInstance<TestAnimationCurveVolumeComponent>();
        }

        [TearDown]
        public void TearDown()
        {
            ScriptableObject.DestroyImmediate(m_DefaultComponent);
        }

        [Test, Description("UUM-20458, UUM-20456"), TestCaseSource(nameof(s_AnimationCurveKeysNotSharedTestDatas))]
        public (int, int, int) AnimationCurveParameterKeysAreNotShared(ActionTest actionToPerform)
        {
            using var stack = new VolumeStack();

            // Initialize the stack
            stack.Reload(new List<VolumeComponent>() { m_DefaultComponent });

            actionToPerform?.Invoke(
                stack.defaultParameters[0].parameter.GetValue<AnimationCurve>(),    // parameterInterpolated
                stack.defaultParameters[0].defaultValue.GetValue<AnimationCurve>(), // defaultParameterForFastAccess
                m_DefaultComponent.testParameter.GetValue<AnimationCurve>(),        // defaultComponentParameterUsedToInitializeStack
                stack);
            
            return (
                stack.defaultParameters == null ? -1 : stack.defaultParameters[0].parameter.GetValue<AnimationCurve>().length,      // parameterInterpolated
                stack.defaultParameters == null ? -1 : stack.defaultParameters[0].defaultValue.GetValue<AnimationCurve>().length,   // defaultParameterForFastAccess
                m_DefaultComponent.testParameter.GetValue<AnimationCurve>().length                                                  // defaultComponentParameterUsedToInitializeStack
                );
        }
    }

    public class VolumeComponentEditorTests
    {
        [HideInInspector]
        [VolumeComponentMenuForRenderPipeline("Tests/No Additional", typeof(RenderPipeline))]
        class VolumeComponentNoAdditionalAttributes : VolumeComponent
        {
            public MinFloatParameter parameter = new MinFloatParameter(0f, 0f);
        }

        [HideInInspector]
        [VolumeComponentMenuForRenderPipeline("Tests/All Additional", typeof(RenderPipeline))]
        class VolumeComponentAllAdditionalAttributes : VolumeComponent
        {
            [AdditionalProperty]
            public MinFloatParameter parameter1 = new MinFloatParameter(0f, 0f);

            [AdditionalProperty]
            public FloatParameter parameter2 = new MinFloatParameter(0f, 0f);
        }

        [HideInInspector]
        [VolumeComponentMenuForRenderPipeline("Tests/Mixed Additional", typeof(RenderPipeline))]
        class VolumeComponentMixedAdditionalAttributes : VolumeComponent
        {
            public MinFloatParameter parameter1 = new MinFloatParameter(0f, 0f);

            [AdditionalProperty]
            public FloatParameter parameter2 = new MinFloatParameter(0f, 0f);

            public MinFloatParameter parameter3 = new MinFloatParameter(0f, 0f);

            [AdditionalProperty]
            public FloatParameter parameter4 = new MinFloatParameter(0f, 0f);
        }

        private void CreateEditorAndComponent(Type volumeComponentType, ref VolumeComponent component, ref VolumeComponentEditor editor)
        {
            component = (VolumeComponent)ScriptableObject.CreateInstance(volumeComponentType);
            editor = (VolumeComponentEditor)Editor.CreateEditor(component);
            editor.Invoke("Init");
        }

        [Test]
        public void TestOverridesChanges()
        {
            VolumeComponent component = null;
            VolumeComponentEditor editor = null;
            CreateEditorAndComponent(typeof(VolumeComponentMixedAdditionalAttributes), ref component, ref editor);

            component.SetAllOverridesTo(false);
            bool allOverridesState = (bool)editor.Invoke("AreAllOverridesTo", false);
            Assert.True(allOverridesState);

            component.SetAllOverridesTo(true);

            // Was the change correct?
            allOverridesState = (bool)editor.Invoke("AreAllOverridesTo", true);
            Assert.True(allOverridesState);

            // Enable the advance mode on the editor
            editor.showAdditionalProperties = true;

            // Everything is false
            component.SetAllOverridesTo(false);

            // Disable the advance mode on the editor
            editor.showAdditionalProperties = false;

            // Now just set to true the overrides of non additional properties
            editor.Invoke("SetOverridesTo", true);

            // Check that the non additional properties must be false
            allOverridesState = (bool)editor.Invoke("AreAllOverridesTo", true);
            Assert.False(allOverridesState);

            ScriptableObject.DestroyImmediate(component);
        }

        static TestCaseData[] s_AdditionalAttributesTestCaseDatas =
        {
            new TestCaseData(typeof(VolumeComponentNoAdditionalAttributes))
                .Returns(Array.Empty<string>())
                .SetName("VolumeComponentNoAdditionalAttributes"),
            new TestCaseData(typeof(VolumeComponentAllAdditionalAttributes))
                .Returns(new string[2] {"parameter1", "parameter2"})
                .SetName("VolumeComponentAllAdditionalAttributes"),
            new TestCaseData(typeof(VolumeComponentMixedAdditionalAttributes))
                .Returns(new string[2] {"parameter2", "parameter4"})
                .SetName("VolumeComponentMixedAdditionalAttributes"),
        };

        [Test, TestCaseSource(nameof(s_AdditionalAttributesTestCaseDatas))]
        public string[] AdditionalProperties(Type volumeComponentType)
        {
            VolumeComponent component = null;
            VolumeComponentEditor editor = null;
            CreateEditorAndComponent(volumeComponentType, ref component, ref editor);

            var fields = component
                .GetFields()
                .Where(f => f.GetCustomAttribute<AdditionalPropertyAttribute>() != null)
                .Select(f => f.Name)
                .ToArray();

            var notAdditionalParameters = editor.GetField("m_VolumeNotAdditionalParameters") as List<VolumeParameter>;
            Assert.True(fields.Count() + notAdditionalParameters.Count == component.parameters.Count);

            ScriptableObject.DestroyImmediate(component);

            return fields;
        }

        #region Decorators Handling Test

        [HideInInspector]
        class VolumeComponentDecorators : VolumeComponent
        {
            [Tooltip("Increase to make the noise texture appear bigger and less")]
            public FloatParameter _NoiseTileSize = new FloatParameter(25.0f);

            [InspectorName("Color")]
            public ColorParameter _FogColor = new ColorParameter(Color.grey);

            [InspectorName("Size and occurrence"), Tooltip("Increase to make patches SMALLER, and frequent")]
            public ClampedFloatParameter _HighNoiseSpaceFreq = new ClampedFloatParameter(0.1f, 0.1f, 1f);
        }

        readonly (string displayName, string tooltip)[] k_ExpectedResults =
        {
            (string.Empty, "Increase to make the noise texture appear bigger and less"),
            ("Color", string.Empty),
            ("Size and occurrence", "Increase to make patches SMALLER, and frequent")
        };

        [Test]
        public void TestHandleParameterDecorators()
        {
            VolumeComponent component = null;
            VolumeComponentEditor editor = null;
            CreateEditorAndComponent(typeof(VolumeComponentDecorators), ref component, ref editor);

            var parameters =
                editor.GetField("m_Parameters") as List<(GUIContent displayName, int displayOrder,
                    SerializedDataParameter param)>;

            Assert.True(parameters != null && parameters.Count() == k_ExpectedResults.Count());

            for (int i = 0; i < k_ExpectedResults.Count(); ++i)
            {
                var property = parameters[i].param;
                var title = new GUIContent(parameters[i].displayName);

                editor.Invoke("HandleDecorators", property, title);

                Assert.True(k_ExpectedResults[i].displayName == title.text);
                Assert.True(k_ExpectedResults[i].tooltip == title.tooltip);
            }

            ScriptableObject.DestroyImmediate(component);
        }

        #endregion

        [Test]
        public void TestSupportedOnAvoidedIfHideInInspector()
        {
            Type[] types = new[]
            {
                typeof(VolumeComponentNoAdditionalAttributes),
                typeof(VolumeComponentAllAdditionalAttributes),
                typeof(VolumeComponentMixedAdditionalAttributes)
            };

            Type volumeComponentProvider = ReflectionUtils.FindTypeByName("UnityEngine.Rendering.VolumeManager");
            var volumeComponents = volumeComponentProvider.InvokeStatic("FilterVolumeComponentTypes",
                types, typeof(RenderPipeline)) as List<(string, Type)>;


            Assert.NotNull(volumeComponents);
            Assert.False(volumeComponents.Any());
        }
    }
}
