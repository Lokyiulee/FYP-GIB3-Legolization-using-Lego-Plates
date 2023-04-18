using System.IO;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;
using UnityEngine.UI;
using SFB;
using TMPro;
using UnityEngine.Networking;
using Dummiesman;
using System;


    public class SaveFile : MonoBehaviour
    {
        //public TextMeshProUGUI textMeshPro;
        //public GameObject model;
        //public Texture2D image;
        //public Dictionary<string, Material> mtl;
        string path3;

       


#if UNITY_WEBGL && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern void DownloadFile(string gameObjectName, string methodName, string filename, byte[] byteArray, int byteArraySize);

    public void OnClickSave(){
        
        DownloadFile(gameObject.name, "OnFileDownload", "model.obj", bytes, bytes.Length);
    }

    // called from browser
    public void OnFileDownload() {}
#else
        public void OnClickSave()
        {
        string[] paths3 = StandaloneFileBrowser.OpenFolderPanel("Save File","", false);
        //string[] paths2 = StandaloneFileBrowser.OpenFilePanel("Open File", "", "mtl", false);
        path3 = string.Concat(paths3);

        //for (int i = 0; i < paths1.Length; i++)
        //{
        //}
        //if (paths3.Length > 0)
        //{
            //lobals.path1 = paths1[0];
            //Globals.path2 = paths2[0];
            //StartCoroutine(UploadFileData());
            //StartCoroutine(OutputRoutineOpen(new System.Uri(paths1[0]).AbsoluteUri));
            StartCoroutine(OutputRoutineOpen(new System.Uri(paths3[0]).AbsoluteUri));

        //}
    }
#endif
    private IEnumerator OutputRoutineOpen(string url3)
    //private IEnumerator OutputRoutineOpen(string url1)

    {


        UnityWebRequest www3 = UnityWebRequest.Get(url3);
        //UnityWebRequest www2 = UnityWebRequest.Get(url2);
        yield return www3.SendWebRequest();
        var exp = new OBJExporter();
        //exp.Export(path3);
        if (www3.result != UnityWebRequest.Result.Success)
        {
            Debug.Log("WWW ERROR " + www3.error);
        }
        else
        {
            MemoryStream textStream3 = new MemoryStream(Encoding.UTF8.GetBytes(www3.downloadHandler.text));
            //MemoryStream textStream2 = new MemoryStream(Encoding.UTF8.GetBytes(www2.downloadHandler.text));

            //if (model != null)
            //{
            //    Destroy(model);
            //}
            //Debug.Log("BEFORE");

            //var mtlloader = new MTLLoader();
            //mtl = mtlloader.Load(path2);
            
            //obj.Materials = mtl;
            //Debug.Log("AFTER");

            //model = new OBJLoader().Load(textStream1);
            //model.transform.localScale = new Vector3(-1, 1, 1);
            //FitOnScreen();
            //GameObject originalGameObject = GameObject.Find("WavefrontObject");
            /*for (var i = 0; i < originalGameObject.transform.childCount; i++)
            {
                GameObject child = originalGameObject.transform.GetChild(i).gameObject;
                Test ts = child.AddComponent(typeof(Test)) as Test;
                child.tag = "Player";
            }*/
            //DoublicateFaces();
        }
    }

}
