using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraSystem : MonoBehaviour
{
    private void Update()
    {
        //camera movement
        Vector3 inputDir = new Vector3(0,0,0);
        //if (Input.GetKey(KeyCode.W)) {inputDir.z= -1f;}
        //if (Input.GetKey(KeyCode.S)) {inputDir.z= +1f;}
        if (Input.GetKey(KeyCode.A)) {inputDir.x= +1f;}
        if (Input.GetKey(KeyCode.D)) {inputDir.x= -1f;}

        Vector3 moveDir = transform.forward * inputDir.z + transform.right * inputDir.x;

        float moveSpeed = 20f;
        transform.position += moveDir * moveSpeed * Time.deltaTime;


        //object rotation
        if (GameObject.Find("WavefrontObject") != null) { 
            GameObject model = GameObject.Find("WavefrontObject");
            Vector3 inputDir2 = new Vector3(0, 0, 0);
            if (Input.GetKey(KeyCode.Q)) { inputDir2.y += 1f; }
            if (Input.GetKey(KeyCode.E)) { inputDir2.y -= 1f; }
            if (Input.GetKey(KeyCode.W)) { inputDir2.x -= 1f; }
            if (Input.GetKey(KeyCode.S)) { inputDir2.x += 1f; }


            float rotateSpeed = 20f;
            //model.transform.eulerAngles += new Vector3(inputDir2.x * rotateSpeed * Time.deltaTime, inputDir2.y * rotateSpeed * Time.deltaTime, 0);
            model.transform.RotateAround(model.transform.position, new Vector3(inputDir2.x, -inputDir2.y, 0), rotateSpeed * Time.deltaTime);
        }
    }
}
