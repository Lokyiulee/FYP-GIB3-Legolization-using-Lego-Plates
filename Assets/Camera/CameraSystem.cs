using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraSystem : MonoBehaviour
{
    private void Update()
    {
        Vector3 inputDir = new Vector3(0,0,0);
        if (Input.GetKey(KeyCode.W)) {inputDir.z= -1f;}
        if (Input.GetKey(KeyCode.S)) {inputDir.z= +1f;}
        if (Input.GetKey(KeyCode.A)) {inputDir.x= +1f;}
        if (Input.GetKey(KeyCode.D)) {inputDir.x= -1f;}

        Vector3 moveDir = transform.forward * inputDir.z + transform.right * inputDir.x;

        float moveSpeed = 20f;
        transform.position += moveDir * moveSpeed * Time.deltaTime;

        Vector3 inputDir2 = new Vector3(0,0,0);
        if (Input.GetKey(KeyCode.Q)) {inputDir2.x += 1f;}
        if (Input.GetKey(KeyCode.E)) {inputDir2.x -= 1f;}
        


        float rotateSpeed = 20f;
        transform.eulerAngles += new Vector3(0,inputDir2.x * rotateSpeed * Time.deltaTime ,0);
    }
}
