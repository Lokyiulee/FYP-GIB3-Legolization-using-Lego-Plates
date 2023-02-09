using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;

namespace VoxelSystem{
public class Test:MonoBehaviour {
public ComputeBuffer buffer1;
public ComputeShader voxelizer;
public bool useuv;
public static Texture2D texture;
public int resolution = 60;
public Mesh mesh;
public MeshFilter meshfil;

public void Start(){
    meshfil = GetComponent<MeshFilter>();
    mesh = meshfil.mesh;
    voxelizer = (ComputeShader)Resources.Load("Voxelizer");
    //texture = (Texture2D)Resources.Load("WallPaper");
}   
public void Open(){
    GPUVoxelData data =  GPUVoxelizer.Voxelize(voxelizer,mesh,resolution,true);
    GetComponent<MeshFilter>().sharedMesh = VoxelMesh.Build(data.GetData(), data.UnitLength, useuv);
    RenderTexture volumeTexture = GPUVoxelizer.BuildTexture3D(voxelizer,data,texture,RenderTextureFormat.ARGBFloat,FilterMode.Bilinear);
    data.Dispose();
    }
}

}