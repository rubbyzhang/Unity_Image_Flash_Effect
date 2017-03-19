using System;
using System.Collections.Generic;
using System.Text;
using JetBrains.Annotations;
using UnityEngine;
using UnityEngine.UI;

[ExecuteInEditMode]
public class ImageFlashEffect : MonoBehaviour
{
    public Material Material ;
    public Texture  OverrideTexture;

    [Range(0.5f,5)]
    public float Scale = 1.0f;
    [Range(-180, 180)]
    public float Angle = 45f;


    //受Angle和Scale影响
    [Range(0.1f, 20)]
    public float Duration = 1;

    //受Angle和Scale影响
    [Range(0.1f, 20)]
    public float Interval = 3;

    //受Angle和Scale影响
    [Range(-10f, 10)]
    public float OffSet = 0;

    public Color Color = Color.white;
    [Range(1, 10)]
    public float Power = 1;

    private Material mDynaMaterial; 
    private MaskableGraphic mGraphic;

    private void Awake()
    {
        UpdateParam();
    }

    void UpdateParam()
    {
        if (Material == null)
        {
            Debug.LogWarning("Metarial is miss");
            return;
        }

        if (mGraphic == null)
        {
            mGraphic = GetComponent<MaskableGraphic>();
        }

        if (mGraphic is Text)
        {
            Debug.LogError("FlashEffec need component type of Image、RawImage");
            return;
        }

        if (mDynaMaterial == null)
        {
            mDynaMaterial = new Material(Material);
            mDynaMaterial.name = mDynaMaterial.name + "(Copy)";
            mDynaMaterial.hideFlags = HideFlags.DontSave | HideFlags.NotEditable;
        }

        if (mDynaMaterial == null)
        {
            return;
        }

        mDynaMaterial.mainTexture = null;
        if (OverrideTexture != null)
        {
            mDynaMaterial.mainTexture = OverrideTexture;

            if (mGraphic is RawImage)
            {
                RawImage img = mGraphic as RawImage;
                img.texture = null;
            }
            else if (mGraphic is Image)
            {
                Image img = mGraphic as Image;
                img.sprite = null;
            }
        }
        else
        {
            mDynaMaterial.mainTexture = mGraphic.mainTexture;
        }

        if (Duration > Interval)
        {
            Debug.LogWarning("ImageFlashEffect.UpdateParam:Duration need less Interval");
            Interval = Duration + 0.5f;
        }

        mDynaMaterial.SetColor("_LightColor", Color);
        mDynaMaterial.SetFloat("_LightPower", Power);
        mDynaMaterial.SetFloat("_LightScale", Scale);
        mDynaMaterial.SetFloat("_LightAngle", Angle);
        mDynaMaterial.SetFloat("_LightDuration", Duration);
        mDynaMaterial.SetFloat("_LightInterval", Interval);
        mDynaMaterial.SetFloat("_LightOffSetX", OffSet);
        mGraphic.material = mDynaMaterial;
        mGraphic.SetMaterialDirty();
    }

#if UNITY_EDITOR
    void OnValidate()
    {
        UpdateParam();
    }
#endif
}

