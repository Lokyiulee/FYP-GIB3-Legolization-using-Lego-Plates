using UnityEngine;
using UnityEngine.UI;
using System.Collections;

namespace VoxelSystem{
public class button123 : MonoBehaviour {
	public GameObject[] child;
	public GameObject originalGameObject;
	public Texture2D[] tex;
	public Material mat;

	void Start () {
		Button btn = this.GetComponent<Button>();
		btn.onClick.AddListener(TaskOnClick);
	}

	void TaskOnClick(){
		mat = (Material)Resources.Load("mat");
		originalGameObject = GameObject.Find("WavefrontObject");
		string[] textures = new string[originalGameObject.transform.childCount];
		child = new GameObject[textures.Length];
		tex = new Texture2D[textures.Length];
		for(var i = 0; i < textures.Length; i++){
        child[i] = originalGameObject.transform.GetChild(i).gameObject;
		textures[i] = child[i].name;
	}
		for(var i = 0; i < textures.Length; i++){
		child[i].GetComponent<Test>().Open(textures[i]);
		tex[i] = (Texture2D)Resources.Load(textures[i]);
		child[i].GetComponent<Renderer>().material = mat;
		}
		for(var i = 0; i < textures.Length; i++){
		child[i].GetComponent<Renderer>().material.mainTexture = tex[i];
		}
	}
}
}