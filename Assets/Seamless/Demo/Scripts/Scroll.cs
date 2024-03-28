using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Scroll : MonoBehaviour
{
    public float primarySpeed;
    public float secondarySpeed;

    private Material mat;

    // Start is called before the first frame update
    void Start()
    {
        mat = GetComponent<MeshRenderer>().material;
        StartCoroutine(ScrollRoutine());
    }

    IEnumerator ScrollRoutine()
    {
        while (Application.isPlaying)
        {
            mat.SetTextureOffset("_MainTex", Vector2.one * Time.time * primarySpeed);
            mat.SetTextureOffset("_DetailAlbedoMap", -Vector2.one * Time.time * secondarySpeed);
            yield return new WaitForSeconds(0.05f);
        }
    }
}
