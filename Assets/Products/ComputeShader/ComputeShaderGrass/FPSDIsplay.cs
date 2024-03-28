using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
[ExecuteAlways]
public class FPSDIsplay : MonoBehaviour
{
    public Text text;
    // Start is called before the first frame update
    void Start()
    {
        text.text = "--";
    }

    private float timer = 0;

    private float frameTimerTemp=0;
    private float TimerTemp=0;
    // Update is called once per frame
    void Update()
    {
        
        if (Time.time-timer>2)
        {
            timer = Time.time;
            text.text = "FPS:"+(TimerTemp / frameTimerTemp).ToString("F2");
            frameTimerTemp = 0;
            TimerTemp = 0;
        }
        else
        {
            TimerTemp += 1;
            frameTimerTemp += Time.deltaTime;
        }
        
    }
}
