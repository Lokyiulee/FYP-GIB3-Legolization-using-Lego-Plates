using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraControl : MonoBehaviour
{
    public GameObject[] models;
    public Vector3 targetCameraPos = Vector3.zero;
    public Camera mainCamera;
    public Vector3 currentVeclocity = Vector3.zero;
    public float smoothTime = 0.1f;
    public float maxSmoothSpeed = 50;
    // Start is called before the first frame update
    void Start()
    {
        mainCamera = Camera.main;
 
    }

    // Update is called once per frame
    void Update()
    {
        models = GameObject.FindGameObjectsWithTag("Player");
        ResetCameraPos();
    }
    void ResetCameraPos(){
        Vector3 sumPos = Vector3.zero;
        foreach (var model in models){
            sumPos.x += model.transform.position.x;
            sumPos.y += model.transform.position.y;
            sumPos.z += model.transform.position.z;
       }
        if (models.Length > 0){
            targetCameraPos = sumPos / models.Length;
            targetCameraPos.y = sumPos.y + 2;
            targetCameraPos.z = sumPos.z - 10;
            targetCameraPos.x = sumPos.x;
            //mainCamera.transform.position = Vector3.SmoothDamp(mainCamera.transform.position, targetCameraPos, ref currentVeclocity, smoothTime, maxSmoothSpeed);
            mainCamera.transform.position = targetCameraPos;
       }
        
    }
}
