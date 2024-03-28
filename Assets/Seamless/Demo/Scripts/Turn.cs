using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Seamless
{
    public class Turn : MonoBehaviour
    {
        public float speed = 0.1f;
        public Space relativeTo = Space.Self;
    
        void Update()
        {
            transform.Rotate(Vector3.up, speed, relativeTo);
        }

    }
}
