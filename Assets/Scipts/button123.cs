using UnityEngine;
using UnityEngine.UI;
using System.Collections;

namespace VoxelSystem{
public class button123 : MonoBehaviour {
	public GameObject[] child;
	public GameObject originalGameObject;
	public static float globalVarlengthx = 0;
	public static float globalVarlengthy = 0;
	public static float globalVarlengthz = 0;
    public static float globalVarminx = 0;
    public static float globalVarminy = 0;
    public static float globalVarminz = 0;



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
		//child[i].GetComponent<ObjectCutter>().original = originalGameObject;
		//child[i].GetComponent<Renderer>().material.shader = Shader.Find("Custom/SNOTShader");
		child[i].GetComponent<Renderer>().material.shader = Shader.Find("Modular Bricks/Pipes/PBL");
		//child[i].GetComponent<Renderer>().material.shader = Shader.Find("Modular Bricks/Pipes/PBL_Right");
		globalVarlengthx = OpenFile.Globals.boundSize.x;
        globalVarlengthy = OpenFile.Globals.boundSize.y;
        globalVarlengthz = OpenFile.Globals.boundSize.z;
        globalVarminx = OpenFile.Globals.boundmin.x;
        globalVarminy = OpenFile.Globals.boundmin.y;
        globalVarminz = OpenFile.Globals.boundmin.z;
        Shader.SetGlobalFloat("_GlobalVarlengthx", globalVarlengthx);
		Shader.SetGlobalFloat("_GlobalVarlengthy", globalVarlengthy);
		Shader.SetGlobalFloat("_GlobalVarlengthz", globalVarlengthz);
        Shader.SetGlobalFloat("_GlobalVarminx", globalVarminx);
        Shader.SetGlobalFloat("_GlobalVarminy", globalVarminy);
        Shader.SetGlobalFloat("_GlobalVarminz", globalVarminz);



            }
        }
}
}