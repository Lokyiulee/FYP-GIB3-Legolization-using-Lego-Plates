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

namespace VoxelSystem{
public class OpenFile : MonoBehaviour
{
    public TextMeshProUGUI textMeshPro;
    public GameObject model;

    public static class Globals
    {
        public static string path1 = "";
    }

#if UNITY_WEBGL && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern void UploadFile(string gameObjectName, string methodName, string filter, bool multiple);

    public void OnClickOpen(){
        UploadFile(gameObject.name, "OnFileUpload", "", false);
    }

    public void OnFileUpload(string url) {
        StartCoroutine(OutputRoutineOpen(url));
    }
#else
    public void OnClickOpen()
    {
        string[] paths = StandaloneFileBrowser.OpenFilePanel("Open File", "", "", false);
        if (paths.Length > 0)
        {
            Globals.path1 = paths[0];
            StartCoroutine(UploadFileData());
            StartCoroutine(OutputRoutineOpen(new System.Uri(paths[0]).AbsoluteUri));
        }
    }
#endif

    private IEnumerator OutputRoutineOpen(string url)
    {
        UnityWebRequest www = UnityWebRequest.Get(url);
        yield return www.SendWebRequest();
        if (www.result != UnityWebRequest.Result.Success)
        {
            Debug.Log("WWW ERROR " + www.error);
        }
        else
        {
            MemoryStream textStream = new MemoryStream(Encoding.UTF8.GetBytes(www.downloadHandler.text));
            if(model != null)
            {
                Destroy(model);
            }
            model = new OBJLoader().Load(textStream);
            model.transform.localScale = new Vector3(-1, 1, 1);
            FitOnScreen();
            GameObject originalGameObject = GameObject.Find("WavefrontObject");
            VoxelSystem.Test.texture = new ImageLoader().LoadTexture(textStream, ImageLoader.TextureFormat.JPG);
            for(var i = 0; i < originalGameObject.transform.childCount; i++){
            GameObject child = originalGameObject.transform.GetChild(i).gameObject;
            Test ts = child.AddComponent(typeof(Test)) as Test;
            child.tag = "Player";
            }
            //DoublicateFaces();
        }
    }

    IEnumerator UploadFileData()
    {

        using (var uwr = new UnityWebRequest("ftp://lego:Fyp123456@223.17.75.107//" + Path.GetFileName(Globals.path1), UnityWebRequest.kHttpVerbPUT))
        {
            uwr.uploadHandler = new UploadHandlerFile(Globals.path1);
            Debug.Log("uploading file");
            yield return uwr.SendWebRequest();

            if (uwr.result != UnityWebRequest.Result.Success)
                Debug.LogError(uwr.error);
            else
            {
                // file data successfully sent
                Debug.Log("File uploaded");
            }
        }
    }

    private Bounds GetBound(GameObject gameObj)
    {
        Bounds bound = new Bounds(gameObj.transform.position, Vector3.zero);
        var rList = gameObj.GetComponentsInChildren(typeof(Renderer));
        foreach (Renderer r in rList)
        {
            bound.Encapsulate(r.bounds);
        }
        return bound;
    }
    public void FitOnScreen()
    {
        Bounds bound = GetBound(model);
        Vector3 boundSize = bound.size;
        float diagonal = Mathf.Sqrt((boundSize.x * boundSize.x) + (boundSize.y * boundSize.y) + (boundSize.z * boundSize.z));
        //Camera.main.orthographicSize = diagonal / 1.0f;
        //Camera.main.transform.position = bound.center;
    }
    public void DoublicateFaces()
    {
        for (int i = 0; i < model.GetComponentsInChildren<Renderer>().Length; i++) //Loop through the model children
        {
            // Get oringal mesh components: vertices, normals triangles and texture coordinates 
            Mesh mesh = model.GetComponentsInChildren<MeshFilter>()[i].mesh;
            Vector3[] vertices = mesh.vertices;
            int numOfVertices = vertices.Length;
            Vector3[] normals = mesh.normals;
            int[] triangles = mesh.triangles;
            int numOfTriangles = triangles.Length;
            Vector2[] textureCoordinates = mesh.uv;
            if (textureCoordinates.Length < numOfTriangles) //Check if mesh doesn't have texture coordinates 
            {
                textureCoordinates = new Vector2[numOfVertices * 2];
            }

            // Create a new mesh component, double the size of the original 
            Vector3[] newVertices = new Vector3[numOfVertices * 2];
            Vector3[] newNormals = new Vector3[numOfVertices * 2];
            int[] newTriangle = new int[numOfTriangles * 2];
            Vector2[] newTextureCoordinates = new Vector2[numOfVertices * 2];

            for (int j = 0; j < numOfVertices; j++)
            {
                newVertices[j] = newVertices[j + numOfVertices] = vertices[j]; //Copy original vertices to make the second half of the mew vertices array
                newTextureCoordinates[j] = newTextureCoordinates[j + numOfVertices] = textureCoordinates[j]; //Copy original texture coordinates to make the second half of the mew texture coordinates array  
                newNormals[j] = normals[j]; //First half of the new normals array is a copy original normals
                newNormals[j + numOfVertices] = -normals[j]; //Second half of the new normals array reverse the original normals
            }

            for (int x = 0; x < numOfTriangles; x += 3)
            {
                // copy the original triangle for the first half of array
                newTriangle[x] = triangles[x];
                newTriangle[x + 1] = triangles[x + 1];
                newTriangle[x + 2] = triangles[x + 2];
                // Reversed triangles for the second half of array
                int j = x + numOfTriangles;
                newTriangle[j] = triangles[x] + numOfVertices;
                newTriangle[j + 2] = triangles[x + 1] + numOfVertices;
                newTriangle[j + 1] = triangles[x + 2] + numOfVertices;
            }
            mesh.vertices = newVertices;
            mesh.uv = newTextureCoordinates;
            mesh.normals = newNormals;
            mesh.triangles = newTriangle;
        }
    }
}
}