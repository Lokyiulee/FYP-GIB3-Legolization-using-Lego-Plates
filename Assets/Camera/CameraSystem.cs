using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraSystem : MonoBehaviour
{
    private void Update()
    {
        //camera movement
        Vector3 inputDir = new Vector3(0,0,0);
        if (Input.GetKey(KeyCode.T)) {inputDir.z= -1f;} //zoom in
        if (Input.GetKey(KeyCode.G)) {inputDir.z= +1f;} //zoom out
        if (Input.GetKey(KeyCode.A)) {inputDir.x= -1f;} //object go left
        if (Input.GetKey(KeyCode.D)) {inputDir.x= +1f;} //object go right

        Vector3 moveDir = transform.forward * inputDir.z + transform.right * inputDir.x;

        float moveSpeed = 20f;
        transform.position += moveDir * moveSpeed * Time.deltaTime;


        //object rotation
        if (GameObject.Find("WavefrontObject") != null) { 
            GameObject model = GameObject.Find("WavefrontObject");
            Vector3 inputDir2 = new Vector3(0, 0, 0);
            Vector3 inputDir3 = new Vector3(0, 0, 0);
            if (Input.GetKey(KeyCode.Q)) { inputDir2.y += 1f; } //obj anticlockwise 
            if (Input.GetKey(KeyCode.E)) { inputDir2.y -= 1f; } //obj clockwise
            if (Input.GetKey(KeyCode.R)) { inputDir2.x -= 1f; } //rotate up
            if (Input.GetKey(KeyCode.F)) { inputDir2.x += 1f; } //rotate down
            if (Input.GetKey(KeyCode.W)) { inputDir3.y= +1f;} //up
            if (Input.GetKey(KeyCode.S)) { inputDir3.y= -1f;} //down



            float rotateSpeed = 20f;
            //model.transform.eulerAngles += new Vector3(inputDir2.x * rotateSpeed * Time.deltaTime, inputDir2.y * rotateSpeed * Time.deltaTime, 0);
            model.transform.RotateAround(model.transform.position, new Vector3(inputDir2.x, -inputDir2.y, 0), rotateSpeed * Time.deltaTime);
            
            Vector3 moveDir1 = transform.up * inputDir3.y;

            //float moveSpeed = 20f; 
            model.transform.position += moveDir1 * moveSpeed * Time.deltaTime;
        }
    }
}
