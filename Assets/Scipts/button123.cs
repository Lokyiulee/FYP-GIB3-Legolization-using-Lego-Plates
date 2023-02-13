using UnityEngine;
using UnityEngine.UI;
using System.Collections;

namespace VoxelSystem{
public class button123 : MonoBehaviour {
	public GameObject[] child;
	public GameObject originalGameObject;

	void Start () {
		Button btn = this.GetComponent<Button>();
		btn.onClick.AddListener(TaskOnClick);
		}
	void TaskOnClick(){
		originalGameObject = GameObject.Find("WavefrontObject");
		child = new GameObject[originalGameObject.transform.childCount];
		for(var i = 0; i < child.Length; i++){
        child[i] = originalGameObject.transform.GetChild(i).gameObject;
		child[i].GetComponent<Test>().Open();
		}
	}
}
}